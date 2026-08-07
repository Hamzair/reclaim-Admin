import 'package:reclaim_admin_panel/views/withdrawals/withdrawal_request.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../../const/constants.dart';
import '../../controller/sidebarController.dart';
import '../../widgets/admin_loaders.dart';

class Withdrawal_Screen extends StatefulWidget {
  Withdrawal_Screen({Key? key}) : super(key: key);

  @override
  State<Withdrawal_Screen> createState() => _Withdrawal_ScreenState();
}

class _Withdrawal_ScreenState extends State<Withdrawal_Screen> {
  final SidebarController sidebarController = Get.put(SidebarController());
  String searchQuery = '';

  final List<_WithdrawalUserRow> _allUsers = [];
  int _visibleCount = 25;
  bool _loading = true;
  String? _error;

  static const int _pageSize = 25;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final users = await _loadWithdrawalUsers();
      if (!mounted) return;
      setState(() {
        _allUsers
          ..clear()
          ..addAll(users);
        _visibleCount = _pageSize;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  /// Parent `userWithdrawals/{uid}` docs are often missing because the app only
  /// writes the subcollection. Discover users via collectionGroup instead.
  Future<List<_WithdrawalUserRow>> _loadWithdrawalUsers() async {
    final requests = await FirebaseFirestore.instance
        .collectionGroup('withdrawalsRequest')
        .get();

    final Map<String, int> pendingByUser = {};
    final Map<String, int> totalByUser = {};

    for (final doc in requests.docs) {
      // path: userWithdrawals/{userId}/withdrawalsRequest/{requestId}
      final segments = doc.reference.path.split('/');
      if (segments.length < 2 || segments[0] != 'userWithdrawals') continue;
      final userId = segments[1];
      totalByUser[userId] = (totalByUser[userId] ?? 0) + 1;
      final status =
          (doc.data()['withdrawStatus'] ?? '').toString().toLowerCase();
      if (status == 'pending') {
        pendingByUser[userId] = (pendingByUser[userId] ?? 0) + 1;
      }
    }

    final users = <_WithdrawalUserRow>[];
    for (final userId in totalByUser.keys) {
      final userSnap = await FirebaseFirestore.instance
          .collection('userDetails')
          .doc(userId)
          .get();
      final data = userSnap.data() ?? {};
      users.add(
        _WithdrawalUserRow(
          userId: userId,
          userName: (data['userName'] ?? 'Unknown').toString(),
          userImage: (data['userImage'] ?? '').toString(),
          totalRequests: totalByUser[userId] ?? 0,
          pendingRequests: pendingByUser[userId] ?? 0,
        ),
      );
    }

    users.sort((a, b) => b.pendingRequests.compareTo(a.pendingRequests));
    return users;
  }

  List<_WithdrawalUserRow> get _filtered {
    final q = searchQuery.trim().toLowerCase();
    if (q.isEmpty) return _allUsers;
    return _allUsers
        .where((u) => u.userName.toLowerCase().contains(q))
        .toList();
  }

  List<_WithdrawalUserRow> get _visible {
    final filtered = _filtered;
    if (searchQuery.trim().isNotEmpty) return filtered;
    return filtered.take(_visibleCount).toList();
  }

  void _loadMore() {
    if (searchQuery.trim().isNotEmpty) return;
    setState(() {
      _visibleCount = (_visibleCount + _pageSize).clamp(0, _allUsers.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final rows = _visible;
    final filtered = _filtered;
    final hasMore =
        searchQuery.trim().isEmpty && _visibleCount < _allUsers.length;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: Get.width < 768
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                const SizedBox(width: 20),
                Get.width < 768
                    ? GestureDetector(
                        onTap: () {
                          sidebarController.showsidebar.value = true;
                        },
                        child: SvgPicture.asset(
                          'assets/images/drawernavigation.svg',
                          colorFilter: const ColorFilter.mode(
                              primaryColor, BlendMode.srcIn),
                        ),
                      )
                    : const SizedBox.shrink(),
                Padding(
                  padding: EdgeInsets.only(
                    left: width < 768 ? 15 : 15,
                    top: 20,
                    bottom: 20,
                  ),
                  child: SizedBox(
                    width: width <= 520
                        ? 260
                        : width < 768
                            ? 370
                            : 500,
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: "Search users",
                        hintStyle: const TextStyle(color: Colors.white),
                        fillColor: primaryColor,
                        filled: true,
                        border: const OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                        suffixIcon: Container(
                          padding: const EdgeInsets.all(defaultPadding * 0.75),
                          margin: const EdgeInsets.symmetric(
                              horizontal: defaultPadding / 2),
                          decoration: const BoxDecoration(
                            color: primaryColor,
                            borderRadius:
                                BorderRadius.all(Radius.circular(10)),
                          ),
                          child: const Icon(Icons.search, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: _loading ? null : _refresh,
                  icon: const Icon(Icons.refresh, color: primaryColor),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Image',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 20,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'User Name',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 20,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Requests',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 20,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Action',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 20,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const AdminLoader(message: 'Loading withdrawals...')
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Failed to load withdrawals:\n$_error',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.red),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: _refresh,
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : rows.isEmpty
                          ? const AdminEmptyState(
                              message: 'No withdrawal requests found.')
                          : RefreshIndicator(
                              color: primaryColor,
                              onRefresh: _refresh,
                              child: ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: rows.length + 1,
                                itemBuilder: (context, index) {
                                  if (index == rows.length) {
                                    return AdminLoadMoreBar(
                                      hasMore: hasMore,
                                      isLoadingMore: false,
                                      loadedCount: searchQuery.trim().isEmpty
                                          ? rows.length
                                          : filtered.length,
                                      onLoadMore: _loadMore,
                                    );
                                  }

                                  final user = rows[index];
                                  return Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: CircleAvatar(
                                                backgroundImage: user
                                                        .userImage.isNotEmpty
                                                    ? NetworkImage(
                                                        user.userImage)
                                                    : const AssetImage(
                                                            'assets/images/logo.png')
                                                        as ImageProvider,
                                                radius: 35,
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                user.userName,
                                                style: const TextStyle(
                                                  color: secondaryColor,
                                                  fontWeight: FontWeight.w400,
                                                  fontSize: 15,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                '${user.pendingRequests} pending / ${user.totalRequests} total',
                                                style: const TextStyle(
                                                  color: secondaryColor,
                                                  fontWeight: FontWeight.w400,
                                                  fontSize: 14,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            Expanded(
                                              child: Center(
                                                child: TextButton(
                                                  onPressed: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            WithdrawalRequest(
                                                          userId: user.userId,
                                                        ),
                                                      ),
                                                    ).then((_) {
                                                      if (mounted) _refresh();
                                                    });
                                                  },
                                                  child: const Text(
                                                    'See Details',
                                                    style: TextStyle(
                                                      color: Colors.blue,
                                                      decoration: TextDecoration
                                                          .underline,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 30),
                                        child: Divider(
                                          color: Colors.grey,
                                          thickness: 2,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WithdrawalUserRow {
  final String userId;
  final String userName;
  final String userImage;
  final int totalRequests;
  final int pendingRequests;

  _WithdrawalUserRow({
    required this.userId,
    required this.userName,
    required this.userImage,
    required this.totalRequests,
    required this.pendingRequests,
  });
}

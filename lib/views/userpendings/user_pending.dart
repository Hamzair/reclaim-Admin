import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../../const/constants.dart';
import '../../controller/sidebarController.dart';
import '../../helper/firestore_paginator.dart';
import '../../widgets/admin_loaders.dart';

class UserPending extends StatefulWidget {
  UserPending({Key? key}) : super(key: key);

  @override
  State<UserPending> createState() => _UserPendingState();
}

class _UserPendingState extends State<UserPending> {
  final SidebarController sidebarController = Get.put(SidebarController());
  late final FirestorePaginator _paginator;
  final List<Map<String, dynamic>> _items = [];
  String searchQuery = '';
  bool _loading = true;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _paginator = FirestorePaginator(
      query: FirebaseFirestore.instance
          .collection('pendingUserUpdates')
          .orderBy(FieldPath.documentId),
      pageSize: 20,
    );
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    try {
      final docs = await _paginator.refresh();
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(docs.map((d) {
            final data = d.data() as Map<String, dynamic>? ?? {};
            return {...data, 'docId': d.id};
          }));
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_paginator.hasMore || searchQuery.trim().isNotEmpty) {
      return;
    }
    setState(() => _loadingMore = true);
    try {
      final docs = await _paginator.loadMore();
      if (!mounted) return;
      setState(() {
        _items.addAll(docs.map((d) {
          final data = d.data() as Map<String, dynamic>? ?? {};
          return {...data, 'docId': d.id};
        }));
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  Future<void> checkForProfileUpdate(String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('pendingUserUpdates')
          .doc(userId)
          .update({"pendingApproval": true});
      DocumentSnapshot pendingUpdates = await FirebaseFirestore.instance
          .collection('pendingUserUpdates')
          .doc(userId)
          .get();
      if (pendingUpdates.exists) {
        Map<String, dynamic> update =
            pendingUpdates.data() as Map<String, dynamic>;
        bool approval = update['pendingApproval'];
        if (approval == true) {
          await FirebaseFirestore.instance
              .collection('userDetails')
              .doc(userId)
              .update({'userName': update['pendingUserName']});
          if (update.containsKey('pendingUserImage') &&
              update['pendingUserImage'] != '') {
            await FirebaseFirestore.instance
                .collection('userDetails')
                .doc(userId)
                .update({'userImage': update['pendingUserImage']});
          }
          await FirebaseFirestore.instance
              .collection('pendingUserUpdates')
              .doc(userId)
              .delete();
          setState(() {
            _items.removeWhere((e) => e['docId'] == userId);
          });
        }
      }
    } catch (e) {
      print('Error Approving Profile Update $e');
    }
  }

  void showBanConfirmationDialog1(
      BuildContext context, String userId, bool isCurrentlyVerified) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: primaryColor,
          title: Text(
              isCurrentlyVerified ? 'Approval Pending User' : 'Approved User'),
          content: Text(isCurrentlyVerified
              ? 'Do you want to Approval Pending this User?'
              : 'Are you sure you want to approve this User?'),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'No',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                    fontSize: 15),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text(
                'Confirm',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                    fontSize: 15),
              ),
              onPressed: () async {
                await checkForProfileUpdate(userId);
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  List<Map<String, dynamic>> get _filtered {
    final q = searchQuery.toLowerCase().trim();
    if (q.isEmpty) return _items;
    return _items.where((u) {
      final name = (u['pendingUserName'] ?? '').toString().toLowerCase();
      return name.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final rows = _filtered;

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
                  padding: const EdgeInsets.only(left: 15, top: 20, bottom: 20),
                  child: SizedBox(
                    width: width <= 520 ? 260 : width < 768 ? 370 : 500,
                    child: TextField(
                      onChanged: (value) {
                        setState(() => searchQuery = value);
                      },
                      decoration: InputDecoration(
                        hintText: "Search",
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
                  onPressed: _loading ? null : _refresh,
                  icon: const Icon(Icons.refresh, color: primaryColor),
                ),
              ],
            ),
            const Row(
              children: [
                Expanded(
                    child: Text(
                  'User Image',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: primaryColor),
                  textAlign: TextAlign.center,
                )),
                Expanded(
                    child: Text('User Name',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: primaryColor),
                        textAlign: TextAlign.center)),
                Expanded(
                    child: Text('Approval',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: primaryColor),
                        textAlign: TextAlign.center)),
              ],
            ),
            Expanded(
              child: _loading
                  ? const AdminLoader(message: 'Loading pending users...')
                  : rows.isEmpty
                      ? const AdminEmptyState(message: 'No Pending User found.')
                      : RefreshIndicator(
                          color: primaryColor,
                          onRefresh: _refresh,
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: rows.length + 1,
                            itemBuilder: (context, index) {
                              if (index == rows.length) {
                                return AdminLoadMoreBar(
                                  hasMore: searchQuery.trim().isEmpty &&
                                      _paginator.hasMore,
                                  isLoadingMore: _loadingMore,
                                  loadedCount: _items.length,
                                  onLoadMore: _loadMore,
                                );
                              }

                              final userData = rows[index];
                              final userName =
                                  userData['pendingUserName'] ?? '';
                              final userImage =
                                  userData['pendingUserImage'];
                              final userId =
                                  (userData['docId'] ?? '').toString();
                              final approved =
                                  userData['pendingApproval'] ?? false;

                              return Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          height: 120,
                                          width: 120,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            image: (userImage != null &&
                                                    userImage
                                                        .toString()
                                                        .isNotEmpty)
                                                ? DecorationImage(
                                                    image: NetworkImage(
                                                        userImage.toString()),
                                                    fit: BoxFit.cover,
                                                  )
                                                : null,
                                          ),
                                          child: (userImage == null ||
                                                  userImage
                                                      .toString()
                                                      .isEmpty)
                                              ? const Icon(Icons.person,
                                                  size: 120)
                                              : null,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          style: const TextStyle(
                                              color: secondaryColor,
                                              fontWeight: FontWeight.w400,
                                              fontSize: 15),
                                          '$userName',
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      Expanded(
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const SizedBox(width: 40),
                                            Text(
                                              approved
                                                  ? 'Approved'
                                                  : 'Pending',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w400,
                                                fontSize: 15,
                                                color: approved
                                                    ? Colors.green
                                                    : Colors.red,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            IconButton(
                                              onPressed: () {
                                                showBanConfirmationDialog1(
                                                  context,
                                                  userId,
                                                  approved == true,
                                                );
                                              },
                                              icon: const Icon(Icons.edit,
                                                  color: primaryColor),
                                            )
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(
                                    color: Colors.grey,
                                    thickness: 2,
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

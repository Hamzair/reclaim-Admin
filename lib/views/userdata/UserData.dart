import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../../const/constants.dart';
import '../../controller/sidebarController.dart';
import '../../helper/firestore_paginator.dart';
import '../../widgets/admin_loaders.dart';
import '../../widgets/confirm_dialog.dart';

class UserData extends StatefulWidget {
  @override
  _UserDataState createState() => _UserDataState();
}

class _UserDataState extends State<UserData> {
  final SidebarController sidebarController = Get.put(SidebarController());
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String searchQuery = '';
  late final FirestorePaginator _paginator;
  final List<Map<String, dynamic>> _users = [];
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _paginator = FirestorePaginator(
      query: _firestore.collection('userDetails').orderBy(FieldPath.documentId),
      pageSize: 25,
    );
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final docs = await _paginator.refresh();
      if (!mounted) return;
      setState(() {
        _users
          ..clear()
          ..addAll(docs.map((d) {
            final data = d.data() as Map<String, dynamic>? ?? {};
            return {...data, 'docId': d.id, 'userId': data['userId'] ?? d.id};
          }));
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

  Future<void> _loadMore() async {
    if (_loadingMore || !_paginator.hasMore || searchQuery.trim().isNotEmpty) {
      return;
    }
    setState(() => _loadingMore = true);
    try {
      final docs = await _paginator.loadMore();
      if (!mounted) return;
      setState(() {
        _users.addAll(docs.map((d) {
          final data = d.data() as Map<String, dynamic>? ?? {};
          return {...data, 'docId': d.id, 'userId': data['userId'] ?? d.id};
        }));
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final q = searchQuery.toLowerCase().trim();
    if (q.isEmpty) return _users;
    return _users.where((u) {
      final name = (u['userName'] ?? '').toString().toLowerCase();
      final email = (u['userEmail'] ?? u['email'] ?? '').toString().toLowerCase();
      return name.contains(q) || email.contains(q);
    }).toList();
  }

  Future<void> _deleteUser(String userId) async {
    final ok = await showAdminConfirmDialog(
      context: context,
      title: 'Delete user?',
      message: 'This will delete the user profile document. Continue?',
      confirmText: 'Delete',
    );
    if (!ok) return;
    try {
      await _firestore.collection('userDetails').doc(userId).delete();
      setState(() {
        _users.removeWhere((u) => (u['userId'] ?? u['docId']) == userId);
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User deleted successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error deleting user')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final rows = _filtered;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: Get.width < 768
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            children: [
              const SizedBox(width: 20),
              if (Get.width < 768)
                GestureDetector(
                  onTap: () => sidebarController.showsidebar.value = true,
                  child: SvgPicture.asset(
                    'assets/images/drawernavigation.svg',
                    colorFilter:
                        const ColorFilter.mode(primaryColor, BlendMode.srcIn),
                  ),
                ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
                child: SizedBox(
                  width: width <= 520 ? 260 : width < 768 ? 370 : 500,
                  child: TextField(
                    onChanged: (v) => setState(() => searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Search users',
                      hintStyle: const TextStyle(color: Colors.white),
                      fillColor: primaryColor,
                      filled: true,
                      border: const OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      suffixIcon:
                          const Icon(Icons.search, color: Colors.white),
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
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Expanded(
                    child: Text('Image',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: primaryColor))),
                Expanded(
                    child: Text('Name',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: primaryColor))),
                Expanded(
                    child: Text('Email',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: primaryColor))),
                SizedBox(width: 40),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const AdminLoader(message: 'Loading users...')
                : _error != null
                    ? Center(child: Text('Error: $_error'))
                    : rows.isEmpty
                        ? const AdminEmptyState(message: 'No users found')
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
                                    loadedCount: _users.length,
                                    onLoadMore: _loadMore,
                                  );
                                }
                                final userDetail = rows[index];
                                final uid =
                                    (userDetail['userId'] ?? userDetail['docId'] ?? '')
                                        .toString();
                                final image =
                                    (userDetail['userImage'] ?? '').toString();

                                return Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 6),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: CircleAvatar(
                                              radius: 28,
                                              backgroundColor:
                                                  Colors.grey.shade300,
                                              backgroundImage: image.isNotEmpty
                                                  ? NetworkImage(image)
                                                  : null,
                                              child: image.isEmpty
                                                  ? const Icon(Icons.person,
                                                      color: Colors.white)
                                                  : null,
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              (userDetail['userName'] ?? '')
                                                  .toString(),
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                  color: secondaryColor,
                                                  fontSize: 15),
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              (userDetail['userEmail'] ??
                                                      userDetail['email'] ??
                                                      '')
                                                  .toString(),
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                  color: secondaryColor,
                                                  fontSize: 15),
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: uid.isEmpty
                                                ? null
                                                : () => _deleteUser(uid),
                                            icon: const Icon(Icons.delete,
                                                color: Colors.redAccent),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 30),
                                      child: Divider(
                                          color: Colors.grey, thickness: 2),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

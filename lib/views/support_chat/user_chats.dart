import 'package:reclaim_admin_panel/const/constants.dart';
import 'package:reclaim_admin_panel/views/support_chat/user_messages.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../../controller/sidebarController.dart';
import '../../helper/firestore_paginator.dart';
import '../../widgets/admin_loaders.dart';

class SupportUserChats extends StatefulWidget {
  const SupportUserChats({super.key});

  @override
  State<SupportUserChats> createState() => _SupportUserChatsState();
}

class _SupportUserChatsState extends State<SupportUserChats> {
  final SidebarController sidebarController = Get.put(SidebarController());
  String searchQuery = '';
  late final FirestorePaginator _paginator;
  final List<Map<String, dynamic>> _chats = [];
  bool _loading = true;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _paginator = FirestorePaginator(
      query: FirebaseFirestore.instance
          .collection('supportChat')
          .orderBy(FieldPath.documentId),
      pageSize: 20,
    );
    _refresh();
  }

  Future<Map<String, dynamic>> _enrichChat(QueryDocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final userId = (data['userId'] ?? doc.id).toString();
    String userName = 'Unknown';
    String userImage = '';
    try {
      final userSnap = await FirebaseFirestore.instance
          .collection('userDetails')
          .doc(userId)
          .get();
      final userData = userSnap.data() ?? {};
      userName = (userData['userName'] ?? 'Unknown').toString();
      userImage = (userData['userImage'] ?? '').toString();
    } catch (_) {}

    return {
      ...data,
      'docId': doc.id,
      'userId': userId,
      'userName': userName,
      'userImage': userImage,
    };
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    try {
      final docs = await _paginator.refresh();
      final mapped = <Map<String, dynamic>>[];
      for (final doc in docs) {
        mapped.add(await _enrichChat(doc));
      }
      if (!mounted) return;
      setState(() {
        _chats
          ..clear()
          ..addAll(mapped);
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
      final mapped = <Map<String, dynamic>>[];
      for (final doc in docs) {
        mapped.add(await _enrichChat(doc));
      }
      if (!mounted) return;
      setState(() {
        _chats.addAll(mapped);
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final q = searchQuery.toLowerCase().trim();
    if (q.isEmpty) return _chats;
    return _chats.where((c) {
      final name = (c['userName'] ?? '').toString().toLowerCase();
      final uid = (c['userId'] ?? '').toString().toLowerCase();
      return name.contains(q) || uid.contains(q);
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
                if (Get.width < 768)
                  GestureDetector(
                    onTap: () => sidebarController.showsidebar.value = true,
                    child: SvgPicture.asset(
                      'assets/images/drawernavigation.svg',
                      colorFilter: const ColorFilter.mode(
                          primaryColor, BlendMode.srcIn),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 20, horizontal: 15),
                  child: SizedBox(
                    width: width <= 520 ? 260 : width < 768 ? 370 : 500,
                    child: TextField(
                      onChanged: (v) => setState(() => searchQuery = v),
                      decoration: InputDecoration(
                        hintText: 'Search support chats',
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
            Expanded(
              child: _loading
                  ? const AdminLoader(message: 'Loading support chats...')
                  : rows.isEmpty
                      ? const AdminEmptyState(message: 'No Chats Yet')
                      : RefreshIndicator(
                          color: primaryColor,
                          onRefresh: _refresh,
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: rows.length + 1,
                            itemBuilder: (context, index) {
                              if (index == rows.length) {
                                return AdminLoadMoreBar(
                                  hasMore: searchQuery.trim().isEmpty &&
                                      _paginator.hasMore,
                                  isLoadingMore: _loadingMore,
                                  loadedCount: _chats.length,
                                  onLoadMore: _loadMore,
                                );
                              }

                              final chats = rows[index];
                              final image =
                                  (chats['userImage'] ?? '').toString();

                              return Card(
                                color: primaryColor,
                                child: ListTile(
                                  onTap: () {
                                    Get.to(SupportUserMessages(
                                      chatsData: chats,
                                    ));
                                  },
                                  leading: CircleAvatar(
                                    backgroundImage: image.isNotEmpty
                                        ? NetworkImage(image)
                                        : const AssetImage(
                                                'assets/images/logo.png')
                                            as ImageProvider,
                                  ),
                                  title: Text(
                                    (chats['userName'] ?? 'Unknown').toString(),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: Text(
                                    (chats['lastMessage'] ??
                                            chats['message'] ??
                                            'Open chat')
                                        .toString(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: Colors.white70),
                                  ),
                                ),
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

import 'package:reclaim_admin_panel/const/constants.dart';
import 'package:reclaim_admin_panel/views/user_chats/order_messages.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../../controller/sidebarController.dart';
import '../../helper/firestore_paginator.dart';
import '../../widgets/admin_loaders.dart';

class OrderUserChats extends StatefulWidget {
  const OrderUserChats({super.key});

  @override
  State<OrderUserChats> createState() => _OrderUserChatsState();
}

class _OrderUserChatsState extends State<OrderUserChats> {
  String searchQuery = '';
  final SidebarController sidebarController = Get.put(SidebarController());
  late final FirestorePaginator _paginator;
  final List<Map<String, dynamic>> _orders = [];
  final Map<String, Map<String, dynamic>> _productCache = {};
  bool _loading = true;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _paginator = FirestorePaginator(
      query: FirebaseFirestore.instance
          .collection('orders')
          .orderBy(FieldPath.documentId),
      pageSize: 20,
    );
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    try {
      final docs = await _paginator.refresh();
      final mapped = <Map<String, dynamic>>[];
      for (final doc in docs) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        mapped.add({...data, 'orderId': data['orderId'] ?? doc.id, 'docId': doc.id});
      }
      if (!mounted) return;
      setState(() {
        _orders
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
        final data = doc.data() as Map<String, dynamic>? ?? {};
        mapped.add({...data, 'orderId': data['orderId'] ?? doc.id, 'docId': doc.id});
      }
      if (!mounted) return;
      setState(() {
        _orders.addAll(mapped);
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  Future<Map<String, dynamic>> _productFor(String productId) async {
    if (productId.isEmpty) return {};
    if (_productCache.containsKey(productId)) return _productCache[productId]!;
    final snap = await FirebaseFirestore.instance
        .collection('productsListing')
        .doc(productId)
        .get();
    final data = snap.data() ?? {};
    _productCache[productId] = data;
    return data;
  }

  List<Map<String, dynamic>> get _filtered {
    final q = searchQuery.toLowerCase().trim();
    if (q.isEmpty) return _orders;
    return _orders.where((o) {
      final id = (o['orderId'] ?? '').toString().toLowerCase();
      final name = (o['productName'] ?? '').toString().toLowerCase();
      return id.contains(q) || name.contains(q);
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
                        hintText: 'Search order chats',
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
                  ? const AdminLoader(message: 'Loading chats...')
                  : rows.isEmpty
                      ? const AdminEmptyState(message: 'No orders chat found')
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
                                  loadedCount: _orders.length,
                                  onLoadMore: _loadMore,
                                );
                              }

                              final orderData = rows[index];
                              final productId =
                                  (orderData['productId'] ?? '').toString();

                              return Card(
                                color: primaryColor,
                                child: ListTile(
                                  onTap: () {
                                    Get.to(OrderUserMessages(
                                      chatsData: orderData,
                                    ));
                                  },
                                  title: FutureBuilder<Map<String, dynamic>>(
                                    future: _productFor(productId),
                                    builder: (context, snap) {
                                      final productData = snap.data ?? {};
                                      final productName =
                                          productData['productName'] ??
                                              orderData['productName'] ??
                                              'Loading...';
                                      final images =
                                          productData['productImages'];
                                      return Row(
                                        children: [
                                          Container(
                                            width: 70,
                                            height: 70,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              image: DecorationImage(
                                                image: (images is List &&
                                                        images.isNotEmpty)
                                                    ? NetworkImage(
                                                        images[0].toString())
                                                    : const AssetImage(
                                                            'assets/images/logo.png')
                                                        as ImageProvider,
                                                fit: BoxFit.contain,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Product Name: $productName',
                                                  style: const TextStyle(
                                                      color: Colors.white),
                                                ),
                                                Text(
                                                  'OrderId: ${orderData['orderId']}',
                                                  style: const TextStyle(
                                                      color: Colors.white),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      );
                                    },
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

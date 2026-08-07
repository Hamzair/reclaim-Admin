import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import '../../const/constants.dart';
import '../../controller/sidebarController.dart';
import '../../helper/firestore_paginator.dart';
import '../../widgets/admin_loaders.dart';
import '../../widgets/confirm_dialog.dart';

class ProductsListing extends StatefulWidget {
  const ProductsListing({super.key});

  @override
  State<ProductsListing> createState() => _ProductsListingState();
}

class _ProductsListingState extends State<ProductsListing> {
  final SidebarController sidebarController = Get.put(SidebarController());
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  late final FirestorePaginator _paginator;
  final List<Map<String, dynamic>> _items = [];
  String searchQuery = '';
  bool _initialLoading = true;
  bool _loadingMore = false;
  bool _isDeleting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _paginator = FirestorePaginator(
      query: _db
          .collection('productsListing')
          .orderBy(FieldPath.documentId),
      pageSize: 20,
    );
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _initialLoading = true;
      _error = null;
    });
    try {
      final docs = await _paginator.refresh();
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(docs.map(_mapDoc));
        _initialLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _initialLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore ||
        !_paginator.hasMore ||
        searchQuery.trim().isNotEmpty) {
      return;
    }
    setState(() => _loadingMore = true);
    try {
      final docs = await _paginator.loadMore();
      if (!mounted) return;
      setState(() {
        _items.addAll(docs.map(_mapDoc));
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load more: $e')),
      );
    }
  }

  Map<String, dynamic> _mapDoc(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return {
      ...data,
      'listingId': doc.id,
    };
  }

  List<Map<String, dynamic>> get _filtered {
    final q = searchQuery.trim().toLowerCase();
    if (q.isEmpty) return _items;
    return _items.where((item) {
      final name = (item['productName'] ?? '').toString().toLowerCase();
      final brand = (item['brand'] ?? '').toString().toLowerCase();
      return name.contains(q) || brand.contains(q);
    }).toList();
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final d = timestamp.toDate();
      return "${d.day}/${d.month}/${d.year} ${d.hour}:${d.minute}";
    }
    return 'N/A';
  }

  Future<void> _deleteListing(String listingId, String productName) async {
    final ok = await showAdminConfirmDialog(
      context: context,
      title: 'Delete listing?',
      message:
          '“$productName” will be removed from Products Listing and from the app home feed.',
      confirmText: 'Delete',
    );
    if (!ok) return;

    setState(() => _isDeleting = true);
    try {
      await _db.collection('productsListing').doc(listingId).delete();
      if (!mounted) return;
      setState(() {
        _items.removeWhere((e) => e['listingId'] == listingId);
        _isDeleting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Listing deleted')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete: $e')),
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
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
                child: SizedBox(
                  width: width <= 520 ? 260 : width < 768 ? 370 : 500,
                  child: TextField(
                    onChanged: (v) => setState(() => searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Search products',
                      hintStyle: const TextStyle(color: Colors.white),
                      fillColor: primaryColor,
                      filled: true,
                      border: const OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      suffixIcon: const Icon(Icons.search, color: Colors.white),
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Refresh',
                onPressed: _initialLoading ? null : _refresh,
                icon: const Icon(Icons.refresh, color: primaryColor),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Expanded(child: Text('Image', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: primaryColor))),
                Expanded(child: Text('Title', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: primaryColor))),
                Expanded(child: Text('Brand', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: primaryColor))),
                Expanded(child: Text('Date', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: primaryColor))),
                Expanded(child: Text('Price', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: primaryColor))),
                Expanded(child: Text('Action', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: primaryColor))),
              ],
            ),
          ),
          Expanded(
            child: _initialLoading
                ? const AdminLoader(message: 'Loading products...')
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Error: $_error',
                                style: const TextStyle(color: Colors.red)),
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
                        ? const AdminEmptyState(message: 'No listings found')
                        : RefreshIndicator(
                            color: primaryColor,
                            onRefresh: _refresh,
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: rows.length + 1,
                              itemBuilder: (context, index) {
                                if (index == rows.length) {
                                  return AdminLoadMoreBar(
                                    hasMore: searchQuery.isEmpty &&
                                        _paginator.hasMore,
                                    isLoadingMore: _loadingMore,
                                    loadedCount: _items.length,
                                    onLoadMore: _loadMore,
                                  );
                                }

                                final bookData = rows[index];
                                final listingId =
                                    (bookData['listingId'] ?? '').toString();
                                final productName =
                                    (bookData['productName'] ?? 'Listing')
                                        .toString();
                                final images = bookData['productImages'];

                                return Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 6),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Container(
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
                                          ),
                                          Expanded(
                                            child: Text(
                                              productName,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                  color: secondaryColor,
                                                  fontSize: 15),
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              (bookData['brand'] ?? 'N/A')
                                                  .toString(),
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                  color: secondaryColor,
                                                  fontSize: 15),
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              _formatTimestamp(
                                                  bookData['postedDate']),
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                  color: secondaryColor,
                                                  fontSize: 15),
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              '\$${bookData['productPrice'] ?? 'N/A'}',
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                  color: secondaryColor,
                                                  fontSize: 15),
                                            ),
                                          ),
                                          Expanded(
                                            child: Center(
                                              child: TextButton.icon(
                                                onPressed: _isDeleting ||
                                                        listingId.isEmpty
                                                    ? null
                                                    : () => _deleteListing(
                                                          listingId,
                                                          productName,
                                                        ),
                                                icon: const Icon(Icons.delete,
                                                    color: Colors.redAccent,
                                                    size: 18),
                                                label: const Text(
                                                  'Delete',
                                                  style: TextStyle(
                                                    color: Colors.redAccent,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ),
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

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import '../../const/constants.dart';
import '../../controller/sidebarController.dart';
import '../../helper/firestore_paginator.dart';
import '../../widgets/admin_loaders.dart';
import '../../widgets/confirm_dialog.dart';

class Order_Screen extends StatefulWidget {
  const Order_Screen({super.key});

  @override
  State<Order_Screen> createState() => _Order_ScreenState();
}

FirebaseFirestore firestore = FirebaseFirestore.instance;

class _Order_ScreenState extends State<Order_Screen> {
  String searchQuery = '';
  bool _isDeleting = false;
  bool _isLoadingOrders = true;
  bool _loadingMore = false;
  String? _ordersError;
  final Set<String> _selectedOrderIds = {};
  List<Map<String, dynamic>> _enrichedOrders = [];
  late final FirestorePaginator _paginator;
  final SidebarController sidebarController = Get.put(SidebarController());
  final Map<String, Map<String, dynamic>> _userCache = {};
  final Map<String, Map<String, dynamic>> _productCache = {};

  @override
  void initState() {
    super.initState();
    _paginator = FirestorePaginator(
      query: firestore.collection('orders').orderBy(FieldPath.documentId),
      pageSize: 15,
    );
    _refreshOrders();
  }

  Future<void> _refreshOrders() async {
    setState(() {
      _isLoadingOrders = true;
      _ordersError = null;
    });
    try {
      final docs = await _paginator.refresh();
      final enriched = <Map<String, dynamic>>[];
      for (final doc in docs) {
        enriched.add(await getOrderDetails(
          doc.data() as Map<String, dynamic>,
          doc.id,
        ));
      }
      if (!mounted) return;
      setState(() {
        _enrichedOrders = enriched;
        _isLoadingOrders = false;
        _selectedOrderIds.removeWhere(
          (id) => !enriched.any((o) => o['orderId'] == id),
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingOrders = false;
        _ordersError = e.toString();
      });
    }
  }

  Future<void> _loadMoreOrders() async {
    if (_loadingMore || !_paginator.hasMore || searchQuery.trim().isNotEmpty) {
      return;
    }
    setState(() => _loadingMore = true);
    try {
      final docs = await _paginator.loadMore();
      final enriched = <Map<String, dynamic>>[];
      for (final doc in docs) {
        enriched.add(await getOrderDetails(
          doc.data() as Map<String, dynamic>,
          doc.id,
        ));
      }
      if (!mounted) return;
      setState(() {
        _enrichedOrders.addAll(enriched);
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load more orders: $e')),
      );
    }
  }

  List<Map<String, dynamic>> get _filteredOrders {
    final q = searchQuery.toLowerCase().trim();
    if (q.isEmpty) return _enrichedOrders;
    return _enrichedOrders.where((order) {
      final buyerName = (order['buyerName'] ?? '').toString().toLowerCase();
      final sellerName = (order['sellerName'] ?? '').toString().toLowerCase();
      final productName = (order['productName'] ?? '').toString().toLowerCase();
      return buyerName.contains(q) ||
          sellerName.contains(q) ||
          productName.contains(q);
    }).toList();
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp != null && timestamp is Timestamp) {
      final dateTime = timestamp.toDate();
      return "${dateTime.day}/${dateTime.month}/${dateTime.year}";
    }
    return 'N/A';
  }

  String _formatDateTime(dynamic timestamp) {
    if (timestamp != null && timestamp is Timestamp) {
      final d = timestamp.toDate();
      final hh = d.hour.toString().padLeft(2, '0');
      final mm = d.minute.toString().padLeft(2, '0');
      return "${d.day}/${d.month}/${d.year}  $hh:$mm";
    }
    return 'N/A';
  }

  Future<Map<String, dynamic>> getUserData(String userId) async {
    if (userId.isEmpty) return {};
    if (_userCache.containsKey(userId)) return _userCache[userId]!;
    final userDoc =
        await firestore.collection('userDetails').doc(userId).get();
    final data = (userDoc.exists && userDoc.data() != null)
        ? userDoc.data() as Map<String, dynamic>
        : <String, dynamic>{};
    _userCache[userId] = data;
    return data;
  }

  Future<Map<String, dynamic>> getBookData(String listingId) async {
    if (listingId.isEmpty) return {};
    if (_productCache.containsKey(listingId)) return _productCache[listingId]!;
    final bookDoc =
        await firestore.collection('productsListing').doc(listingId).get();
    final data = (bookDoc.exists && bookDoc.data() != null)
        ? bookDoc.data() as Map<String, dynamic>
        : <String, dynamic>{};
    _productCache[listingId] = data;
    return data;
  }

  Future<Map<String, dynamic>> getOrderDetails(
    Map<String, dynamic> order,
    String orderId,
  ) async {
    final buyerId = (order['buyerId'] ?? '').toString();
    final sellerId = (order['sellerId'] ?? '').toString();
    final productId = (order['productId'] ?? '').toString();

    final buyerData = await getUserData(buyerId);
    final sellerData = await getUserData(sellerId);
    final bookData = await getBookData(productId);

    final productName = bookData['productName'] ??
        order['productName'] ??
        'Unknown';
    final productImages = (bookData['productImages'] is List &&
            (bookData['productImages'] as List).isNotEmpty)
        ? bookData['productImages']
        : (order['productImage'] != null &&
                order['productImage'].toString().isNotEmpty)
            ? [order['productImage']]
            : <dynamic>[];

    return {
      ...order,
      'orderId': orderId,
      'productName': productName,
      'productImages': productImages,
      'buyerName': buyerData['userName'] ?? 'Unknown',
      'sellerName': sellerData['userName'] ?? 'Unknown',
      'buyerEmail': buyerData['email'] ?? '',
      'sellerEmail': sellerData['email'] ?? '',
      'orderDate': order['orderDate'],
      'finalPrice': order['finalPrice'] ?? order['buyingPrice'] ?? 0,
    };
  }

  String _statusLabel(Map<String, dynamic> order) {
    if (order['refund'] == true || order['isCancelled'] == true) {
      return 'Refunded / Cancelled';
    }
    if (order['deliveryStatus'] == true) return 'Delivered';
    if (order['isOrdered'] == true) return 'Ordered';
    return 'Pending';
  }

  Color _statusColor(String label) {
    switch (label) {
      case 'Delivered':
        return Colors.green;
      case 'Ordered':
        return primaryColor;
      case 'Refunded / Cancelled':
        return Colors.redAccent;
      default:
        return Colors.orange;
    }
  }

  Future<void> _deleteOrder(String orderId, String productName) async {
    final shouldDelete = await showAdminConfirmDialog(
      context: context,
      title: 'Delete order?',
      message:
          'This will permanently delete the order for “$productName” from Firestore. This cannot be undone.',
      confirmText: 'Delete',
      icon: Icons.delete_outline_rounded,
    );
    if (!shouldDelete) return;

    setState(() => _isDeleting = true);
    try {
      await firestore.collection('orders').doc(orderId).delete();
      _selectedOrderIds.remove(orderId);
      _enrichedOrders.removeWhere((o) => o['orderId'] == orderId);
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order deleted')),
      );
    } catch (e) {
      debugPrint('Error deleting order: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete order: $e')),
      );
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  Future<void> _deleteSelectedOrders() async {
    final ids = _selectedOrderIds.toList();
    if (ids.isEmpty) return;

    final shouldDelete = await showAdminConfirmDialog(
      context: context,
      title: 'Delete ${ids.length} orders?',
      message:
          'You are about to permanently delete ${ids.length} selected order${ids.length == 1 ? '' : 's'}. This cannot be undone.',
      confirmText: 'Delete all',
      icon: Icons.delete_sweep_outlined,
    );
    if (!shouldDelete) return;

    setState(() => _isDeleting = true);
    try {
      for (var i = 0; i < ids.length; i += 450) {
        final chunk = ids.skip(i).take(450);
        final batch = firestore.batch();
        for (final id in chunk) {
          batch.delete(firestore.collection('orders').doc(id));
        }
        await batch.commit();
      }
      _selectedOrderIds.clear();
      _enrichedOrders.removeWhere((o) => ids.contains(o['orderId']));
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${ids.length} orders deleted')),
      );
    } catch (e) {
      debugPrint('Error bulk deleting orders: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete selected orders: $e')),
      );
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  void _toggleSelectAll(List<Map<String, dynamic>> orders) {
    final ids = orders
        .map((o) => (o['orderId'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toList();
    final allSelected =
        ids.isNotEmpty && ids.every(_selectedOrderIds.contains);
    setState(() {
      if (allSelected) {
        _selectedOrderIds.removeAll(ids);
      } else {
        _selectedOrderIds.addAll(ids);
      }
    });
  }

  void _toggleOrderSelection(String orderId) {
    if (orderId.isEmpty) return;
    setState(() {
      if (_selectedOrderIds.contains(orderId)) {
        _selectedOrderIds.remove(orderId);
      } else {
        _selectedOrderIds.add(orderId);
      }
    });
  }

  void _showOrderDetail(Map<String, dynamic> order) {
    final images = order['productImages'];
    final imageUrl = (images is List && images.isNotEmpty)
        ? images[0].toString()
        : null;
    final status = _statusLabel(order);
    final statusColor = _statusColor(status);
    final orderId = (order['orderId'] ?? '').toString();
    final productName = (order['productName'] ?? 'Order').toString();

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520, maxHeight: 640),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
                    color: primaryColor.withOpacity(0.08),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Order details',
                            style: TextStyle(
                              color: Color(0xFF1A1A1A),
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          icon: Icon(Icons.close, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: 88,
                                  height: 88,
                                  color: Colors.grey.shade100,
                                  child: imageUrl != null
                                      ? Image.network(imageUrl,
                                          fit: BoxFit.cover)
                                      : const Icon(Icons.image_not_supported),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      productName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1A1A1A),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        status,
                                        style: TextStyle(
                                          color: statusColor,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _detailRow('Order ID', orderId),
                          _detailRow('Buyer', order['buyerName']?.toString() ?? '—'),
                          if ((order['buyerEmail'] ?? '')
                              .toString()
                              .isNotEmpty)
                            _detailRow(
                                'Buyer email', order['buyerEmail'].toString()),
                          _detailRow(
                              'Seller', order['sellerName']?.toString() ?? '—'),
                          if ((order['sellerEmail'] ?? '')
                              .toString()
                              .isNotEmpty)
                            _detailRow(
                                'Seller email', order['sellerEmail'].toString()),
                          _detailRow(
                              'Date', _formatDateTime(order['orderDate'])),
                          _detailRow(
                            'Price',
                            '${order['finalPrice'] ?? order['buyingPrice'] ?? 0} AED',
                          ),
                          _detailRow(
                            'Delivery type',
                            (order['deliveryType'] ?? 'standard').toString(),
                          ),
                          if ((order['shipmentAddress'] ?? '')
                              .toString()
                              .isNotEmpty)
                            _detailRow('Address',
                                order['shipmentAddress'].toString()),
                          if ((order['awbNumber'] ?? '')
                              .toString()
                              .isNotEmpty)
                            _detailRow(
                                'AWB', order['awbNumber'].toString()),
                          if (order['refund'] == true)
                            _detailRow(
                              'Refund reason',
                              (order['refundReason'] ?? '—').toString(),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey.shade800,
                              side: BorderSide(color: Colors.grey.shade300),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Close',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: orderId.isEmpty
                                ? null
                                : () async {
                                    Navigator.of(ctx).pop();
                                    await _deleteOrder(orderId, productName);
                                  },
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: const Text(
                              'Delete',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE53935),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF1A1A1A),
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
                      left: width <= 375
                          ? 10
                          : width <= 520
                              ? 10
                              : width < 768
                                  ? 15
                                  : 15,
                      top: 20,
                      bottom: 20,
                    ),
                    child: SizedBox(
                      width: width <= 375
                          ? 200
                          : width <= 425
                              ? 240
                              : width <= 520
                                  ? 260
                                  : width < 768
                                      ? 370
                                      : width < 1024
                                          ? 400
                                          : 500,
                      child: TextField(
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: "Search",
                          hintStyle: const TextStyle(color: Colors.white),
                          fillColor: primaryColor,
                          filled: true,
                          border: const OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius:
                                BorderRadius.all(Radius.circular(10)),
                          ),
                          suffixIcon: Container(
                            padding:
                                const EdgeInsets.all(defaultPadding * 0.75),
                            margin: const EdgeInsets.symmetric(
                                horizontal: defaultPadding / 2),
                            decoration: const BoxDecoration(
                              color: primaryColor,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10)),
                            ),
                            child: const Icon(
                              Icons.search,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh',
                    onPressed: _isLoadingOrders ? null : _refreshOrders,
                    icon: const Icon(Icons.refresh, color: primaryColor),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    const SizedBox(width: 48),
                    _headerCell(width, 'Image'),
                    _headerCell(width, 'Title'),
                    _headerCell(width, 'Buyer'),
                    _headerCell(width, 'Seller'),
                    _headerCell(width, 'Date'),
                    _headerCell(width, 'Price'),
                    _headerCell(width, 'Action'),
                  ],
                ),
              ),
              Expanded(
                child: _buildOrderList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _selectionBar(List<Map<String, dynamic>> filteredOrders) {
    final visibleIds = filteredOrders
        .map((o) => (o['orderId'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toList();
    final allSelected = visibleIds.isNotEmpty &&
        visibleIds.every(_selectedOrderIds.contains);
    final selectedCount = _selectedOrderIds.length;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Checkbox(
            value: allSelected,
            activeColor: primaryColor,
            onChanged: _isDeleting
                ? null
                : (_) => _toggleSelectAll(filteredOrders),
          ),
          Text(
            selectedCount == 0
                ? 'Select orders'
                : '$selectedCount selected',
            style: const TextStyle(
              color: Color(0xFF1A1A1A),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          if (selectedCount > 0) ...[
            TextButton(
              onPressed: _isDeleting
                  ? null
                  : () => setState(() => _selectedOrderIds.clear()),
              child: const Text('Clear'),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _isDeleting ? null : _deleteSelectedOrders,
              icon: _isDeleting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.delete_sweep, size: 18),
              label: Text(
                'Delete selected ($selectedCount)',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _headerCell(double width, String text) {
    return Expanded(
      child: Text(
        overflow: width <= 520 ? TextOverflow.ellipsis : TextOverflow.visible,
        maxLines: width <= 520 ? 1 : 2,
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: primaryColor,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildOrderList() {
    final width = MediaQuery.of(context).size.width;

    if (_isLoadingOrders && _enrichedOrders.isEmpty) {
      return const AdminLoader(message: 'Loading orders...');
    }
    if (_ordersError != null && _enrichedOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Error: $_ordersError'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _refreshOrders,
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final filteredOrders = _filteredOrders;
    if (filteredOrders.isEmpty) {
      return const AdminEmptyState(message: 'No orders found');
    }

    return Column(
      children: [
        _selectionBar(filteredOrders),
        Expanded(
          child: RefreshIndicator(
            color: primaryColor,
            onRefresh: _refreshOrders,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: filteredOrders.length + 1,
              itemBuilder: (context, index) {
                if (index == filteredOrders.length) {
                  return AdminLoadMoreBar(
                    hasMore: searchQuery.trim().isEmpty && _paginator.hasMore,
                    isLoadingMore: _loadingMore,
                    loadedCount: _enrichedOrders.length,
                    onLoadMore: _loadMoreOrders,
                  );
                }

                final order = filteredOrders[index];
                final orderId = (order['orderId'] ?? '').toString();
                final productName = (order['productName'] ?? 'Order').toString();
                final isSelected = _selectedOrderIds.contains(orderId);

                return Column(
                  children: [
                    Material(
                      color: isSelected
                          ? primaryColor.withOpacity(0.06)
                          : Colors.transparent,
                      child: InkWell(
                        onTap: () => _showOrderDetail(order),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 48,
                                child: Checkbox(
                                  value: isSelected,
                                  activeColor: primaryColor,
                                  onChanged: _isDeleting || orderId.isEmpty
                                      ? null
                                      : (_) => _toggleOrderSelection(orderId),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    image: DecorationImage(
                                      image: (order['productImages'] != null &&
                                              order['productImages'].isNotEmpty)
                                          ? NetworkImage(order['productImages'][0])
                                          : const AssetImage('assets/images/logo.png')
                                              as ImageProvider,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  productName,
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
                                  order['buyerName'] ?? 'Unknown',
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
                                  order['sellerName'] ?? 'Unknown',
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
                                  overflow: width <= 520
                                      ? TextOverflow.ellipsis
                                      : TextOverflow.visible,
                                  maxLines: width <= 520 ? 1 : 2,
                                  _formatTimestamp(order['orderDate']),
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
                                  (order['finalPrice'] ?? '0').toString(),
                                  style: const TextStyle(
                                    color: secondaryColor,
                                    fontWeight: FontWeight.w400,
                                    fontSize: 15,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: TextButton.icon(
                                    onPressed: _isDeleting || orderId.isEmpty
                                        ? null
                                        : () => _deleteOrder(orderId, productName),
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.redAccent,
                                      size: 18,
                                    ),
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
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 30),
                      child: Divider(color: Colors.grey, thickness: 2),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

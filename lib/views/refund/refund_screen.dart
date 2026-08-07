import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../const/constants.dart';
import '../../controller/sidebarController.dart';
import '../../helper/firestore_paginator.dart';
import '../../widgets/admin_loaders.dart';
import '../../widgets/custom_button.dart';

class RefundScreen extends StatefulWidget {
  const RefundScreen({super.key});

  @override
  State<RefundScreen> createState() => _RefundScreenState();
}

class _RefundScreenState extends State<RefundScreen> {
  final SidebarController sidebarController = Get.put(SidebarController());
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final FirestorePaginator _paginator;
  final List<Map<String, dynamic>> _items = [];
  String searchQuery = '';
  bool _loading = true;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _paginator = FirestorePaginator(
      query: _firestore
          .collection('refundRequests')
          .orderBy(FieldPath.documentId),
      pageSize: 20,
    );
    _cleanupExpiredRequests();
    _refresh();
  }

  Future<void> _cleanupExpiredRequests() async {
    try {
      DateTime threshold = DateTime.now().subtract(const Duration(hours: 48));
      QuerySnapshot expiredSnapshot = await _firestore
          .collection('refundRequests')
          .where('status', isEqualTo: 'pending')
          .where('createdAt', isLessThan: Timestamp.fromDate(threshold))
          .get();

      if (expiredSnapshot.docs.isNotEmpty) {
        WriteBatch batch = _firestore.batch();
        for (var doc in expiredSnapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
    } catch (e) {
      print("Error cleaning up expired requests: $e");
    }
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

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp != null && timestamp is Timestamp) {
      DateTime dateTime = timestamp.toDate();
      return DateFormat('dd/MM/yyyy hh:mm a').format(dateTime);
    }
    return 'N/A';
  }

  Future<void> _processRefund(
      Map<String, dynamic> data, String docId, String status) async {
    try {
      final String buyerId = data['buyerId'] ?? '';
      final double refundAmount =
          double.tryParse(data['amount'].toString()) ?? 0.0;

      if (status == 'approved') {
        QuerySnapshot walletSnapshot = await _firestore
            .collection('wallet')
            .where('userId', isEqualTo: buyerId)
            .limit(1)
            .get();

        if (walletSnapshot.docs.isEmpty) {
          Get.snackbar("Error", "No wallet found for user ID: $buyerId",
              backgroundColor: Colors.red, colorText: Colors.white);
          return;
        }

        DocumentReference walletDocRef = walletSnapshot.docs.first.reference;
        WriteBatch batch = _firestore.batch();

        batch.update(_firestore.collection('refundRequests').doc(docId), {
          'status': 'approved',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        batch.update(walletDocRef, {
          'balance': FieldValue.increment(refundAmount),
        });

        DocumentReference transRef =
            walletDocRef.collection('transaction').doc();
        batch.set(transRef, {
          'buyerId': buyerId,
          'date': FieldValue.serverTimestamp(),
          'price': refundAmount,
          'productName': data['productName'] ?? 'N/A',
          'sellerId': data['sellerId'] ?? '',
          'sellerName': data['sellerName'] ?? '',
          'type': 'refund',
          'userImage': data['userImage'] ?? '',
          'userName': data['userName'] ?? '',
        });

        await batch.commit();
        setState(() {
          final i = _items.indexWhere((e) => e['docId'] == docId);
          if (i >= 0) _items[i]['status'] = 'approved';
        });
        Get.snackbar("Success", "Refund Approved and Wallet Updated",
            backgroundColor: Colors.green, colorText: Colors.white);
      } else {
        await _firestore.collection('refundRequests').doc(docId).update({
          'status': 'rejected',
          'updatedAt': FieldValue.serverTimestamp(),
        });
        setState(() {
          final i = _items.indexWhere((e) => e['docId'] == docId);
          if (i >= 0) _items[i]['status'] = 'rejected';
        });
        Get.snackbar("Rejected", "Refund Request was rejected",
            backgroundColor: Colors.orange, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar("Error", "Something went wrong: $e",
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  void _showActionDialog(
      Map<String, dynamic> data, String docId, String action) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: primaryColor,
        title: Text("Confirm $action",
            style: const TextStyle(color: Colors.white)),
        content: Text("Are you sure you want to $action this request?",
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text("Cancel", style: TextStyle(color: Colors.white54)),
          ),
          CustomButton(
            width: 100,
            height: 40,
            text: "Confirm",
            onPressed: () {
              Navigator.pop(context);
              _processRefund(
                  data, docId, action == 'Approve' ? 'approved' : 'rejected');
            },
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> get _filtered {
    final threshold = DateTime.now().subtract(const Duration(hours: 48));
    final q = searchQuery.toLowerCase().trim();

    return _items.where((d) {
      final status = (d['status'] ?? 'pending').toString();
      final createdAt = d['createdAt'];
      if (status == 'pending' &&
          createdAt is Timestamp &&
          createdAt.toDate().isBefore(threshold)) {
        return false;
      }
      if (q.isEmpty) return true;
      return (d['productName'] ?? '').toString().toLowerCase().contains(q) ||
          (d['buyerId'] ?? '').toString().toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final rows = _filtered;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                if (Get.width < 768)
                  IconButton(
                    icon: const Icon(Icons.menu, color: primaryColor),
                    onPressed: () => sidebarController.showsidebar.value = true,
                  ),
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => searchQuery = v),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Search Product or Buyer ID...",
                      hintStyle: const TextStyle(color: Colors.white54),
                      fillColor: primaryColor,
                      filled: true,
                      prefixIcon: const Icon(Icons.search, color: Colors.white),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _loading ? null : _refresh,
                  icon: const Icon(Icons.refresh, color: primaryColor),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Row(
              children: [
                Expanded(
                    child: Text('Product',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: primaryColor),
                        textAlign: TextAlign.center)),
                Expanded(
                    child: Text('Amount',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: primaryColor),
                        textAlign: TextAlign.center)),
                Expanded(
                    child: Text('Status',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: primaryColor),
                        textAlign: TextAlign.center)),
                Expanded(
                    child: Text('Actions',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: primaryColor),
                        textAlign: TextAlign.center)),
              ],
            ),
            const Divider(color: primaryColor),
            Expanded(
              child: _loading
                  ? const AdminLoader(message: 'Loading refunds...')
                  : rows.isEmpty
                      ? const AdminEmptyState(message: 'No refund requests')
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

                              final data = rows[index];
                              final docId = (data['docId'] ?? '').toString();
                              final status =
                                  (data['status'] ?? 'pending').toString();

                              return Column(
                                children: [
                                  ListTile(
                                    title: Row(
                                      children: [
                                        Expanded(
                                            child: Text(
                                                data['productName'] ?? 'N/A',
                                                style: const TextStyle(
                                                    color: Colors.black),
                                                textAlign: TextAlign.center)),
                                        Expanded(
                                            child: Text(
                                                "Rs. ${data['amount']}",
                                                style: const TextStyle(
                                                    color: Colors.black),
                                                textAlign: TextAlign.center)),
                                        Expanded(
                                          child: Center(
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                color: status == 'approved'
                                                    ? Colors.green
                                                        .withOpacity(0.1)
                                                    : status == 'rejected'
                                                        ? Colors.red
                                                            .withOpacity(0.1)
                                                        : Colors.orange
                                                            .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                status.toUpperCase(),
                                                style: TextStyle(
                                                    color: status == 'approved'
                                                        ? Colors.green
                                                        : status == 'rejected'
                                                            ? Colors.red
                                                            : Colors.orange,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 11),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              if (status == 'pending') ...[
                                                IconButton(
                                                    icon: const Icon(
                                                        Icons.check_circle,
                                                        color: Colors.green),
                                                    onPressed: () =>
                                                        _showActionDialog(data,
                                                            docId, 'Approve')),
                                                IconButton(
                                                    icon: const Icon(
                                                        Icons.cancel,
                                                        color: Colors.red),
                                                    onPressed: () =>
                                                        _showActionDialog(data,
                                                            docId, 'Reject')),
                                              ] else
                                                Text(
                                                    status.capitalizeFirst ??
                                                        status,
                                                    style: const TextStyle(
                                                        color: Colors.grey)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    subtitle: Text(
                                      _formatTimestamp(data['createdAt']),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 11),
                                    ),
                                  ),
                                  const Divider(thickness: 0.5),
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

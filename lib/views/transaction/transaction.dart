import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../const/constants.dart';
import '../../controller/sidebarController.dart';
import '../../helper/firestore_paginator.dart';
import '../../widgets/admin_loaders.dart';

class Transaction1 extends StatefulWidget {
  @override
  _Transaction1State createState() => _Transaction1State();
}

class _Transaction1State extends State<Transaction1> {
  String searchQuery = '';
  List<Map<String, dynamic>> allTransactions = [];
  List<Map<String, dynamic>> filteredTransactions = [];
  final SidebarController sidebarController = Get.put(SidebarController());
  late final FirestorePaginator _walletPaginator;
  bool loading = true;
  bool loadingMore = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _walletPaginator = FirestorePaginator(
      query: FirebaseFirestore.instance
          .collection('wallet')
          .orderBy(FieldPath.documentId),
      pageSize: 12,
    );
    fetchFirstPage();
  }

  DateTime? _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  Map<String, dynamic> _normalizeTransaction(
    Map<String, dynamic> raw, {
    required String walletUserId,
    String? userName,
    String? userImage,
  }) {
    final type = (raw['type'] ?? raw['purchaseType'] ?? 'unknown').toString();
    final price = raw['price'] ??
        raw['amount'] ??
        raw['purchasePrice'] ??
        raw['finalPrice'] ??
        0;
    final date = raw['date'] ??
        raw['transactionDate'] ??
        raw['purchaseDate'] ??
        raw['createdAt'];

    return {
      ...raw,
      'walletUserId': walletUserId,
      'type': type,
      'price': price,
      'date': date,
      'productName':
          (raw['productName'] ?? raw['purchaseName'] ?? '').toString(),
      'userName': (raw['userName'] ?? userName ?? walletUserId).toString(),
      'userImage': (raw['userImage'] ?? userImage ?? '').toString(),
      'sellerName': (raw['sellerName'] ?? '').toString(),
    };
  }

  Future<List<Map<String, dynamic>>> _txnsForWallets(
    List<QueryDocumentSnapshot> walletDocs,
  ) async {
    final firestore = FirebaseFirestore.instance;
    final collected = <Map<String, dynamic>>[];

    for (final walletDoc in walletDocs) {
      final walletUserId = walletDoc.id;

      String? userName;
      String? userImage;
      try {
        final userSnap =
            await firestore.collection('userDetails').doc(walletUserId).get();
        final userData = userSnap.data();
        userName = userData?['userName']?.toString();
        userImage = userData?['userImage']?.toString();
      } catch (_) {}

      final transactionsSnapshot = await firestore
          .collection('wallet')
          .doc(walletUserId)
          .collection('transaction')
          .get();

      for (final transactionDoc in transactionsSnapshot.docs) {
        final raw = transactionDoc.data();
        final normalized = _normalizeTransaction(
          raw,
          walletUserId: walletUserId,
          userName: userName,
          userImage: userImage,
        );

        if ((normalized['type'] as String).toLowerCase() == 'withdraw') {
          continue;
        }
        collected.add(normalized);
      }
    }

    collected.sort((a, b) {
      final aDate = _parseDate(a['date']) ?? DateTime(2000);
      final bDate = _parseDate(b['date']) ?? DateTime(2000);
      return bDate.compareTo(aDate);
    });
    return collected;
  }

  Future<void> fetchFirstPage() async {
    setState(() {
      loading = true;
      errorMessage = null;
      allTransactions = [];
      filteredTransactions = [];
    });

    try {
      final walletDocs = await _walletPaginator.refresh();
      final collected = await _txnsForWallets(walletDocs);
      if (!mounted) return;
      setState(() {
        allTransactions = collected;
        loading = false;
      });
      filterTransactions();
    } catch (e) {
      debugPrint('Error fetching transactions: $e');
      if (!mounted) return;
      setState(() {
        loading = false;
        errorMessage = e.toString();
      });
    }
  }

  Future<void> loadMore() async {
    if (loadingMore ||
        !_walletPaginator.hasMore ||
        searchQuery.trim().isNotEmpty) {
      return;
    }
    setState(() => loadingMore = true);
    try {
      final walletDocs = await _walletPaginator.loadMore();
      final collected = await _txnsForWallets(walletDocs);
      if (!mounted) return;
      setState(() {
        allTransactions.addAll(collected);
        allTransactions.sort((a, b) {
          final aDate = _parseDate(a['date']) ?? DateTime(2000);
          final bDate = _parseDate(b['date']) ?? DateTime(2000);
          return bDate.compareTo(aDate);
        });
        loadingMore = false;
      });
      filterTransactions();
    } catch (e) {
      if (!mounted) return;
      setState(() => loadingMore = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load more: $e')),
      );
    }
  }

  void filterTransactions() {
    setState(() {
      if (searchQuery.isEmpty) {
        filteredTransactions = List.from(allTransactions);
      } else {
        final q = searchQuery.toLowerCase();
        filteredTransactions = allTransactions.where((transaction) {
          final userName =
              transaction['userName']?.toString().toLowerCase() ?? '';
          final productName =
              transaction['productName']?.toString().toLowerCase() ?? '';
          final type = transaction['type']?.toString().toLowerCase() ?? '';
          final sellerName =
              transaction['sellerName']?.toString().toLowerCase() ?? '';
          return userName.contains(q) ||
              productName.contains(q) ||
              type.contains(q) ||
              sellerName.contains(q);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

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
                        searchQuery = value;
                        filterTransactions();
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
                const SizedBox(width: 12),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: loading ? null : fetchFirstPage,
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
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: primaryColor),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'User Name',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: primaryColor),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Product Name',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: primaryColor),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Type',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: primaryColor),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Price',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: primaryColor),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Date',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: primaryColor),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Seller Name',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: primaryColor),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: loading
                  ? const AdminLoader(message: 'Loading transactions...')
                  : errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Failed to load transactions\n$errorMessage',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.red),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: fetchFirstPage,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                  ),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : filteredTransactions.isEmpty
                          ? const AdminEmptyState(
                              message: 'No transactions found')
                          : RefreshIndicator(
                              color: primaryColor,
                              onRefresh: fetchFirstPage,
                              child: ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: filteredTransactions.length + 1,
                                itemBuilder: (context, index) {
                                  if (index == filteredTransactions.length) {
                                    return AdminLoadMoreBar(
                                      hasMore: searchQuery.trim().isEmpty &&
                                          _walletPaginator.hasMore,
                                      isLoadingMore: loadingMore,
                                      loadedCount: allTransactions.length,
                                      onLoadMore: loadMore,
                                    );
                                  }

                                  final transaction =
                                      filteredTransactions[index];
                                  final date = _parseDate(transaction['date']);
                                  final formattedDate = date != null
                                      ? DateFormat(
                                              "d MMMM yyyy 'at' HH:mm:ss")
                                          .format(date)
                                      : 'N/A';
                                  final imageUrl =
                                      transaction['userImage']?.toString() ??
                                          '';

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
                                                backgroundImage:
                                                    imageUrl.isNotEmpty
                                                        ? NetworkImage(imageUrl)
                                                        : null,
                                                child: imageUrl.isEmpty
                                                    ? const Icon(Icons.person,
                                                        color: Colors.white)
                                                    : null,
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                transaction['userName'] ?? '',
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
                                                transaction['productName'] ??
                                                    '',
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
                                                transaction['type'] ?? '',
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
                                                (transaction['price'] ?? 0)
                                                    .toString(),
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
                                                formattedDate,
                                                style: const TextStyle(
                                                  color: secondaryColor,
                                                  fontWeight: FontWeight.w400,
                                                  fontSize: 13,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                transaction['sellerName'] ??
                                                    '',
                                                style: const TextStyle(
                                                  color: secondaryColor,
                                                  fontWeight: FontWeight.w400,
                                                  fontSize: 15,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 30),
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
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../const/constants.dart';
import '../../controller/sidebarController.dart';

class Transaction1 extends StatefulWidget {
  @override
  _Transaction1State createState() => _Transaction1State();
}

class _Transaction1State extends State<Transaction1> {
  String searchQuery = '';
  List<Map<String, dynamic>> allTransactions = [];
  List<Map<String, dynamic>> filteredTransactions = [];
  final SidebarController sidebarController = Get.put(SidebarController());

  RxBool loading = false.obs;

  Future<List<Map<String, dynamic>>> fetchAllTransactions() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    try {
      loading.value = true;
      QuerySnapshot walletSnapshot = await firestore.collection('wallet').get();

      for (var walletDoc in walletSnapshot.docs) {
        CollectionReference transactionsRef = firestore
            .collection('wallet')
            .doc(walletDoc.id)
            .collection('transaction');

        QuerySnapshot transactionsSnapshot =
            await transactionsRef.where('type', isNotEqualTo: 'withdraw').get();

        for (var transactionDoc in transactionsSnapshot.docs) {
          allTransactions.add(transactionDoc.data() as Map<String, dynamic>);
        }
      }
      // Initially, all transactions are shown
      filteredTransactions = List.from(allTransactions);
      loading.value = false;
    } catch (e) {
      print('Error fetching transactions: $e');
      loading.value = false;
    }

    return allTransactions;
  }

  void filterTransactions() {
    setState(() {
      if (searchQuery.isEmpty) {
        filteredTransactions = List.from(allTransactions);
      } else {
        filteredTransactions = allTransactions.where((transaction) {
          final userName = transaction['userName']?.toLowerCase() ?? '';
          final productName = transaction['productName']?.toLowerCase() ?? '';
          return userName.contains(searchQuery.toLowerCase()) ||
              productName.contains(searchQuery.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  void initState() {
    fetchAllTransactions();
    super.initState();
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
                SizedBox(width: 20),
                Get.width < 768
                    ? GestureDetector(
                        onTap: () {
                          sidebarController.showsidebar.value = true;
                        },
                        child: SvgPicture.asset(
                          'assets/images/drawernavigation.svg',
                          colorFilter:
                              ColorFilter.mode(primaryColor, BlendMode.srcIn),
                        ),
                      )
                    : SizedBox.shrink(),
                Padding(
                  padding: EdgeInsets.only(
                    left: width <= 375
                        ? 10
                        : width <= 520
                            ? 10
                            : width < 768
                                ? 15
                                : width < 1024
                                    ? 15
                                    : width <= 1440
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
                                        : width <= 1440
                                            ? 500
                                            : 500,
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value;
                          filterTransactions(); // Call this method to filter transactions
                        });
                      },
                      decoration: InputDecoration(
                        hintText: "Search",
                        hintStyle: TextStyle(color: Colors.white),
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
                            borderRadius: BorderRadius.all(Radius.circular(10)),
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
              child: Obx(
                () => loading.value
                    ? Center(
                        child: CircularProgressIndicator(
                          color: primaryColor,
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredTransactions.length,
                        itemBuilder: (context, index) {
                          var transaction = filteredTransactions[index];
                          var transactionTimestamp =
                              transaction['date'] as Timestamp;
                          var transactionDate = transactionTimestamp.toDate();
                          var formattedDate =
                              DateFormat('d MMMM yyyy \'at\' HH:mm:ss')
                                  .format(transactionDate);

                          return Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      width: 70,
                                      height: 70,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: transaction['userImage'] != null
                                            ? Colors.transparent
                                            : Colors.red,
                                      ),
                                      child: transaction['userImage'] != null
                                          ? CircleAvatar(
                                              backgroundImage: NetworkImage(
                                                  transaction['userImage']),
                                            )
                                          : const Icon(Icons.person,
                                              color: Colors.white),
                                    ),
                                  ),
                                  Expanded(
                                      child: Text(
                                          style: TextStyle(
                                              color: secondaryColor,
                                              fontWeight: FontWeight.w400,
                                              fontSize: 15),
                                          transaction['userName'] ?? '',
                                          textAlign: TextAlign.center)),
                                  Expanded(
                                      child: Text(
                                          style: TextStyle(
                                              color: secondaryColor,
                                              fontWeight: FontWeight.w400,
                                              fontSize: 15),
                                          transaction['productName'] ?? '',
                                          textAlign: TextAlign.center)),
                                  Expanded(
                                      child: Text(
                                          style: TextStyle(
                                              color: secondaryColor,
                                              fontWeight: FontWeight.w400,
                                              fontSize: 15),
                                          transaction['type'] ?? '',
                                          textAlign: TextAlign.center)),
                                  Expanded(
                                      child: Text(
                                          style: TextStyle(
                                              color: secondaryColor,
                                              fontWeight: FontWeight.w400,
                                              fontSize: 15),
                                          transaction['price'].toString() ?? '',
                                          textAlign: TextAlign.center)),
                                  Expanded(
                                      child: Text(
                                          style: TextStyle(
                                              color: secondaryColor,
                                              fontWeight: FontWeight.w400,
                                              fontSize: 15),
                                          formattedDate,
                                          textAlign: TextAlign.center)),
                                  Expanded(
                                      child: Text(
                                          style: TextStyle(
                                              color: secondaryColor,
                                              fontWeight: FontWeight.w400,
                                              fontSize: 15),
                                          transaction['sellerName'] ?? '',
                                          textAlign: TextAlign.center)),
                                ],
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 30),
                                child: Divider(
                                  // height: 20,
                                  thickness: 2,
                                  color: Colors.grey,
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

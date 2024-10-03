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
  final SidebarController sidebarController = Get.put(SidebarController());

  RxBool loading = false.obs;
  Future<List<Map<String, dynamic>>> fetchAllTransactions() async {
    // Reference to the Firestore instance
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    // List to store all transactions

    try {
      // Get all documents in the wallet collection
      loading.value = true;
      QuerySnapshot walletSnapshot = await firestore.collection('wallet').get();

      // Iterate through each wallet document
      for (var walletDoc in walletSnapshot.docs) {
        // Get the transactions subcollection for the current wallet document
        CollectionReference transactionsRef = firestore
            .collection('wallet')
            .doc(walletDoc.id)
            .collection('transaction');

        // Get all transactions in the subcollection
        QuerySnapshot transactionsSnapshot = await transactionsRef.where('type',isNotEqualTo: 'withdraw').get();

        // Iterate through each transaction document
        for (var transactionDoc in transactionsSnapshot.docs) {
          // Add the transaction data to the allTransactions list
          allTransactions.add(transactionDoc.data() as Map<String, dynamic>);
        }
      }
      loading.value = false;
      print('bubiyubsyidfby$allTransactions');
    } catch (e) {
      print('Error fetching transactions: $e');
      loading.value = false;
    }

    return allTransactions;
  }

  @override
  void initState() {
    // TODO: implement initState
    fetchAllTransactions();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 25),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: Get.width < 768
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                ),
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
                              ? 10 // You can specify the width for widths less than 425
                              : width < 768
                                  ? 15 // You can specify the width for widths less than 768
                                  : width < 1024
                                      ? 15 // You can specify the width for widths less than 1024
                                      : width <= 1440
                                          ? 15
                                          : width > 1440 && width <= 2550
                                              ? 15
                                              : 15,
                      top: 20,
                      bottom: 20),
                  child: SizedBox(
                    width: width <= 375
                        ? 200
                        : width <= 425
                            ? 240
                            : width <= 520
                                ? 260 // You can specify the width for widths less than 425
                                : width < 768
                                    ? 370 // You can specify the width for widths less than 768
                                    : width < 1024
                                        ? 400 // You can specify the width for widths less than 1024
                                        : width <= 1440
                                            ? 500
                                            : width > 1440 && width <= 2550
                                                ? 500
                                                : 800,
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: "Search",
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
              padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 10),
              child: Row(
                // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // SizedBox(width: 65),
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
                      'Purchase Type',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: primaryColor),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Purchase Price',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: primaryColor),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Purchase Date',
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
                        color: Colors.black,
                      ),
                    )
                  : ListView.builder(
                      itemCount: allTransactions.length,
                      itemBuilder: (context, index) {
                        var transaction = allTransactions[index];
                        var transactionTimestamp =
                            transaction['date'] as Timestamp;
                        var transactionDate = transactionTimestamp.toDate();
                        var formattedDate =
                            DateFormat('d MMMM yyyy \'at\' HH:mm:ss')
                                .format(transactionDate);
                        return Column(
                          children: [
                            Row(
                              // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                // SizedBox(width: 10),
                                Container(
                                  width: 60,
                                  height: 60,
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
                            const Divider(
                              color: Colors.grey,
                              thickness: 2,
                            )
                          ],
                        );
                      },
                    ),
            )),
          ],
        ),
      ),
    );
  }
}

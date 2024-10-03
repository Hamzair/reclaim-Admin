import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../constants.dart';

class Transaction1 extends StatefulWidget {
  @override
  _Transaction1State createState() => _Transaction1State();
}

class _Transaction1State extends State<Transaction1> {
  String searchQuery = '';
  List<Map<String, dynamic>> allTransactions = [];

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
        QuerySnapshot transactionsSnapshot = await transactionsRef.where('purchaseType',isNotEqualTo:'topup',).get();

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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: secondaryColor,
        title: const Text('Transactions History'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 25),
        child: Column(
          children: [

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 100),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: "Search",
                  fillColor: secondaryColor,
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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SizedBox(width: 65),
                  Expanded(
                    child: Text(
                      'User Name',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.blue),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Book Name',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.blue),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Purchase Name',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.blue),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Purchase Price',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.blue),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Purchase Date',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.blue),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Seller Name',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.blue),
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
                      color: Colors.white,

                    ),
                  )
                  : ListView.builder(
                      itemCount: allTransactions.length,
                      itemBuilder: (context, index) {
                        var transaction = allTransactions[index];
                        var transactionTimestamp =
                            transaction['purchaseDate'] as Timestamp;
                        var transactionDate = transactionTimestamp.toDate();
                        var formattedDate =
                            DateFormat('d MMMM yyyy \'at\' HH:mm:ss')
                                .format(transactionDate);
                        return Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                SizedBox(width: 10),
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
                                    child: Text(transaction['userName'] ?? '',
                                        textAlign: TextAlign.center)),
                                Expanded(
                                    child: Text(transaction['bookName'] ?? '',
                                        textAlign: TextAlign.center)),
                                Expanded(
                                    child: Text(
                                        transaction['purchaseName'] ?? '',
                                        textAlign: TextAlign.center)),

                                Expanded(
                                    child: Text(
                                        transaction['purchasePrice']
                                                .toString() ??
                                            '',
                                        textAlign: TextAlign.center)),
                                Expanded(
                                    child: Text(formattedDate,
                                        textAlign: TextAlign.center)),
                                Expanded(
                                    child: Text(transaction['sellerName'] ?? '',
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

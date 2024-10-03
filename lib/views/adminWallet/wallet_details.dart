import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../const/constants.dart';

class WalletDetail extends StatelessWidget {
  final String walletId;

  const WalletDetail({Key? key, required this.walletId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text('Transaction Details'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                SizedBox(width: 65),
                Expanded(
                    child: Text(
                  'Fees',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: primaryColor),
                  textAlign: TextAlign.center,
                )),
                Expanded(
                    child: Text('Date',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: primaryColor),
                        textAlign: TextAlign.center)),
                Expanded(
                    child: Text('Name',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color:primaryColor),
                        textAlign: TextAlign.center)),
                Expanded(
                    child: Text('Type',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: primaryColor),
                        textAlign: TextAlign.center)),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('adminWallet')
                  .doc(walletId)
                  .collection('transaction')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }

                var transactions = snapshot.data!.docs;

                if (transactions.isEmpty) {
                  return Center(
                    child: Text('No transactions found.'),
                  );
                }

                return ListView.builder(
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    var transaction = transactions[index];
                    var transactionTimestamp =
                        transaction['TransactionDate'] as Timestamp;
                    var transactionDate = transactionTimestamp.toDate();
                    var formattedDate =
                        DateFormat('d MMMM yyyy \'at\' HH:mm:ss')
                            .format(transactionDate);
                    var appFees = transaction['appFees'];
                    var transactionType = transaction['purchaseType'];
                    var transactionName = transaction['purchaseName'];
                    // var sellerName = transaction['sellerName'];

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 5),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              SizedBox(width: 65),
                              Expanded(
                                child: Text(
                                  style: TextStyle(
                                      color: secondaryColor,
                                      fontWeight: FontWeight.w400,
                                      fontSize: 15),
                                  '${appFees ?? 'N/A'} Aed',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              // Expanded(
                              //   child: Text(
                              //     '$sellerName',
                              //     textAlign: TextAlign.center,
                              //   ),
                              // ),
                              Expanded(
                                child: Text(
                                  style: TextStyle(
                                      color: secondaryColor,
                                      fontWeight: FontWeight.w400,
                                      fontSize: 15),
                                  formattedDate,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  style: TextStyle(
                                      color: secondaryColor,
                                      fontWeight: FontWeight.w400,
                                      fontSize: 15),
                                  transactionName,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  style: TextStyle(
                                      color: secondaryColor,
                                      fontWeight: FontWeight.w400,
                                      fontSize: 15),
                                  '$transactionType',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                          Divider(
                            color: Colors.grey,
                            thickness: 2,
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

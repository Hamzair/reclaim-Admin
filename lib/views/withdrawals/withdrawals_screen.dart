import 'package:Creek_admin_web/Data/withdrawal_request.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants.dart';

class Withdrawal_Screen extends StatefulWidget {
  Withdrawal_Screen({Key? key}) : super(key: key);

  @override
  State<Withdrawal_Screen> createState() => _Withdrawal_ScreenState();
}

class _Withdrawal_ScreenState extends State<Withdrawal_Screen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: secondaryColor,
        title: const Text('Withdrawals'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 25),
        child: Column(
          children: [
            const Padding(
              padding:
              EdgeInsets.only(left: 20.0, top: 10, bottom: 10, right: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: 50,
                  ), // Adjusted to match the CircleAvatar size in data rows
                  Expanded(
                      child: Text('User Name',
                          style: TextStyle(
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.w500,
                              fontSize: 20),
                          textAlign: TextAlign.center)),
                  Expanded(
                      child: Text('Withdrawal Requests',
                          style: TextStyle(
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.w500,
                              fontSize: 20),
                          textAlign: TextAlign.center)),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('userWithdrawals')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return SizedBox.shrink();
                  }

                  final withdrawals = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: withdrawals.length,
                    itemBuilder: (context, index) {
                      final userId = withdrawals[index].id;

                      return StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('userDetails')
                              .doc(userId)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return Center(child: CircularProgressIndicator());
                            }
                            final userDetails =
                            snapshot.data!.data() as Map<String, dynamic>;

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0, vertical: 10),
                              child: Column(
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.center,
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: [

                                      CircleAvatar(
                                        backgroundImage: NetworkImage(
                                            userDetails['userImage'] ?? ''),
                                        radius:
                                        35, // Keep consistent with the SizedBox in the header
                                      ),
                                      Expanded(
                                        child: Text(
                                            userDetails['userName'] ?? '',
                                            textAlign: TextAlign.center),
                                      ),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => WithdrawalRequest(userId: userId,
                                                ),
                                              ),
                                            );
                                          },
                                          child: Text(
                                            'See Details',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.blue,
                                              decoration:
                                              TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(
                                    color: Colors.grey,
                                    thickness: 2,
                                  ),
                                ],
                              ),
                            );
                          });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
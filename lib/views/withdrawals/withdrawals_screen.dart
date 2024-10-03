import 'package:Reclaim_admin_panel/views/withdrawals/withdrawal_request.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../const/constants.dart';

class Withdrawal_Screen extends StatefulWidget {
  Withdrawal_Screen({Key? key}) : super(key: key);

  @override
  State<Withdrawal_Screen> createState() => _Withdrawal_ScreenState();
}

class _Withdrawal_ScreenState extends State<Withdrawal_Screen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  SizedBox(width: 50), // Space for CircleAvatar
                  Expanded(
                      child: Text('User Name',
                          style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 20),
                          textAlign: TextAlign.center)),
                  Expanded(
                      child: Text('Withdrawal Requests',
                          style: TextStyle(
                              color: primaryColor,
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
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text(
                        style: TextStyle(
                            color: secondaryColor,
                            fontWeight: FontWeight.w400,
                            fontSize: 15),
                        "No withdrawal requests found."));
                  }

                  final withdrawals = snapshot.data!.docs;

                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: withdrawals.length,
                    itemBuilder: (context, index) {
                      final userId = withdrawals[index].id;

                      return StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('userDetails')
                            .doc(userId)
                            .snapshots(),
                        builder: (context, userSnapshot) {
                          if (userSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          }

                          if (!userSnapshot.hasData) {
                            return Center(
                              child: Text(
                                'No user data found for ID: $userId',
                                style: TextStyle(color: Colors.red),
                              ),
                            );
                          }

                          final userDetails = userSnapshot.data!.data()
                          as Map<String, dynamic>?;

                          if (userDetails == null) {
                            return Text("Invalid user data.");
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8.0, vertical: 10),
                            child: Column(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    CircleAvatar(
                                      backgroundImage: NetworkImage(
                                          userDetails['userImage'] ?? ''),
                                      radius: 35,
                                    ),
                                    Expanded(
                                      child: Text(
                                        userDetails['userName'] ?? '',
                                        style: TextStyle(
                                            color: secondaryColor,
                                            fontWeight: FontWeight.w400,
                                            fontSize: 15),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  WithdrawalRequest(
                                                userId: userId,
                                              ),
                                            ),
                                          );
                                        },
                                        child: Text(
                                          'See Details',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: secondaryColor,
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
                        },
                      );
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

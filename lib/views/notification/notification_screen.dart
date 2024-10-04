import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../const/constants.dart';


class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title:  Text('Notifications History')
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('adminNotification')
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print('Error: ${snapshot.error}');
            return const Center(child: Text('Something went wrong'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No notifications available', style: TextStyle(
                color: secondaryColor,
                fontWeight: FontWeight.w400,
                fontSize: 15),));
          }

          return ListView(
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Map<String, dynamic> data =
                  document.data()! as Map<String, dynamic>;
              return ListTile(
                title: Text(data['type'] == "bookVerify"
                    ? "Book Verify"
                    : "User Verify",style: TextStyle(color: Colors.white,fontWeight: FontWeight.w500,fontSize:18 ),),
                subtitle: Text(data['message'] ?? 'No Message'),
                trailing: Text(
                  (data['timestamp'] != null)
                      ? (data['timestamp'] as Timestamp).toDate().toString()
                      : 'No Timestamp',
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

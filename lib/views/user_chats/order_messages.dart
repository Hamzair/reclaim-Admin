import 'package:Reclaim_admin_panel/const/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart'; // Import intl package

class OrderUserMessages extends StatelessWidget {
  final dynamic chatsData;
  const OrderUserMessages({super.key, this.chatsData});

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
    appBar: AppBar(
      backgroundColor: primaryColor,
      title: Text("Messages",style: TextStyle(color: Colors.white),),
    ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('userMessages').doc(chatsData['orderId']).collection('messages').orderBy("timeStamp").snapshots(),
        builder: (context, snapshot) {
          if(snapshot.connectionState==ConnectionState.waiting){
            return Center(child: CircularProgressIndicator(),);
          }
          else if(snapshot.hasError || !snapshot.hasData){
            return Center(child: Text("Error while getting messages"),);
          }
          else if(snapshot.data!.docs.isEmpty){
            return Center(child: Text("No Messages"),);
          }
          dynamic messagesData = snapshot.data!.docs;
          return ListView.builder(
              shrinkWrap: true,
              itemCount: messagesData.length,
              itemBuilder: (context,index){
                final message = messagesData[index].data() as Map<String, dynamic>;
                final userId = message['userId'];
                final isSeller =  userId == chatsData['sellerId'];

                // Parse Firestore timestamp and format it
                final Timestamp timeStamp = message['timeStamp'];
                final DateTime date = timeStamp.toDate();
                final formattedDate = DateFormat('dd/MMM/yy h:mma').format(date);
                return Align(
                 alignment: isSeller ? Alignment.centerLeft : Alignment.centerRight,
                 child: Padding(
                   padding: const EdgeInsets.all(8.0),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if(isSeller)
                        UserProfileDetail(userId: userId,role: "Seller",),
                        SizedBox(width: 10,),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width / 2,
                              ),
                              padding: EdgeInsets.symmetric(horizontal: 10,vertical: 10),
                              decoration: BoxDecoration(
                                color: isSeller ? primaryColor:Colors.white,
                                border: Border.all(
                                  color: isSeller ? Colors.transparent : primaryColor
                                ),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text("${message['message']}",style: TextStyle(color: isSeller ? Colors.white:Colors.black),),
                            ),
                            Text("$formattedDate",style: TextStyle(color: Colors.black),),

                          ],
                        ),
                        SizedBox(width: 10,),
                        if(!isSeller)
                          UserProfileDetail(userId: userId,role: "Buyer",),

                      ],
                    ),

                  ],
                           ),
                         ),
               );
          });
        }
      )
    );
  }
}


class UserProfileDetail extends StatelessWidget {
  final String userId;
  final String role;
  const UserProfileDetail({super.key, required this.userId, required this.role});

  @override
  Widget build(BuildContext context) {
    return   StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('userDetails').doc(userId).snapshots(),
      builder: (context, usersnapshot) {
        if(usersnapshot.connectionState==ConnectionState.waiting){
          return Center(child: SizedBox.shrink());
        }
        else if(usersnapshot.hasError || !usersnapshot.hasData){
          return Center(child: Text("N/A"),);
        }
        else if(!usersnapshot.data!.exists){
          return Center(child: Text("N/A"),);
        }
        dynamic userData = usersnapshot.data!.data();
        return Column(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage(userData['userImage']),
            ),
            Text("${userData['userName'].toString().capitalizeFirst}\n($role)",style: TextStyle(color: Colors.black,),textAlign: TextAlign.center,),
        
          ],
        );
      }
    );
  }
}

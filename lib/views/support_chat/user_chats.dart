import 'package:Reclaim_admin_panel/const/constants.dart';
import 'package:Reclaim_admin_panel/views/support_chat/user_messages.dart';
import 'package:Reclaim_admin_panel/views/user_chats/order_messages.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class SupportUserChats extends StatefulWidget {
  const SupportUserChats({super.key});

  @override
  State<SupportUserChats> createState() => _SupportUserChatsState();
}

class _SupportUserChatsState extends State<SupportUserChats> {
  TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 20,),
            // Padding(
            //   padding: EdgeInsets.only(
            //       left: width <= 375
            //           ? 10
            //           : width <= 520
            //           ? 10 // You can specify the width for widths less than 425
            //           : width < 768
            //           ? 15 // You can specify the width for widths less than 768
            //           : width < 1024
            //           ? 15 // You can specify the width for widths less than 1024
            //           : width <= 1440
            //           ? 15
            //           : width > 1440 && width <= 2550
            //           ? 15
            //           : 15,
            //       top: 20,
            //       bottom: 20),
            //   child: SizedBox(
            //     width: width <= 375
            //         ? 200
            //         : width <= 425
            //         ? 240
            //         : width <= 520
            //         ? 260 // You can specify the width for widths less than 425
            //         : width < 768
            //         ? 370 // You can specify the width for widths less than 768
            //         : width < 1024
            //         ? 400 // You can specify the width for widths less than 1024
            //         : width <= 1440
            //         ? 500
            //         : width > 1440 && width <= 2550
            //         ? 500
            //         : 800,
            //     child: TextField(
            //       onChanged: (value) {
            //         setState(() {
            //           searchQuery = value;
            //         });
            //       },
            //       decoration: InputDecoration(
            //         hintText: "Search",
            //         fillColor: primaryColor,
            //         filled: true,
            //         border: OutlineInputBorder(
            //           borderSide: BorderSide.none,
            //           borderRadius:
            //           const BorderRadius.all(Radius.circular(10)),
            //         ),
            //         suffixIcon: Container(
            //           padding: EdgeInsets.all(defaultPadding * 0.75),
            //           margin: EdgeInsets.symmetric(
            //               horizontal: defaultPadding / 2),
            //           decoration: BoxDecoration(
            //             color: primaryColor,
            //             borderRadius:
            //             const BorderRadius.all(Radius.circular(10)),
            //           ),
            //           child: Icon(
            //             Icons.search,
            //             color: Colors.white,
            //           ),
            //         ),
            //       ),
            //     ),
            //   ),
            // ),
            SizedBox(height: 20,),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('supportChat').snapshots(),
                builder: (context, snapshot) {
                  if(snapshot.connectionState==ConnectionState.waiting){
                    return Center(child: CircularProgressIndicator(),);
                  }
                  else if(snapshot.hasError || !snapshot.hasData){
                    return Center(child: Text("Error while getting messages"),);
                  }
                  else if(snapshot.data!.docs.isEmpty){
                    return Center(child: Text("No Chats Yet"),);
                  }


                  dynamic data = snapshot.data!.docs;
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: data.length,
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    itemBuilder: (context, index) {
                      final chats = data[index].data() as Map<String, dynamic>;
                      return StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance.collection('userDetails').doc(chats['userId']).snapshots(),
                        builder: (context, userSnapshot) {
                          if(userSnapshot.connectionState==ConnectionState.waiting){
                            return SizedBox.shrink();
                          }
                          else if(userSnapshot.hasError || !userSnapshot.hasData){
                            return SizedBox.shrink();
                          }
                          else if(!userSnapshot.data!.exists){
                            return SizedBox.shrink();
                          }
                          dynamic userData = userSnapshot.data!.data();
                          return Card(
                            color: primaryColor,
                              child: ListTile(
                                onTap: () {
                                  Get.to(SupportUserMessages(chatsData: chats,));
                                },
                                  title:  Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("${userData['userName'].toString().capitalizeFirst}",style: TextStyle(color: Colors.white),),
                                  LastMessageText(userId: chats['userId'],)
                                ],
                              )
                          ));
                        }
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
class LastMessageText extends StatelessWidget {
  final String userId;
  const LastMessageText({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return   StreamBuilder<QuerySnapshot>(
      stream:  FirebaseFirestore.instance.collection('supportChat').doc(userId).collection('messages').orderBy('timestamp').snapshots(),
      builder: (context, lastmessagesnap) {
        if(lastmessagesnap.connectionState==ConnectionState.waiting){
          return SizedBox.shrink();
        }
        else if(lastmessagesnap.hasError || !lastmessagesnap.hasData){
          return SizedBox.shrink();
        }
        else if(lastmessagesnap.data!.docs!.isEmpty){
          return Text("No Message Yet",style: TextStyle(color: Colors.white),);
        }
        dynamic lastMessage = lastmessagesnap.data!.docs.first;

        final timestamp = lastMessage['timestamp'];
        // Format the timestamp to display time as "hh:mm a"
        final DateTime dateTime = timestamp.toDate();
        final String formattedTime = DateFormat('hh:mm a').format(dateTime);

        return Row(
          children: [
            Text("${lastMessage['message']}",style: TextStyle(color: Colors.white,fontSize: 13),),
            Spacer(),
            Text("$formattedTime",style: TextStyle(color: Colors.white,fontSize: 13),),
          ],
        );
      }
    );

  }
}

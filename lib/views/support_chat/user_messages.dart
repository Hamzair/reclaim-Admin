import 'package:Reclaim_admin_panel/const/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart'; // Import intl package

class SupportUserMessages extends StatefulWidget {
  final dynamic chatsData;
  const SupportUserMessages({super.key, this.chatsData});

  @override
  State<SupportUserMessages> createState() => _SupportUserMessagesState();
}

class _SupportUserMessagesState extends State<SupportUserMessages> {
  final TextEditingController messageController  = TextEditingController();
  final ScrollController scrollController  = ScrollController();
  late Stream<QuerySnapshot> messageSnap;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    messageSnap = FirebaseFirestore.instance.collection('supportChat').doc(widget.chatsData['userId']).collection('messages').orderBy("timestamp").snapshots();
  }
  Future<void> sendMessage() async {
    if (messageController.text.trim().isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('supportChat')
          .doc(widget.chatsData['userId'])
          .collection('messages')
          .add({
        "message": messageController.text.trim(),
        "timestamp": DateTime.now(),
        "userId": FirebaseAuth.instance.currentUser!.uid,
      });
      messageController.clear();

    }
  }

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextField(
onSubmitted: (val)async{
  await sendMessage();
},

       controller: messageController,
          decoration: InputDecoration(
            hintText: "Search",
            fillColor: primaryColor,
            filled: true,
            border: OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius:
              const BorderRadius.all(Radius.circular(10)),
            ),
            suffixIcon: Container(
              padding: EdgeInsets.all(defaultPadding * 0.75),
              margin: EdgeInsets.symmetric(
                  horizontal: defaultPadding / 2),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius:
                const BorderRadius.all(Radius.circular(10)),
              ),
              child: GestureDetector(
                onTap: ()async{
                  await sendMessage();
                },
                child: Icon(
                  Icons.send,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    appBar: AppBar(
      backgroundColor: primaryColor,
      title: Text("Messages",style: TextStyle(color: Colors.white),),
    ),
      body: StreamBuilder<QuerySnapshot>(
        stream: messageSnap,
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
          WidgetsBinding.instance.addPostFrameCallback((_) {
            scrollController.animateTo(
              scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOut,
            );
      });
          return ListView.builder(
            controller: scrollController,
              shrinkWrap: true,
              padding: EdgeInsets.symmetric(vertical: 20),
              itemCount: messagesData.length,
              itemBuilder: (context,index){
                final message = messagesData[index].data() as Map<String, dynamic>;
                final userId = message['userId'];
                final isAdmin =  userId == FirebaseAuth.instance.currentUser!.uid;
                // Parse Firestore timestamp and format it
                final Timestamp timeStamp = message['timestamp'];
                final DateTime date = timeStamp.toDate();
                final formattedDate = DateFormat('dd/MMM/yy h:mma').format(date);
                return Align(
                 alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
                 child: Padding(
                   padding: const EdgeInsets.all(8.0),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if(!isAdmin)
                        UserProfileDetail(userId: userId,role: "User",),
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
                                color: !isAdmin ? primaryColor:Colors.white,
                                border: Border.all(
                                  color: !isAdmin ? Colors.transparent : primaryColor
                                ),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text("${message['message']}",style: TextStyle(color: !isAdmin ? Colors.white:Colors.black),),
                            ),
                            Text("$formattedDate",style: TextStyle(color: Colors.black),),

                          ],
                        ),
                        SizedBox(width: 10,),
                        if(isAdmin)
                          UserProfileDetail(userId: userId,role: "Admin",),

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


class UserProfileDetail extends StatefulWidget {
  final String userId;
  final String role;
  const UserProfileDetail({super.key, required this.userId, required this.role});

  @override
  State<UserProfileDetail> createState() => _UserProfileDetailState();
}

class _UserProfileDetailState extends State<UserProfileDetail> {
  late Stream<DocumentSnapshot> userDoc;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    userDoc = FirebaseFirestore.instance.collection('userDetails').doc(widget.userId).snapshots();
  }
  @override
  Widget build(BuildContext context) {
    return   StreamBuilder<DocumentSnapshot>(
      stream:userDoc,
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
            Text("${userData['userName'].toString().capitalizeFirst}\n(${widget.role})",style: TextStyle(color: Colors.black,),textAlign: TextAlign.center,),

          ],
        );
      }
    );
  }
}

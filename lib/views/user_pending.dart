import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../const/constants.dart';
import '../controller/sidebarController.dart';

class UserPending extends StatefulWidget {
  UserPending({
    Key? key,
  }) : super(key: key);

  @override
  State<UserPending> createState() => _UserPendingState();
}

String searchQuery = '';

class _UserPendingState extends State<UserPending> {
  Future<void> checkForProfileUpdate(String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('pendingUserUpdates')
          .doc(userId)
          .update({"pendingApproval": true});
      // Get pending updates
      DocumentSnapshot pendingUpdates = await FirebaseFirestore.instance
          .collection('pendingUserUpdates')
          .doc(userId)
          .get();
      if (pendingUpdates.exists) {
        Map<String, dynamic> update =
            pendingUpdates.data() as Map<String, dynamic>;
        bool approval = update['pendingApproval'];
        if (approval == true) {
          await FirebaseFirestore.instance
              .collection('userDetails')
              .doc(userId)
              .update(
            {
              'userName': update['pendingUserName'],
            },
          );
          if (update.containsKey('pendingUserImage') &&
              update['pendingUserImage'] != '') {
            await FirebaseFirestore.instance
                .collection('userDetails')
                .doc(userId)
                .update(
              {
                'userImage': update['pendingUserImage'],
              },
            );
          }

          // Remove the pending updates after approval
          await FirebaseFirestore.instance
              .collection('pendingUserUpdates')
              .doc(userId)
              .delete();
        }
      }
    } catch (e) {
      print('Error Approving Profile Update $e');
    }
  }

  final SidebarController sidebarController = Get.put(SidebarController());

  void showBanConfirmationDialog1(
      BuildContext context, String userId, bool isCurrentlyVerified) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: primaryColor,
          title: Text(
              isCurrentlyVerified ? 'Approval Pending User' : 'Approved User'),
          content: Text(isCurrentlyVerified
              ? 'Do you want to Approval Pending this User?'
              : 'Are you sure you want to approve this User?'),
          actions: <Widget>[
            TextButton(
              child: Text(
                'No',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                    fontSize: 15),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                'Confirm',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                    fontSize: 15),
              ),
              onPressed: () async {
                print('update');
                await checkForProfileUpdate(userId);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 100,vertical: 20),

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
                  padding:  EdgeInsets.only(left:        width <= 375
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
                      : 15, top: 20, bottom: 20),
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
            Row(
              // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                // SizedBox(width: 65),
                Expanded(
                    child: Text(
                  'User Image',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: primaryColor),
                  textAlign: TextAlign.center,
                )),
                Expanded(
                    child: Text('User Name',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: primaryColor),
                        textAlign: TextAlign.center)),
                Expanded(
                    child: Text('Approval',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: primaryColor),
                        textAlign: TextAlign.center)),
              ],
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('pendingUserUpdates')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  } else if (snapshot.hasError ||
                      !snapshot.hasData ||
                      snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        'No Pending User found.',
                        style: TextStyle(
                            color: secondaryColor,
                            fontWeight: FontWeight.w400,
                            fontSize: 15),
                      ),
                    );
                  }

                  var pendingUser = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: pendingUser.length,
                    itemBuilder: (context, index) {
                      var userData =
                          pendingUser[index].data() as Map<String, dynamic>;

                      var userName = pendingUser[index]['pendingUserName'];
                      var userImage = userData.containsKey('pendingUserImage')
                          ? pendingUser[index]['pendingUserImage']
                          : null;
                      var userId = pendingUser[index].id;

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8.0, vertical: 5),
                        child: Column(
                          children: [
                            Row(
                              // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                // SizedBox(width: 65),
                                Expanded(
                                  child: Container(
                                    height: 120,
                                    width: 120,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      image: userImage != null
                                          ? DecorationImage(
                                              image: NetworkImage(userImage),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                    child: userImage == null
                                        ? Icon(Icons.person, size: 120)
                                        : null,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    style: TextStyle(
                                        color: secondaryColor,
                                        fontWeight: FontWeight.w400,
                                        fontSize: 15),
                                    userName,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Expanded(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(width: 40),
                                      // const SizedBox(width: 170),
                                      Text(
                                        pendingUser[index]['pendingApproval'] ??
                                                false
                                            ? 'Approved'
                                            : 'Pending',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w400,
                                          fontSize: 15,
                                          color: pendingUser[index]
                                                      ['pendingApproval'] ??
                                                  false
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        onPressed: () {
                                          showBanConfirmationDialog1(
                                            context,
                                            userId,
                                            pendingUser[index]
                                                    ['pendingApproval'] ??
                                                false,
                                          );
                                        },
                                        icon: const Icon(Icons.edit,
                                            color: primaryColor),
                                      )
                                    ],
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
      ),
    );
  }
}

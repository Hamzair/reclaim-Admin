import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../../const/constants.dart';
import '../../controller/sidebarController.dart';
import '../../widgets/custom_button.dart';

class UserData extends StatefulWidget {
  @override
  _UserDataState createState() => _UserDataState();
}

class _UserDataState extends State<UserData>
    with SingleTickerProviderStateMixin {
  final SidebarController sidebarController = Get.put(SidebarController());
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String searchQuery = '';
  late TabController _tabController;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _deleteUser(String userId) async {
    bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: primaryColor,
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this user?'),
          actions: [
            CustomButton(
              color: Colors.transparent,
              width: 100,
              height: 40,
              text: 'Cancel',
              textColor: Colors.white,
              onPressed: () => Navigator.of(context).pop(false),
            ),
            CustomButton(
              width: 100,
              height: 40,
              text: 'Delete',
              textColor: Colors.white,

              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      try {
        await _firestore.collection('userDetails').doc(userId).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User deleted successfully')),
        );
      } catch (e) {
        print('Error deleting user: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error deleting user')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  // void showBanConfirmationDialog(
  //     BuildContext context, String uid, bool isCurrentlyVerified) {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: Text(
  //             isCurrentlyVerified ? 'Unverified Account' : 'Verified Account'),
  //         content: Text(isCurrentlyVerified
  //             ? 'Do you want to unverified this account?'
  //             : 'Are you sure you want to verified this account?'),
  //         actions: <Widget>[
  //           TextButton(
  //             child: const Text('No'),
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //             },
  //           ),
  //           TextButton(
  //             child: const Text('Confirm'),
  //             onPressed: () async {
  //               await FirebaseFirestore.instance
  //                   .collection('userDetails')
  //                   .doc(uid)
  //                   .update({'verified': !isCurrentlyVerified});
  //
  //               setState(() {});
  //
  //               Navigator.of(context).pop();
  //             },
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40,vertical: 20),

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
                      hintStyle: TextStyle(color: Colors.white),

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
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // SizedBox(width: 65),
                Expanded(
                  child: Text(
                    'Image',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: primaryColor),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Name',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: primaryColor),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Email',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: primaryColor),
                    textAlign: TextAlign.center,
                  ),
                ),
                // Expanded(
                //   child: Text(
                //     'School',
                //     style: TextStyle(
                //         fontSize: 18,
                //         fontWeight: FontWeight.w500,
                //         color: Colors.blue),
                //     textAlign: TextAlign.center,
                //   ),
                // ),
                // Expanded(
                //   child: Text(
                //     'Verified',
                //     style: TextStyle(
                //         fontSize: 18,
                //         fontWeight: FontWeight.w500,
                //         color: Colors.blue),
                //     textAlign: TextAlign.center,
                //   ),
                // ),
                SizedBox(width: 40),
              ],
            ),
          ),
          Expanded(
            child: buildUserList(true),
          ),
        ],
      ),
    );
  }

  Widget buildUserList(bool isVerified) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('userDetails').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(
            color: primaryColor,

          ));
        }

        List<Map<String, dynamic>> userDetails = snapshot.data!.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();

        List<Map<String, dynamic>> filteredUserDetails = userDetails
            .where((userDetail) => ((userDetail['userName'] as String? ?? '')
                    .toLowerCase()
                    .contains(searchQuery.toLowerCase()) ||
                (userDetail['userEmail'] as String? ?? '')
                    .toLowerCase()
                    .contains(searchQuery.toLowerCase())))
            .toList();

        return ListView.builder(
          shrinkWrap: true,
          itemCount: filteredUserDetails.length,
          itemBuilder: (context, index) {
            Map<String, dynamic> userDetail = filteredUserDetails[index];
            String uid = userDetail['userId'] ?? '';
            String uname = userDetail['userName'] ?? '';

            return GestureDetector(
              onTap: () {
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //     builder: (context) => UserDetailsScreen(
                //       userId: uid,
                //       userName: uname,
                //     ),
                //   ),
                // );
              },
              child: Column(
                children: [
                  // SizedBox(
                  //   height: 10,
                  // ),
                  Row(
                    // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: userDetail['userImage'] != null
                                ? Colors.transparent
                                : Colors.red,

                          ),
                          child: userDetail['userImage'] != null
                              ? CircleAvatar(
                                  backgroundImage: NetworkImage(userDetail['userImage'])
                                )
                              : const Icon(Icons.person, color: Colors.white),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          style: TextStyle(
                              color: secondaryColor,
                              fontWeight: FontWeight.w400,
                              fontSize: 15),
                          userDetail['userName']?.isNotEmpty == true
                              ? userDetail['userName']
                              : (userDetail['userName'] ?? ''),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                          child: Text(
                              style: TextStyle(
                                  color: secondaryColor,
                                  fontWeight: FontWeight.w400,
                                  fontSize: 15),
                              userDetail['userEmail'] ?? '',
                              textAlign: TextAlign.center)),
                      // Expanded(
                      //     child: Text(userDetail['userSchool'] ?? '',
                      //         textAlign: TextAlign.center)),
                      IconButton(
                        onPressed: () {
                          _deleteUser(userDetail['userId']);
                        },
                        icon: const Icon(Icons.delete),
                        color: Colors.red,
                        iconSize: 25,
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 30,right: 10),

                    child: const Divider(
                      color: Colors.grey,
                      thickness: 2,
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }
}

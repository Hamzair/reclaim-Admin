import 'package:Reclaim_admin_panel/views/withdrawals/withdrawal_request.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../../const/constants.dart';
import '../../controller/sidebarController.dart';
import '../userpendings/user_pending.dart';

class Withdrawal_Screen extends StatefulWidget {
  Withdrawal_Screen({Key? key}) : super(key: key);

  @override
  State<Withdrawal_Screen> createState() => _Withdrawal_ScreenState();
}

class _Withdrawal_ScreenState extends State<Withdrawal_Screen> {
  final SidebarController sidebarController = Get.put(SidebarController());

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
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
                        hintStyle: TextStyle(color: Colors.white),
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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // SizedBox(width: 50), // Space for CircleAvatar
                  Expanded(
                      child: Text('Image',
                          style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 20),
                          textAlign: TextAlign.center)),
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
                    return Center(child: CircularProgressIndicator(
                      color: primaryColor,

                    ));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                        child: Text(
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
                            return Center(child: CircularProgressIndicator(
                              color: primaryColor,

                            ));
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

                          return Column(
                            children: [
                              Row(
                                // crossAxisAlignment: CrossAxisAlignment.center,
                                // mainAxisAlignment:
                                // MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: CircleAvatar(
                                      backgroundImage: NetworkImage(
                                          userDetails['userImage'] ?? ''),
                                      radius: 35,
                                    ),
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
                                          color: Colors.blue,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 30),
                                child: const Divider(
                                  color: Colors.grey,
                                  thickness: 2,
                                ),
                              ),
                            ],
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

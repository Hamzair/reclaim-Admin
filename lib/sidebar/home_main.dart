import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:sidebarx/sidebarx.dart';

import '../controller/sidebarController.dart';
import '../const/constants.dart';
import '../views/notification/notification_screen.dart';
import '../Auth/Login_Page.dart';
import '../widgets/custom_button.dart';

class ExampleSidebarX extends StatefulWidget {
  @override
  State<ExampleSidebarX> createState() => _ExampleSidebarXState();
}

class _ExampleSidebarXState extends State<ExampleSidebarX> {
  FirebaseAuth auth = FirebaseAuth.instance;

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: primaryColor,
          title: Text('Logout'),
          content: Text('Are you sure you want to logout?'),
          actions: <Widget>[
            CustomButton(
              color: Colors.transparent,
              width: 100,
              height: 40,
              text: 'No',
              textColor: Colors.white,
              onPressed: () {
                sidebarController.selectedindex.value = 0;

                Navigator.of(context).pop();
              },
            ),
            CustomButton(
              width: 100,
              height: 40,
              text: 'Yes',
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              },
            ),
          ],
        );
      },
    );
  }

  final SidebarController sidebarController = Get.put(SidebarController());

  @override
  Widget build(BuildContext context) {
    print('hellosidebarController${sidebarController.selectedindex.value}');
    // final setNameProvider=Provider.of<GetHeadingNurseName>(context,listen: false);
    return GetBuilder<SidebarController>(builder: (sidebarController) {
      return SidebarX(

        controller: sidebarController.controller,
        theme: SidebarXTheme(

          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(20),
          ),
          hoverColor: Colors.white,
          textStyle:
              TextStyle(color: primaryColor.withOpacity(0.5), fontSize: 18),
          selectedTextStyle: const TextStyle(color: primaryColor, fontSize: 18),
          hoverTextStyle: const TextStyle(
            fontSize: 18,
            color: primaryColor,
            fontWeight: FontWeight.w600,
          ),
          itemTextPadding: const EdgeInsets.only(left: 10),
          selectedItemTextPadding: const EdgeInsets.only(left: 10),
          itemDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: primaryColor),
          ),
          selectedItemDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.white,
            ),
            gradient: LinearGradient(
              colors: [Colors.white10, primaryColor.withOpacity(0.5)],
            ),
            // boxShadow: [
            //   BoxShadow(
            //     color: primaryColor,
            //     blurRadius: 30,
            //   )
            // ],
          ),
          // iconTheme: IconThemeData(
          //   color: primaryColor,
          //   size: 50,
          // ),
          selectedIconTheme: const IconThemeData(
            color: Colors.white,
            size: 10,
          ),
        ),
        extendedTheme: SidebarXTheme(
          width: 250,
          decoration: BoxDecoration(
            color: Colors.white,
          ),
        ),
        footerDivider: Divider(
          color: Colors.transparent,
        ),
        headerBuilder: (context, extended) {
          return Column(
            children: [
              SizedBox(
                height: 20,
              ),
              Obx(
                () => sidebarController.showsidebar.value == true
                    ? Align(
                        alignment: Alignment.topRight,
                        child: Icon(
                          Icons.clear_sharp,
                          color: primaryColor,
                        ))
                    : SizedBox.shrink(),
              ),
              Get.width <= 1440
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: 100,
                          width: 120,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              image: DecorationImage(
                                  image: AssetImage('assets/images/logo.png'),
                                  fit: BoxFit.fill)),
                        ),
                        SizedBox(
                          width: 5,
                        ),
                        IconButton(
                            icon: Icon(
                              Icons.notifications,
                              color: primaryColor,
                              size: 30,
                            ),
                            onPressed: () {
                              Get.to(NotificationScreen());
                            })
                      ],
                    )
                  : Get.width > 1440 && Get.width <= 2550
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              height: 100,
                              width: 120,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  image: DecorationImage(
                                      image:
                                          AssetImage('assets/images/logo.png'),
                                      fit: BoxFit.fill)),
                            ),
                            SizedBox(
                              width: 5,
                            ),
                            IconButton(
                                icon: Icon(
                                  Icons.notifications,
                                  color: primaryColor,
                                  size: 30,
                                ),
                                onPressed: () {
                                  Get.to(NotificationScreen());
                                })
                          ],
                        )
                      : SizedBox(
                          height: 80,
                          width: 220,
                          child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Image.asset('assets/images/logo.png')),
                        ),
              SizedBox(
                height: 20,
              ),
            ],
          );
        },
        items: [
          SidebarXItem(
              onTap: () {
                sidebarController.selectedindex.value = 0;
                // setNameProvider.setName('Home');
              },
              iconBuilder: (selected, hovered) {
                return Icon(
                  Icons.home,
                  color: Colors.transparent,
                );
              },
              label: 'Products Listing'),
          SidebarXItem(
              onTap: () {
                sidebarController.selectedindex.value = 1;

                // setNameProvider.setName('Diary');
              },
              iconBuilder: (selected, hovered) {
                return Icon(
                  Icons.home,
                  color: Colors.transparent,
                );
              },
              label: 'Orders'),
          SidebarXItem(
              onTap: () {
                sidebarController.selectedindex.value = 2;

                // setNameProvider.setName('Previous Bookings');
              },
              iconBuilder: (selected, hovered) {
                return Icon(
                  Icons.home,
                  color: Colors.transparent,
                );
              },
              label: 'User Data'),
          SidebarXItem(
              onTap: () {
                sidebarController.selectedindex.value = 3;

                // setNameProvider.setName('Previous Bookings');
              },
              iconBuilder: (selected, hovered) {
                return Icon(
                  Icons.home,
                  color: Colors.transparent,
                );
              },
              label: 'User Chats'),
          SidebarXItem(
              onTap: () {
                sidebarController.selectedindex.value = 4;

                // setNameProvider.setName('Profile');
              },
              iconBuilder: (selected, hovered) {
                return Icon(
                  Icons.home,
                  color: Colors.transparent,
                );
              },
              label: 'User Pendings'),
          SidebarXItem(
              onTap: () {
                sidebarController.selectedindex.value = 5;

                // setNameProvider.setName('Profile');
              },
              iconBuilder: (selected, hovered) {
                return Icon(
                  Icons.home,
                  color: Colors.transparent,
                );
              },
              label: 'Support Chat'),
          SidebarXItem(
              onTap: () {
                sidebarController.selectedindex.value = 6;

                // setNameProvider.setName('Profile');
              },
              iconBuilder: (selected, hovered) {
                return Icon(
                  Icons.home,
                  color: Colors.transparent,
                );
              },
              label: 'Admin Wallet'),
          SidebarXItem(
              onTap: () {
                sidebarController.selectedindex.value = 7;

                // setNameProvider.setName('Profile');
              },
              iconBuilder: (selected, hovered) {
                return Icon(
                  Icons.home,
                  color: Colors.transparent,
                );
              },
              label: 'Transactions'),
          SidebarXItem(
              onTap: () {
                sidebarController.selectedindex.value = 8;

                // setNameProvider.setName('Profile');
              },
              iconBuilder: (selected, hovered) {
                return Icon(
                  Icons.home,
                  color: Colors.transparent,
                );
              },
              label: 'Withdrawals'),
          SidebarXItem(
              onTap: () {
                sidebarController.selectedindex.value = 0;
                sidebarController.controller =
                    SidebarXController(selectedIndex: 0, extended: true);
                sidebarController.update();
                //
                _showLogoutDialog();
              },
              iconBuilder: (selected, hovered) {
                return Icon(
                  Icons.home,
                  color: Colors.transparent,
                );
              },
              label: 'Log out'),
        ],
      );
    });
  }
}

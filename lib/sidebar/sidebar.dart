import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../views/UserData.dart';
import '../views/order_screen.dart';
import '../views/products_listing.dart';
import '../views/user_pending.dart';
import '../views/userchats.dart';
import 'home_main.dart';
import '../controller/sidebarController.dart';

class HomeMain extends StatefulWidget {
  const HomeMain({super.key});

  @override
  State<HomeMain> createState() => _HomeMainState();
}

class _HomeMainState extends State<HomeMain> {
  final SidebarController sidebarController = Get.put(SidebarController());
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context)!.size.width;
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          if (sidebarController.showsidebar.value == true) {
            sidebarController.showsidebar.value = false;
          }
        },
        child: Stack(
          children: [
            Row(
              children: [
                width >= 768 ? ExampleSidebarX() : SizedBox.shrink(),
                Expanded(
                    child: Obx(() => sidebarController.selectedindex.value == 0
                        ? ProductsListing()
                        : sidebarController.selectedindex.value == 1
                            ? Order_Screen()
                            : sidebarController.selectedindex.value == 2
                                ? UserData()
                                : sidebarController.selectedindex.value == 3
                                    ? Userchats()
                                    : UserPending()))
              ],
            ),
            Obx(
              () => sidebarController.showsidebar.value == true
                  ? ExampleSidebarX()
                  : SizedBox.shrink(),
            )
          ],
        ),
      ),
    );
  }
}

import 'package:Reclaim_admin_panel/views/adminWallet/wallet.dart';
import 'package:Reclaim_admin_panel/views/support_chat/user_chats.dart';
import 'package:Reclaim_admin_panel/views/transaction/transaction.dart';
import 'package:Reclaim_admin_panel/views/withdrawals/withdrawals_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../views/UserData.dart';
import '../views/order_screen.dart';
import '../views/products_listing.dart';
import '../views/user_pending.dart';
import '../views/user_chats/order_chats.dart';
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
                                    ? OrderUserChats()
                                    : sidebarController.selectedindex.value == 4
                                        ? UserPending()
                                        : sidebarController
                                                    .selectedindex.value ==
                                                5
                                            ? SupportUserChats():sidebarController
                                                    .selectedindex.value ==
                                                6
                                            ? Wallet()
                                            : sidebarController
                                                        .selectedindex.value ==
                                                    7
                                                ? Transaction1():sidebarController
                                                        .selectedindex.value ==
                                                    8
                                                ? Withdrawal_Screen()
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

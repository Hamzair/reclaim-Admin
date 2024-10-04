import 'package:Reclaim_admin_panel/const/constants.dart';
import 'package:Reclaim_admin_panel/views/user_chats/order_messages.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../../controller/sidebarController.dart';

class OrderUserChats extends StatefulWidget {
  const OrderUserChats({super.key});

  @override
  State<OrderUserChats> createState() => _OrderUserChatsState();
}

class _OrderUserChatsState extends State<OrderUserChats> {
  TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  final SidebarController sidebarController = Get.put(SidebarController());

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        child: Column(
          children: [
            // SizedBox(height: 20,),
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
            // SizedBox(height: 20,),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance.collection('orders').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                        child: CircularProgressIndicator(
                      color: primaryColor,
                    ));
                  }
                  // Filter data based on searchQuery
                  dynamic data = snapshot.data!.docs.where((doc) {
                    final orderData = doc.data() as Map<String, dynamic>;
                    final orderId = orderData['orderId'].toString();
                    return searchQuery.isEmpty ||
                        orderId
                            .toLowerCase()
                            .contains(searchQuery.toLowerCase());
                  }).toList();

                  if (data.isEmpty) {
                    return const Center(
                        child: Text(
                      "No orders chat found",
                      style: TextStyle(color: Colors.black),
                    ));
                  }

                  // dynamic data = snapshot.data!.docs;
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: data.length,
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    itemBuilder: (context, index) {
                      final orderData =
                          data[index].data() as Map<String, dynamic>;
                      final productId = orderData['productId'];

                      return Card(
                          color: primaryColor,
                          child: ListTile(
                              onTap: () {
                                Get.to(OrderUserMessages(
                                  chatsData: orderData,
                                ));
                              },
                              title: FutureBuilder(
                                  future: FirebaseFirestore.instance
                                      .collection('productsListing')
                                      .doc(productId)
                                      .get(),
                                  builder: (context, productSnapshot) {
                                    if (!productSnapshot.hasData) {
                                      return const ListTile(
                                        title: Text('Loading product...'),
                                      );
                                    }

                                    final productData = productSnapshot.data!
                                        .data() as Map<String, dynamic>;
                                    final productName =
                                        productData['productName'];
                                    // final productImage = productData['productImages'];

                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: 70,
                                              height: 70,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                image: DecorationImage(
                                                  image: NetworkImage(
                                                      productData['productImages']
                                                              [0] ??
                                                          ''),
                                                  fit: BoxFit.contain,
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 5,),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "Product Name: $productName",
                                                  style: TextStyle(color: Colors.white),
                                                ),
                                                Text(
                                                  "OrderId: ${orderData['orderId']}",
                                                  style: TextStyle(color: Colors.white),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),


                                      ],
                                    );
                                  })));
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

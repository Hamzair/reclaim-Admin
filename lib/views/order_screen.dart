import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import '../const/constants.dart';
import '../controller/sidebarController.dart';

class Order_Screen extends StatefulWidget {
  const Order_Screen({super.key});

  @override
  State<Order_Screen> createState() => _Order_ScreenState();
}

FirebaseFirestore firestore = FirebaseFirestore.instance;

class _Order_ScreenState extends State<Order_Screen> {
  String searchQuery = '';

  Future<Map<String, dynamic>> getUserData(String userId) async {
    DocumentSnapshot userDoc =
        await firestore.collection('userDetails').doc(userId).get();
    if (userDoc.exists && userDoc.data() != null) {
      return userDoc.data() as Map<String, dynamic>;
    } else {
      return {}; // Return an empty map if the document does not exist
    }
  }

  final SidebarController sidebarController = Get.put(SidebarController());

  Future<Map<String, dynamic>> getBookData(String listingId) async {
    DocumentSnapshot bookDoc =
        await firestore.collection('productsListing').doc(listingId).get();
    if (bookDoc.exists && bookDoc.data() != null) {
      return bookDoc.data() as Map<String, dynamic>;
    } else {
      return {}; // Return an empty map if the document does not exist
    }
  }

  Future<Map<String, dynamic>> getOrderDetails(
      Map<String, dynamic> order) async {
    String buyerId = order['buyerId'];
    String sellerId = order['sellerId'];
    String productId = order['productId'];

    Map<String, dynamic> buyerData = await getUserData(buyerId);
    Map<String, dynamic> sellerData = await getUserData(sellerId);
    Map<String, dynamic> bookData = await getBookData(productId);

    return {
      'productName': bookData['productName'] ?? 'Unknown',
      'productImages': bookData['productImages'] ?? [],
      'buyerName': buyerData['userName'] ?? 'Unknown',
      'sellerName': sellerData['userName'] ?? 'Unknown',
      'orderDate': order['orderDate'],
      'buyingprice': order['buyingprice'],
      // 'deliveryStatus': order['deliveryStatus']
    };
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        // appBar: AppBar(
        //   toolbarHeight: 8,
        //   automaticallyImplyLeading: false,
        //   backgroundColor: secondaryColor,
        //   bottom: const TabBar(
        //     labelColor: Colors.blue,
        //     tabs: [
        //       Tab(text: 'Order Complete'),
        //       Tab(text: 'Pending Order'),
        //     ],
        //   ),
        // ),
        body: Padding(
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
                    padding:  EdgeInsets.only(      left: width <= 375
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
                          ? 240:
                      width <= 520
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
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),

                child: Row(
                  // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                        child: Text(
                            overflow:  width <= 520?TextOverflow.ellipsis:TextOverflow.visible,
                            maxLines: width <= 520?1:2,
                            'Image',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: primaryColor),
                            textAlign: TextAlign.center)),
                    Expanded(
                        child: Text(
                            overflow:  width <= 520?TextOverflow.ellipsis:TextOverflow.visible,
                            maxLines: width <= 520?1:2,
                            'Title',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: primaryColor),
                            textAlign: TextAlign.center)),
                    Expanded(
                        child: Text(
                            overflow:  width <= 520?TextOverflow.ellipsis:TextOverflow.visible,
                            maxLines: width <= 520?1:2,
                            'Buyer',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: primaryColor),
                            textAlign: TextAlign.center)),
                    Expanded(
                        child: Text(
                            overflow:  width <= 520?TextOverflow.ellipsis:TextOverflow.visible,
                            maxLines: width <= 520?1:2,
                            'Seller',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: primaryColor),
                            textAlign: TextAlign.center)),
                    Expanded(
                        child: Text(
                            overflow:  width <= 520?TextOverflow.ellipsis:TextOverflow.visible,
                            maxLines: width <= 520?1:2,
                            'Date',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: primaryColor),
                            textAlign: TextAlign.center)),
                    Expanded(
                        child: Text(
                            overflow:  width <= 520?TextOverflow.ellipsis:TextOverflow.visible,
                            maxLines: width <= 520?1:2,
                            'Price',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: primaryColor),
                            textAlign: TextAlign.center)),
                    // Expanded(
                    //     child: Text('Delivery Status',
                    //         style: TextStyle(
                    //             fontSize: 18,
                    //             fontWeight: FontWeight.w500,
                    //             color: Colors.blue),
                    //         textAlign: TextAlign.center)),
                  ],
                ),
              ),
              Expanded(
                child: _buildOrderList(true),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderList(bool isComplete) {
    final width = MediaQuery.of(context).size.width;

    return StreamBuilder<QuerySnapshot>(
      stream: firestore.collection('orders').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('No orders found'),
          );
        } else {
          List<DocumentSnapshot> documents = snapshot.data!.docs;
          List<Map<String, dynamic>> listedOrders = documents.map((document) {
            return document.data() as Map<String, dynamic>;
          }).toList();

          return FutureBuilder(
            future: Future.wait(
                listedOrders.map((order) => getOrderDetails(order))),
            builder:
                (context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text('No orders found'),
                );
              } else {
                List<Map<String, dynamic>> filteredOrders =
                    snapshot.data!.where((order) {
                  String buyerName = order['buyerName'] ?? '';
                  String sellerName = order['sellerName'] ?? '';
                  String productName = order['productName'] ?? '';
                  // bool deliveryStatus = order['deliveryStatus'];

                  return (buyerName
                          .toLowerCase()
                          .contains(searchQuery.toLowerCase()) ||
                      sellerName
                          .toLowerCase()
                          .contains(searchQuery.toLowerCase()) ||
                      productName
                          .toLowerCase()
                          .contains(searchQuery.toLowerCase()));
                }).toList();

                if (filteredOrders.isEmpty) {
                  return const Center(
                    child: Text('No orders found'),
                  );
                }

                return ListView.builder(
                  itemCount: filteredOrders.length,
                  itemBuilder: (context, index) {
                    var order = filteredOrders[index];
                    return Column(
                      children: [
                        Row(
                          // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  image: DecorationImage(
                                    image: NetworkImage(
                                        order['productImages'][0] ?? ''),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            // const SizedBox(width: 30),
                            Expanded(
                              child: Text(
                                  style: TextStyle(
                                      color: secondaryColor,
                                      fontWeight: FontWeight.w400,
                                      fontSize: 15),
                                  order['productName'] ?? 'Loading',
                                  textAlign: TextAlign.center),
                            ),
                            Expanded(
                              child: Text(
                                  style: TextStyle(
                                      color: secondaryColor,
                                      fontWeight: FontWeight.w400,
                                      fontSize: 15),
                                  order['buyerName'],
                                  textAlign: TextAlign.center),
                            ),
                            Expanded(
                              child: Text(
                                  style: TextStyle(
                                      color: secondaryColor,
                                      fontWeight: FontWeight.w400,
                                      fontSize: 15),
                                  order['sellerName'],
                                  textAlign: TextAlign.center),
                            ),
                            Expanded(
                              child: Text(
                                  overflow:  width <= 520?TextOverflow.ellipsis:TextOverflow.visible,
                                  maxLines: width <= 520?1:2,
                                  style: TextStyle(
                                      color: secondaryColor,
                                      fontWeight: FontWeight.w400,
                                      fontSize: 15),
                                  order['orderDate'].toDate().toString(),
                                  textAlign: TextAlign.center),
                            ),
                            Expanded(
                              child: Text(
                                  style: TextStyle(
                                      color: secondaryColor,
                                      fontWeight: FontWeight.w400,
                                      fontSize: 15),
                                  order['buyingprice'].toString(),
                                  textAlign: TextAlign.center),
                            ),
                            // Expanded(
                            //   child: Text(order['deliveryStatus'].toString(),
                            //       textAlign: TextAlign.center),
                            // ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30),

                          child: const Divider(color: Colors.grey, thickness: 2),
                        ),
                      ],
                    );
                  },
                );
              }
            },
          );
        }
      },
    );
  }
}

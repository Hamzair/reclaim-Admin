import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import '../const/constants.dart';
import '../controller/sidebarController.dart';

class ProductsListing extends StatefulWidget {
  const ProductsListing({super.key});

  @override
  State<ProductsListing> createState() => _ProductsListingState();
}

String searchQuery = '';

final FirebaseFirestore fireStore = FirebaseFirestore.instance;

String _formatTimestamp(Timestamp? timestamp) {
  if (timestamp != null) {
    DateTime dateTime = timestamp.toDate();
    return "${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}";
  } else {
    return 'N/A';
  }
}

// void showBanConfirmationDialog(
//     BuildContext context, String uid, bool isCurrentlyVerified) {
//   showDialog(
//     context: context,
//     builder: (BuildContext context) {
//       return AlertDialog(
//         title: Text(
//             isCurrentlyVerified ? 'Approval Pending Book' : 'Approved Book'),
//         content: Text(isCurrentlyVerified
//             ? 'Do you want to Approval Pending this book?'
//             : 'Are you sure you want to approve this book?'),
//         actions: <Widget>[
//           TextButton(
//             child: Text('No'),
//             onPressed: () {
//               Navigator.of(context).pop();
//             },
//           ),
//           TextButton(
//             child: Text('Confirm'),
//             onPressed: () async {
//               await FirebaseFirestore.instance
//                   .collection('booksListing')
//                   .doc(uid)
//                   .update({'approval': !isCurrentlyVerified});
//               Navigator.of(context).pop();
//             },
//           ),
//         ],
//       );
//     },
//   );
// }

// void showBookDetailDialog(BuildContext context, Map<String, dynamic> bookData) {
//   showDialog(
//     context: context,
//     builder: (BuildContext context) {
//       return AlertDialog(
//         backgroundColor: secondaryColor,
//         title: Text(bookData['bookName'] ?? 'No Title'),
//         content: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Container(
//                 height: 200,
//                 decoration: BoxDecoration(
//                   image: DecorationImage(
//                     image: NetworkImage(bookData['bookImage'] ?? ''),
//                     fit: BoxFit.cover,
//                   ),
//                 ),
//               ),
//               SizedBox(height: 20),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text('Author:', style: TextStyle(fontWeight: FontWeight.bold,color: primaryColor)),
//                   Text('${bookData['bookAuthor'] ?? 'N/A'}'),
//                 ],
//               ),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text('Subtitle:', style: TextStyle(fontWeight: FontWeight.bold,color: primaryColor)),
//                   Text('${bookData['bookSubtitle'] ?? 'N/A'}'),
//                 ],
//               ),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text('Condition:', style: TextStyle(fontWeight: FontWeight.bold,color: primaryColor)),
//                   Text('${bookData['bookCondition'] ?? 'N/A'}'),
//                 ],
//               ),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text('Price:', style: TextStyle(fontWeight: FontWeight.bold,color: primaryColor)),
//                   Text('\$${bookData['bookPrice'] ?? 'N/A'}'),
//                 ],
//               ),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text('Posted on:', style: TextStyle(fontWeight: FontWeight.bold,color: primaryColor)),
//                   Text('${_formatTimestamp(bookData['bookPosted'])}'),
//                 ],
//               ),
//               SizedBox(height: 20),
//               Text('Description:', style: TextStyle(fontWeight: FontWeight.bold,color: primaryColor)),
//               SizedBox(
//                   width: 500,
//                   child: Text(
//                       // maxLines: 5,
//                       bookData['bookDescription'] ?? 'No Description')),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             child: Text('Close', style: TextStyle(fontWeight: FontWeight.bold,color: Colors.red)),
//             onPressed: () {
//               Navigator.of(context).pop();
//             },
//           ),
//         ],
//       );
//     },
//   );
// }

Future<List<Map<String, dynamic>>> fetchUserBookListing() async {
  try {
    List<Map<String, dynamic>> listings = [];
    QuerySnapshot listingsData =
        await fireStore.collection('productsListing').get();
    if (listingsData.docs.isNotEmpty) {
      for (var book in listingsData.docs) {
        dynamic bookData = book.data();
        // var myBook = {
        //   'bookImage': bookData['bookImage'],
        //   'bookName': bookData['bookName'],
        //   'bookSubtitle': bookData['bookSubtitle'],
        //   'bookAuthor': bookData['bookAuthor'],
        //   'bookCondition': bookData['bookCondition'],
        //   'bookPrice': bookData['bookPrice'],
        //   'bookPosted': bookData['bookPosted'],
        //   'sellerId': bookData['sellerId'],
        //   'bookDescription': bookData['bookDescription'],
        //   'approval': bookData['approval'],
        //   'listingId': book.id,
        // };
        listings.add(bookData);
      }
    } else {
      print("No user listings found");
    }
    return listings;
  } catch (e) {
    print("Error fetching user listings $e");
    return [];
  }
}

class _ProductsListingState extends State<ProductsListing>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BookListView(approvalStatus: true);
  }
}

class BookListView extends StatefulWidget {
  final bool approvalStatus;

  const BookListView({required this.approvalStatus});

  @override
  _BookListViewState createState() => _BookListViewState();
}

class _BookListViewState extends State<BookListView> {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final SidebarController sidebarController = Get.put(SidebarController());

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 100,vertical: 20),
      child: Column(
        // crossAxisAlignment: CrossAxisAlignment.start,
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
                        child: Icon(
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
              children: [
                Expanded(
                  child: Text(
                    overflow: width <= 520
                        ? TextOverflow.ellipsis
                        : TextOverflow.visible,
                    maxLines: width <= 520 ? 1 : 2,
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
                    overflow: width <= 520
                        ? TextOverflow.ellipsis
                        : TextOverflow.visible,
                    maxLines: width <= 520 ? 1 : 2,
                    'Title',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: primaryColor),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                      overflow: width <= 520
                          ? TextOverflow.ellipsis
                          : TextOverflow.visible,
                      maxLines: width <= 520 ? 1 : 2,
                      'Brand',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: primaryColor),
                      textAlign: TextAlign.center),
                ),
                Expanded(
                  child: Text(
                      overflow: width <= 520
                          ? TextOverflow.ellipsis
                          : TextOverflow.visible,
                      maxLines: width <= 520 ? 1 : 2,
                      'Date',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: primaryColor),
                      textAlign: TextAlign.center),
                ),
                Expanded(
                  child: Text(
                      overflow: width <= 520
                          ? TextOverflow.ellipsis
                          : TextOverflow.visible,
                      maxLines: width <= 520 ? 1 : 2,
                      'Price',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: primaryColor),
                      textAlign: TextAlign.center),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: fireStore.collection('productsListing').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text('Error Loading Data'),
                  );
                } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text('No Listings Found'),
                  );
                } else {
                  List<Map<String, dynamic>> listings =
                      snapshot.data!.docs.map((doc) {
                    return {
                      'productImages': doc['productImages'],
                      'productName': doc['productName'],
                      'category': doc['category'],
                      'brand': doc['brand'],
                      'productCondition': doc['productCondition'],
                      'productPrice': doc['productPrice'],
                      'postedDate': doc['postedDate'],
                      'sellerId': doc['sellerId'],
                      'Description': doc['Description'],
                      'approval': doc['approval'],
                      'size': doc['size'],
                      'listingId': doc.id,
                    };
                  }).toList();

                  // Apply search query filter
                  List<Map<String, dynamic>> filteredListings =
                      listings.where((listing) {
                    String productName = listing['productName'] ?? '';

                    return productName
                        .toLowerCase()
                        .contains(searchQuery.toLowerCase());
                  }).toList();

                  return ListView.builder(
                    physics: ClampingScrollPhysics(),
                    itemCount: filteredListings.length,
                    itemBuilder: (context, index) {
                      var bookData = filteredListings[index];
                      Timestamp timestamp = bookData['postedDate'];
                      String uid = bookData['listingId'];
                      bool approval = bookData['approval'] ?? false;

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8.0, vertical: 5),
                        child: GestureDetector(
                          onTap: () {
                            // showBookDetailDialog(context, bookData);
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      width: 70,
                                      height: 70,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        image: DecorationImage(
                                          image: NetworkImage(
                                              bookData['productImages'][0] ??
                                                  ''),
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                      child: Text(
                                          style: TextStyle(
                                              color: secondaryColor,
                                              fontWeight: FontWeight.w400,
                                              fontSize: 15),
                                          bookData['productName'] ?? 'N/A',
                                          textAlign: TextAlign.center)),
                                  Expanded(
                                      child: Text(
                                          style: TextStyle(
                                              color: secondaryColor,
                                              fontWeight: FontWeight.w400,
                                              fontSize: 15),
                                          bookData['brand'] ?? 'N/A',
                                          textAlign: TextAlign.center)),
                                  Expanded(
                                      child: Text(
                                          overflow: width <= 520
                                              ? TextOverflow.ellipsis
                                              : TextOverflow.visible,
                                          maxLines: 1,
                                          style: TextStyle(
                                              color: secondaryColor,
                                              fontWeight: FontWeight.w400,
                                              fontSize: 15),
                                          _formatTimestamp(timestamp),
                                          textAlign: TextAlign.center)),
                                  Expanded(
                                      child: Text(
                                          style: TextStyle(
                                              color: secondaryColor,
                                              fontWeight: FontWeight.w400,
                                              fontSize: 15),
                                          "\$${bookData['productPrice'] ?? 'N/A'}",
                                          textAlign: TextAlign.center)),
                                  // Expanded(
                                  //   child: Row(
                                  //     children: [
                                  //       SizedBox(width: 50),
                                  //       Text(
                                  //         approval
                                  //             ? 'Approved'
                                  //             : 'Approval\npending',
                                  //         style: TextStyle(
                                  //             color: approval
                                  //                 ? Colors.green
                                  //                 : Colors.red),
                                  //       ),
                                  //       SizedBox(width: 5),
                                  //       IconButton(
                                  //         onPressed: () {
                                  //           // showBanConfirmationDialog(
                                  //           //     context, uid, approval);
                                  //         },
                                  //         icon: Icon(Icons.edit,
                                  //             color: Colors.white),
                                  //       ),
                                  //     ],
                                  //   ),
                                  // ),
                                ],
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 50),
                                child: Divider(
                                  color: Colors.grey,
                                  thickness: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

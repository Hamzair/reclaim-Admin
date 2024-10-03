import 'package:Reclaim_admin_panel/views/adminWallet/wallet_details.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../../const/constants.dart';
import '../../controller/sidebarController.dart';

final FirebaseFirestore fireStore = FirebaseFirestore.instance;

class Wallet extends StatefulWidget {
  const Wallet({Key? key}) : super(key: key);

  @override
  _WalletState createState() => _WalletState();
}

class _WalletState extends State<Wallet> {
  final SidebarController sidebarController = Get.put(SidebarController());

  late Stream<QuerySnapshot> walletStream;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Initialize the stream to listen for changes in the entire 'adminWallet' collection
    walletStream = fireStore.collection('adminWallet').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
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
                children: const [
                  // SizedBox(width: 65),
                  Expanded(
                      child: Text(
                    'Role',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: primaryColor),
                    textAlign: TextAlign.center,
                  )),
                  Expanded(
                      child: Text('Balance',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: primaryColor),
                          textAlign: TextAlign.center)),
                  Expanded(
                      child: Text('Transactions',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: primaryColor),
                          textAlign: TextAlign.center)),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: walletStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  // Extract the list of documents from the snapshot
                  List<DocumentSnapshot> documents = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: documents.length,
                    itemBuilder: (context, index) {
                      var document = documents[index];
                      var balance = document['balance'];
                      var documentId = document.id;

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
                                  child: Text(
                                    style: TextStyle(
                                        color: secondaryColor,
                                        fontWeight: FontWeight.w400,
                                        fontSize: 15),
                                    'Admin',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    style: TextStyle(
                                        color: secondaryColor,
                                        fontWeight: FontWeight.w400,
                                        fontSize: 15),
                                    '${balance ?? 'N/A'} Aed',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => WalletDetail(
                                              walletId: documentId),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'View Details',
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
                                  const EdgeInsets.symmetric(horizontal: 50),
                              child: Divider(
                                color: Colors.grey,
                                thickness: 2,
                              ),
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

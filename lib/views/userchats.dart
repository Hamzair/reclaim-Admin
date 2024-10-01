import 'package:Reclaim_admin_panel/const/constants.dart';
import 'package:Reclaim_admin_panel/views/userChats_details.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Userchats extends StatelessWidget {
  const Userchats({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('orders').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            dynamic data = snapshot.data!.docs;
            return ListView.builder(
              shrinkWrap: true,
              itemCount: data.length,
              itemBuilder: (context, index) {
                final orderData = data[index].data() as Map<String, dynamic>;
                final productId = orderData['productId'];

                return Card(
                    color: primaryColor,
                    child: ListTile(
                      onTap: () {
                        Get.to(UserchatsDetails());
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

                              final productData = productSnapshot.data!.data()
                                  as Map<String, dynamic>;
                              final productName = productData['productName'];

                              return Text("Product Name: $productName");
                            })));
              },
            );
          },
        ),
      ),
    );
  }
}

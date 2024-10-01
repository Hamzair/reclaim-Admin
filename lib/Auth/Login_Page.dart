import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../sidebar/sidebar.dart';
import '../const/constants.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController passwordController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  bool isPasswordVisible = false;
  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  final UserController userController = Get.put(UserController());

  void login() async {
    try {
      userController.isLoading.value = true;
      // Sign in with email and password

      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      String? uid = userCredential.user?.uid;
      print("Admin UID: $uid");

      // Fetch the ID token result to get the custom claims
      IdTokenResult idTokenResult =
          await userCredential.user!.getIdTokenResult();

      // Check if the user has the admin claim
      bool isAdmin = idTokenResult.claims?['admin'] == true;
      if (isAdmin) {
        print("Admin logged in: $uid");

        userController.setUid(uid!);
        Get.snackbar("Success", "Login",backgroundColor: Colors.black,colorText: Colors.white);
        // Update the controller with the UID
        Get.offAll(() => HomeMain()); // Navigate to MainDashboard
      } else {
        await FirebaseAuth.instance.signOut();

        print("User is not an admin");
        Get.snackbar("Access Denied", "You do not have admin privileges.",backgroundColor: Colors.black,colorText: Colors.white);
      }
      userController.isLoading.value = false;
    } catch (e) {
      print("Login Error: $e"); // Print the error to the terminal
      Get.snackbar("Login Error", e.toString(),backgroundColor: Colors.black,colorText: Colors.white);
      userController.isLoading.value = false;
    }
  }

  // @override
  // void initState() {
  //   super.initState();
  //
  //   if (!kIsWeb) {
  //     // Only subscribe to the topic if not on a web platform
  //     FirebaseMessaging.instance.subscribeToTopic('all');
  //   }
  //
  //   loadFCM();
  //   listenFCM();
  // }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
        body: Padding(
      padding: const EdgeInsets.all(22.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          width <= 1440
              ? Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      image: DecorationImage(
                          fit: BoxFit.contain,
                          image: AssetImage(
                            'assets/images/logo.png',
                          ))),
                )
              : width > 1440 && width <= 2550
                  ? Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          image: DecorationImage(
                              fit: BoxFit.contain,
                              image: AssetImage(
                                'assets/images/logo.png',
                              ))),
                    )
                  : Container(
                      width: 170,
                      height: 170,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          image: DecorationImage(
                              fit: BoxFit.contain,
                              image: AssetImage(
                                'assets/images/logo.png',
                              ))),
                    ),
          SizedBox(
            height: 50,
          ),
          Text(
            'Login',
            style: TextStyle(
                fontSize: 26, color: primaryColor, fontWeight: FontWeight.bold),
          ),
          SizedBox(
            height: 20,
          ),
          Container(
            width: width < 425
                ? 280 // You can specify the width for widths less than 425
                : width < 768
                    ? 300 // You can specify the width for widths less than 768
                    : width <= 1440
                        ? 400
                        : width > 1440 && width <= 2550
                            ? 400
                            : 700,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: Colors.grey,
                width: 1.0,
              ),
            ),
            child: TextField(
              style: TextStyle(color: Colors.black),
              controller: emailController,
              decoration: InputDecoration(
                contentPadding: EdgeInsets.all(14.0),
                prefixIcon: Icon(
                  Icons.mail_outline,
                  color: primaryColor,
                ),
                hintText: 'Enter email',
                border: InputBorder.none, // Remove the default underline border
              ),
            ),
          ),
          SizedBox(
            height: 15,
          ),
          Align(
            alignment: Alignment.center,
            child: Container(
              width: width < 425
                  ? 280 // You can specify the width for widths less than 425
                  : width < 768
                      ? 300 // You can specify the width for widths less than 768
                      : width <= 1440
                          ? 400
                          : width > 1440 && width <= 2550
                              ? 400
                              : 700,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                  color: Colors.grey,
                  width: 1.0,
                ),
              ),
              child: TextField(
                style: TextStyle(color: Colors.black),
                controller: passwordController,
                obscureText: !isPasswordVisible,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.all(14.0),
                  prefixIcon: Icon(Icons.lock, color: primaryColor),
                  suffixIcon: IconButton(
                    icon: Icon(
                        isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: primaryColor),
                    onPressed: () {
                      setState(() {
                        isPasswordVisible = !isPasswordVisible;
                      });
                    },
                  ),
                  hintText: 'Password',
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 5,
          ),
          SizedBox(
            height: 30,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Login',
                style: TextStyle(
                    fontSize: 20,
                    color: primaryColor,
                    fontWeight: FontWeight.bold),
              ),
              SizedBox(
                width: width < 425
                    ? 170 // You can specify the width for widths less than 425
                    : width < 768
                        ? 190 // You can specify the width for widths less than 768
                        : width <= 1440
                            ? 300
                            : width > 1440 && width <= 2550
                                ? 300
                                : 700,
              ),
              Obx(() {
                return Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primaryColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                  child: userController.isLoading.value == true
                      ? Center(
                          child: CircularProgressIndicator(
                          color: Colors.white,
                        ))
                      : IconButton(
                          color: Colors.white,
                          onPressed: login,
                          icon: Transform.scale(
                            scale: 0.5,
                            child: Image.asset('assets/images/forward.png'),
                          ),
                        ),
                );
              }),
            ],
          ),
          SizedBox(
            height: 60,
          ),
        ],
      ),
    ));
  }
}

class UserController extends GetxController {
  var uid = ''.obs; // Observable
  RxBool isLoading = false.obs;

  void setUid(String uid) {
    this.uid.value = uid; // Update the observable value
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
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

  @override
  void initState() {
    super.initState();
    // Keep fields empty — admin must enter credentials manually.
  }

  void login() async {
    debugPrint("--- LOGIN ATTEMPT ---");
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    if (email.isEmpty) {
      rootScaffoldMessengerKey.currentState?.showSnackBar(const SnackBar(
          content: Text("Please enter your email"),
          backgroundColor: Colors.black));
      return;
    }
    if (!GetUtils.isEmail(email)) {
      rootScaffoldMessengerKey.currentState?.showSnackBar(const SnackBar(
          content: Text("Please enter a valid email"),
          backgroundColor: Colors.black));
      return;
    }
    if (password.isEmpty) {
      rootScaffoldMessengerKey.currentState?.showSnackBar(const SnackBar(
          content: Text("Please enter your password"),
          backgroundColor: Colors.black));
      return;
    }

    try {
      userController.isLoading.value = true;

      // Primary check: Search in Firestore 'admin' collection for matching credentials
      final QuerySnapshot adminQuery = await FirebaseFirestore.instance
          .collection('admin')
          .where('email', isEqualTo: email)
          .where('password', isEqualTo: password)
          .get();

      if (adminQuery.docs.isNotEmpty) {
        debugPrint("Admin credentials verified in Firestore.");

        // Attempt Firebase Auth sign-in in the background so Firebase rules/Storage still work
        try {
          await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
        } catch (authError) {
          debugPrint("Background Auth sign-in error (ignoring): $authError");
        }

        String uid = adminQuery.docs.first.id;
        userController.setUid(uid);

        rootScaffoldMessengerKey.currentState?.showSnackBar(const SnackBar(
            content: Text("Login Successful"), backgroundColor: Colors.black));

        Get.offAllNamed('/home');
      } else {
        debugPrint("No matching admin credentials found in Firestore.");
        rootScaffoldMessengerKey.currentState?.showSnackBar(const SnackBar(
            content: Text("Invalid email or password. Access Denied."),
            backgroundColor: Colors.black));
      }
    } catch (e) {
      debugPrint("Login Error: $e");
      rootScaffoldMessengerKey.currentState?.showSnackBar(const SnackBar(
          content: Text("Error connecting to database. Please try again."),
          backgroundColor: Colors.black));
    } finally {
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
                        color: Colors.grey.withValues(alpha: 0.3),
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

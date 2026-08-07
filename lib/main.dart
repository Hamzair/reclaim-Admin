import 'package:reclaim_admin_panel/sidebar/sidebar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'Auth/Login_Page.dart'; // LoginPage + UserController
import 'const/constants.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Avoid GetX restoring a broken route stack after hot restart on web.
  Get.reset();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Widget _initialScreen() {
    if (FirebaseAuth.instance.currentUser == null) {
      return const LoginPage();
    }
    return const HomeMain();
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Reclaim Admin',
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: bgColor,
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme)
            .apply(bodyColor: Colors.white),
        canvasColor: secondaryColor,
      ),
      // Use ONLY named routes — mixing `home` + `getPages` causes
      // "Unexpected null value" on hot restart (GetX route_middleware).
      initialRoute: '/',
      getPages: [
        GetPage(
          name: '/',
          page: () => _initialScreen(),
        ),
        GetPage(
          name: '/login',
          page: () => const LoginPage(),
        ),
        GetPage(
          name: '/home',
          page: () => const HomeMain(),
        ),
      ],
      unknownRoute: GetPage(
        name: '/not-found',
        page: () => const LoginPage(),
      ),
      initialBinding: BindingsBuilder(() {
        if (!Get.isRegistered<UserController>()) {
          Get.put(UserController());
        }
      }),
    );
  }
}

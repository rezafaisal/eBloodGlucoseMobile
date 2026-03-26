import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:get/get.dart';

import '../controller/login_page_controller.dart';
import 'main_page.dart';

class LoginPage extends GetView<LoginPageController> {
  const LoginPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        primaryColor: Colors.teal,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          primary: Colors.teal,
          secondary: Colors.tealAccent,
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: Colors.teal,
          circularTrackColor: Colors.white24,
        ),
      ),
      child: FlutterLogin(
        logo: const AssetImage('assets/logo.png'),
        onLogin: controller.onLogin,
        hideForgotPasswordButton: true,
        onSubmitAnimationCompleted: () {
          Get.to(() => const MainPage());
        },
        onRecoverPassword: (_) => Future.value(null),
        theme: LoginTheme(
          primaryColor: Colors.teal,
          accentColor: Colors.tealAccent,
          errorColor: Colors.red,
          pageColorLight: Colors.teal[300],
          pageColorDark: Colors.teal[700],
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          bodyStyle: const TextStyle(
            color: Colors.white,
          ),
          buttonTheme: LoginButtonTheme(
            backgroundColor: Colors.teal,
            highlightColor: Colors.teal[700],
          ),
          cardTheme: CardTheme(
            color: Colors.white,
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          inputTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.teal, width: 2),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
            ),
          ),
        ),
        userValidator: (value) {
          if (value == null || value.isEmpty) {
            return 'Email tidak boleh kosong';
          }
          return null;
        },
        passwordValidator: (value) {
          if (value == null || value.isEmpty) {
            return 'Password tidak boleh kosong';
          }
          return null;
        },
      ),
    );
  }
}

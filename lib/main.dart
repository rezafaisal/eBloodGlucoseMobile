import 'dart:io';

import 'package:e_fever_care/binding/main_bindings.dart';
import 'package:e_fever_care/view/history/history_page.dart';
import 'package:e_fever_care/view/home_page.dart';
import 'package:e_fever_care/view/main_page.dart';
import 'package:e_fever_care/view/profile_page.dart';
import 'package:e_fever_care/view/settings_page.dart';
import 'package:e_fever_care/view/splash_screen.dart';
import 'package:e_fever_care/view/weight_data_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize date formatting for Indonesian locale
  await initializeDateFormatting('id_ID', null);
  
  await Hive.initFlutter();
  // await Hive.openBox('temperatureData');
  await Hive.openBox('glucoseData');
  await Hive.openBox('weightData'); // Add weight data box
  await Hive.openBox('deviceData');
  await Hive.openBox('user');
  await Hive.openBox('userProfile'); // Add user profile box
  await Hive.openBox('token');

  if (Platform.isAndroid) {
    [
      Permission.location,
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan
    ].request().then((status) {
      runApp(const MyApp());
    });
  } else {
    runApp(const MyApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ResponsiveSizer(
        builder: (context, orientation, screenType) {
          return GetMaterialApp(
            // title: 'e Fever Care',
            title: 'Monitor Gula Darah',
            theme: ThemeData(
                primarySwatch: Colors.teal,
                scaffoldBackgroundColor: Colors.white,
                fontFamily: 'Noto Sans'),
            initialRoute: '/',
            initialBinding: MainBindings(),
            debugShowCheckedModeBanner: false,
            getPages: [
              GetPage(name: '/', page: () => const Splash()),
              GetPage(name: '/main', page: () => const MainPage()),
              GetPage(name: '/home', page: () => const HomePage()),
              GetPage(name: '/history', page: () => const HistoryPage()),
              GetPage(name: '/profile', page: () => const ProfilePage()),
              GetPage(name: '/setting', page: () => const SettingsPage()),
              GetPage(name: '/weight-data', page: () => const WeightDataPage()),
            ],
          );
        }
    );
  }
}

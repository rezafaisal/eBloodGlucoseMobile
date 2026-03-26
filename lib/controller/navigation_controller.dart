import 'package:e_fever_care/controller/history_page_controller.dart';
import 'package:e_fever_care/view/history/history_page.dart';
import 'package:e_fever_care/view/home_page.dart';
import 'package:e_fever_care/view/profile_page.dart';
import 'package:e_fever_care/view/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';

import '../service/utils_service.dart';

class NavigationController extends GetxController {
  final UtilService utilService = UtilService();
  var selectedIndex = 0.obs;

  final iconList = <IconData>[
    Icons.home_rounded,
    Icons.bar_chart_rounded,
    Icons.person_rounded,
    Icons.settings_rounded,
  ];

  final List<Widget> pages = [
    const HomePage(),
    const HistoryPage(),
    const ProfilePage(),
    const SettingsPage()
  ];

  final List<String> pageList = [
    'home',
    'history',
    'profile',
    'setting',
  ];

  List<BluetoothDevice> connectedDevices = [];

  void changePage(int index) {
    selectedIndex.value = index;
    if (index == 1) {
      // When switching to history page, trigger refresh instead of forcing yesterday's data
      HistoryPageController historyController = Get.find();
      historyController.markForRefresh();
    }
  }
}

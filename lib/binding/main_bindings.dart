import 'package:e_fever_care/controller/home_page_controller.dart';
import 'package:e_fever_care/controller/navigation_controller.dart';
import 'package:e_fever_care/controller/manual_data_controller.dart';
import 'package:e_fever_care/controller/profile_controller.dart';
import 'package:e_fever_care/controller/weight_controller.dart';
import 'package:e_fever_care/service/utils_service.dart';
import 'package:get/get.dart';

import '../controller/connect_page_controller.dart';
import '../controller/history_page_controller.dart';
import '../controller/login_page_controller.dart';
import '../controller/settings_page_controller.dart';

class MainBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => NavigationController());
    Get.lazyPut(() => HomePageController());
    Get.lazyPut(() => ConnectPageController());
    Get.lazyPut(() => HistoryPageController());
    Get.lazyPut(() => SettingsPageController());
    Get.lazyPut(() => ProfileController());
    Get.lazyPut(() => LoginPageController());
    Get.lazyPut(() => ManualDataController());
    Get.lazyPut(() => WeightController());
    Get.lazyPut(() => UtilService());
  }
}

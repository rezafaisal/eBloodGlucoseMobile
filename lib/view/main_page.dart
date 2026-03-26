import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/navigation_controller.dart';

class MainPage extends GetView<NavigationController> {
  const MainPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() => IndexedStack(
        index: controller.selectedIndex.value,
        children: controller.pages,
      )),
      bottomNavigationBar: Obx(() => AnimatedBottomNavigationBar(
        icons: controller.iconList,
        gapLocation: GapLocation.none,
        activeIndex: controller.selectedIndex.value,
        onTap: (index) => controller.changePage(index),
      )),
    );
  }
}

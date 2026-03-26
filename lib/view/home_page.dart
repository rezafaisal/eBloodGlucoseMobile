import 'package:e_fever_care/view/widgets/glucose_gauge_card.dart';
import 'package:e_fever_care/view/widgets/summary_90day_card.dart';
import 'package:e_fever_care/view/widgets/recent_activities_card.dart';
import 'package:e_fever_care/view/manual_data_page.dart';
import 'package:e_fever_care/controller/manual_data_controller.dart';
import 'package:e_fever_care/controller/connect_page_controller.dart';
import 'package:e_fever_care/controller/settings_page_controller.dart';
import 'package:e_fever_care/controller/navigation_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/home_page_controller.dart';

class HomePage extends GetView<HomePageController> {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard",
            style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'refresh') {
                controller.refreshData();
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'refresh',
                  child: Row(
                    children: [
                      Icon(Icons.refresh, color: Colors.teal),
                      SizedBox(width: 8),
                      Text('Muat Ulang Data'),
                    ],
                  ),
                ),
              ];
            },
            icon: const Icon(Icons.more_vert, color: Colors.teal),
          ),
        ],
      ),
      body: Container(
        color: Colors.grey[200],
        child: OrientationBuilder(
          builder: (context, orientation) {
            if (orientation == Orientation.portrait) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    // Card utama: GlucoseGaugeCard
                    Obx(() => GlucoseGaugeCard(
                          glucose: controller.glucose.value.toInt(),
                          date: controller.date.value,
                          context: controller.context.value,
                          avg90days: controller.avg90days.value,
                          avgFasting: controller.avgFastingGlucose.value,
                          avgPostMeal: controller.avgPostMealGlucose.value,
                          status: controller.glucoseStatus.value.isNotEmpty
                              ? controller.glucoseStatus.value
                              : null,
                        )),

                    // Summary 90 hari card
                    Obx(() => Summary90DayCard(
                          normalCount: controller.normalCount.value,
                          lowCount: controller.lowCount.value,
                          highCount: controller.highCount.value,
                          totalCount: controller.totalCount.value,
                        )),

                    // Recent Activities card
                    GetBuilder<HomePageController>(
                      builder: (controller) => RecentActivitiesCard(
                        activities: controller.recentActivities.toList(),
                      ),
                    ),
                  ],
                ),
              );
            } else {
              // Landscape mode - responsive layout
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left column - Glucose Gauge
                      Expanded(
                        flex: 2,
                        child: Obx(() => GlucoseGaugeCard(
                              glucose: controller.glucose.value.toInt(),
                              date: controller.date.value,
                              context: controller.context.value,
                              avg90days: controller.avg90days.value,
                              avgFasting: controller.avgFastingGlucose.value,
                              avgPostMeal: controller.avgPostMealGlucose.value,
                              status: controller.glucoseStatus.value.isNotEmpty
                                  ? controller.glucoseStatus.value
                                  : null,
                              isLandscape: true,
                            )),
                      ),
                      const SizedBox(width: 12),
                      // Right column - Summary & Activities
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            Obx(() => Summary90DayCard(
                                  normalCount: controller.normalCount.value,
                                  lowCount: controller.lowCount.value,
                                  highCount: controller.highCount.value,
                                  totalCount: controller.totalCount.value,
                                )),
                            GetBuilder<HomePageController>(
                              builder: (controller) => RecentActivitiesCard(
                                activities:
                                    controller.recentActivities.toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "home_fab", // Add unique hero tag
        onPressed: () => _showAddManualDataDialog(context),
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddManualDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Row(
            children: [
              Icon(Icons.add_circle_outline, color: Colors.teal, size: 28),
              SizedBox(width: 12),
              Text(
                'Tambah Data',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.8,
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Pilih jenis data yang ingin ditambahkan:',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),

                  // Header Gula Darah
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Icon(Icons.bloodtype,
                              size: 18, color: Colors.grey[600]),
                          const SizedBox(width: 6),
                          Text(
                            'Gula Darah',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Tombol Gula Darah Otomatis dari Jam
                  SizedBox(
                    width: double.maxFinite,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        _startAutomaticGlucoseMeasurement(context);
                      },
                      icon: const Icon(Icons.watch,
                          color: Colors.white, size: 20),
                      label: const Text(
                        'Ukur dari Jam',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Tombol Gula Darah Manual
                  SizedBox(
                    width: double.maxFinite,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        Get.put(ManualDataController());
                        Get.to(() => const ManualDataPage());
                      },
                      icon:
                          const Icon(Icons.edit, color: Colors.white, size: 20),
                      label: const Text(
                        'Input Manual',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  // Divider/Separator
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Row(
                      children: [
                        Expanded(child: Divider(thickness: 1)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'LAINNYA',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(thickness: 1)),
                      ],
                    ),
                  ),

                  // Tombol Berat Badan
                  SizedBox(
                    width: double.maxFinite,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        Get.toNamed('/weight-data');
                      },
                      icon: const Icon(Icons.monitor_weight,
                          color: Colors.white, size: 20),
                      label: const Text(
                        'Berat Badan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
          ],
        );
      },
    );
  }

  void _startAutomaticGlucoseMeasurement(BuildContext context) {
    // Cek apakah SettingsPageController sudah ada
    final settingsController = Get.isRegistered<SettingsPageController>()
        ? Get.find<SettingsPageController>()
        : Get.put(SettingsPageController());

    // Validasi koneksi perangkat
    if (!settingsController.isConnect.value) {
      // Jika belum terhubung, tampilkan dialog untuk ke settings
      Get.defaultDialog(
        title: 'Perangkat Belum Terhubung',
        middleText:
            'Anda perlu menghubungkan jam smartwatch terlebih dahulu untuk menggunakan fitur ini.',
        textCancel: 'Batal',
        textConfirm: 'Ke Pengaturan',
        confirmTextColor: Colors.white,
        buttonColor: Colors.teal,
        onConfirm: () {
          Get.back();
          // Navigasi ke tab pengaturan (index 3)
          final navController = Get.find<NavigationController>();
          navController.selectedIndex.value = 3;
        },
      );
      return;
    }

    // Jika sudah terhubung, lanjutkan dengan pengukuran
    Get.defaultDialog(
      title: 'Konfirmasi',
      middleText:
          'Mulai pengukuran glukosa darah otomatis dari jam smartwatch?',
      textCancel: 'Batal',
      textConfirm: 'Mulai',
      confirmTextColor: Colors.white,
      buttonColor: Colors.blue,
      onConfirm: () {
        Get.back();

        // Cek apakah ConnectPageController sudah ada
        final connectController = Get.isRegistered<ConnectPageController>()
            ? Get.find<ConnectPageController>()
            : Get.put(ConnectPageController());

        connectController.startGlucoseDetect();

        Get.snackbar(
          "Sedang Mengukur",
          "Jam smartwatch sedang melakukan pengukuran glukosa darah...",
          margin: const EdgeInsets.all(8),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.blue.withOpacity(0.1),
          colorText: Colors.blue.shade700,
          icon: const Icon(Icons.monitor_heart_rounded, color: Colors.blue),
          duration: const Duration(seconds: 3),
        );
      },
    );
  }
}

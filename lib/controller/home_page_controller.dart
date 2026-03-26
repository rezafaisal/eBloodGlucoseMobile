import 'dart:async';

import 'package:e_fever_care/controller/manual_data_controller.dart';
import 'package:e_fever_care/controller/weight_controller.dart';
import 'package:e_fever_care/controller/connect_page_controller.dart';
import 'package:e_fever_care/service/utils_service.dart';
import 'package:e_fever_care/view/connect/connect_page.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

class HomePageController extends GetxController {
  final UtilService utilService = UtilService();

  final date = ''.obs;
  final glucose = 0.0.obs;
  final glucoseSpots = <FlSpot>[].obs;
  final avg90days = 0.0.obs; // Tambahan untuk rata-rata 90 hari

  // Tambahan untuk summary 90 hari
  final normalCount = 0.obs;
  final lowCount = 0.obs;
  final highCount = 0.obs;
  final totalCount = 0.obs;
  final recentActivities = <Map<String, dynamic>>[].obs;

  // Observable untuk context translated
  final context = ''.obs;

  // Observable untuk detailed average 90 days
  final avgAllGlucose = 0.0.obs;
  final avgFastingGlucose = 0.0.obs;
  final avgPostMealGlucose = 0.0.obs;
  final glucoseStatus = ''.obs;

  // Loading state
  final isLoading = false.obs;

  // Flag untuk trigger reload dari controller lain
  final shouldReload = false.obs;

  // Method untuk translate context
  String translateContext(String? contextValue) {
    if (contextValue == null) return '';
    switch (contextValue) {
      case 'before_breakfast':
        return 'Sebelum Sarapan';
      case 'after_breakfast':
        return 'Sesudah Sarapan';
      case 'random':
        return 'Sewaktu'; // Display as "Sewaktu" instead of "Acak"
      default:
        return contextValue;
    }
  }

  // Method untuk translate legacy meal_time format
  String translateLegacyMealTime(String? mealTime) {
    if (mealTime == null) return '';
    switch (mealTime.toLowerCase()) {
      case 'sebelum sarapan':
        return 'Sebelum Sarapan';
      case 'setelah sarapan':
        return 'Sesudah Sarapan';
      case 'sewaktu': // Handle UI frontend term
        return 'Sewaktu';
      case 'before breakfast':
        return 'Sebelum Sarapan';
      case 'after breakfast':
        return 'Sesudah Sarapan';
      case 'acak':
      case 'random':
        return 'Sewaktu'; // Display as "Sewaktu" in UI
      default:
        return mealTime;
    }
  }

  @override
  void onInit() async {
    glucoseSpots.value = utilService.chartData([]);
    await connectDevice();
    await getDashboardData(); // Use new dashboard API

    // Trigger auto-sync untuk semua pending data
    await triggerAutoSyncAll();

    // Listen untuk perubahan shouldReload
    ever(shouldReload, (_) {
      if (shouldReload.value) {
        print('🔄 Detected data change, reloading dashboard...');
        reloadDashboardFromServer();
        shouldReload.value = false; // Reset flag
      }
    });

    super.onInit();
  }

  Future<void> connectDevice() async {
    if (Hive.isBoxOpen('deviceData')) {
      var box = await Hive.openBox('deviceData');
      if (box.isNotEmpty) {
        Get.to(() => const ConnectPage());
      }
    }
  }

  Future<void> getGlucose() async {
    if (Hive.isBoxOpen('glucoseData')) {
      var box = await Hive.openBox('glucoseData');
      populateData(box);
      update();

      box.watch().listen((e) {
        populateData(box);
        update();
      });
    }
  }

  void populateData(Box box) {
    print('Populating data from local storage...');
    if (box.isNotEmpty) {
      List<dynamic> dataList = box.get('GlucoseList', defaultValue: []);
      print('Data count in local storage: ${dataList.length}');
      if (dataList.isNotEmpty) {
        DateTime today = utilService.dateToday;

        List<dynamic> todayDataList = dataList.where((entry) {
          DateTime date = DateTime.parse(entry['date']);
          return date.year == today.year &&
              date.month == today.month &&
              date.day == today.day;
        }).toList();

        // Urutkan berdasarkan waktu ASCENDING untuk chart
        todayDataList.sort((a, b) =>
            DateTime.parse(a['date']).compareTo(DateTime.parse(b['date'])));

        glucoseSpots.value = utilService.chartData(todayDataList);
      } else {
        print('No data found in local storage');
      }
    } else {
      print('Local storage box is empty');
    }
  }

  // New method to get dashboard data from API
  Future<void> getDashboardData() async {
    final connect = GetConnect();
    print('Fetching dashboard data from server...');

    // Load data lokal terlebih dahulu untuk ditampilkan
    await loadDashboardFromLocal();

    if (Hive.isBoxOpen('token')) {
      var box = await Hive.openBox('token');
      final token = box.getAt(0);

      if (token == null) {
        print('No token available, menggunakan data lokal');
        return;
      }

      print('Token: ${token.toString().substring(0, 20)}...');
      print('URL: ${utilService.url}/api/dashboard');

      await connect
          .get(
            '${utilService.url}/api/dashboard',
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10))
          .then((response) async {
            print('Response: ${response.statusCode}');
            print('Response body: ${response.body}');

            if (response.statusCode == 200) {
              var data = response.body;

              // Update latest glucose data
              if (data['latest'] != null) {
                var latest = data['latest'];
                date.value = latest['reading_time'];
                glucose.value =
                    double.parse(latest['blood_glucose'].toString());
                context.value = latest['context_label'] ??
                    translateContext(latest['context']);

                print(
                    'Latest glucose - Date: ${date.value}, Glucose: ${glucose.value}, Context: ${context.value}');
              }

              // Update summary 90 days
              if (data['summary_90_days'] != null) {
                var summary = data['summary_90_days'];
                lowCount.value = summary['low'] ?? 0;
                normalCount.value = summary['normal'] ?? 0;
                highCount.value = summary['high'] ?? 0;
                totalCount.value =
                    lowCount.value + normalCount.value + highCount.value;

                print(
                    'Summary 90 days - Low: ${lowCount.value}, Normal: ${normalCount.value}, High: ${highCount.value}');
              }

              // Update average 90 days
              if (data['average_90_days'] != null) {
                // Langsung parse dari data tanpa variabel tambahan
                avg90days.value = data['average_90_days']['all'] != null
                    ? double.parse(data['average_90_days']['all'].toString())
                    : 0.0;
                avgAllGlucose.value = avg90days.value;

                avgFastingGlucose.value =
                    data['average_90_days']['fasting'] != null
                        ? double.parse(
                            data['average_90_days']['fasting'].toString())
                        : 0.0;

                avgPostMealGlucose.value =
                    data['average_90_days']['post_meal'] != null
                        ? double.parse(
                            data['average_90_days']['post_meal'].toString())
                        : 0.0;

                glucoseStatus.value =
                    data['average_90_days']['status']?.toString() ?? '';

                print('Average 90 days: ${avg90days.value}');
                print(
                    'Detailed averages - All: ${avgAllGlucose.value}, Fasting: ${avgFastingGlucose.value}, Post Meal: ${avgPostMealGlucose.value}, Status: ${glucoseStatus.value}');
              }

              // Update recent activities from latest_list
              if (data['latest_list'] != null) {
                List<dynamic> latestList = data['latest_list'];
                recentActivities.value = latestList.take(5).map((entry) {
                  double glucoseValue =
                      double.parse(entry['blood_glucose'].toString());
                  String category;
                  if (glucoseValue < 70) {
                    category = 'Rendah';
                  } else if (glucoseValue > 130) {
                    category = 'Tinggi';
                  } else {
                    category = 'Normal';
                  }

                  return {
                    'date': entry['reading_time'],
                    'glucose': glucoseValue,
                    'category': category,
                    'context': entry['context_label'] ??
                        translateContext(entry['context']),
                  };
                }).toList();

                print('Recent activities count: ${recentActivities.length}');
              }

              // Save data to local storage for offline access
              await saveToLocalStorage(data);

              // Update chart with today's data
              await getGlucose();

              // Notify UI to update
              update();

              Get.snackbar(
                "Berhasil",
                "Data dashboard berhasil dimuat dari server",
                margin: const EdgeInsets.all(8),
                backgroundColor: Colors.teal,
                colorText: Colors.white,
                icon: const Icon(Icons.check_circle, color: Colors.white),
                snackPosition: SnackPosition.BOTTOM,
                duration: const Duration(seconds: 2),
              );
            } else {
              print(
                  'Error response: ${response.statusCode} - ${response.statusText}');
              if (response.statusCode == 401) {
                Get.snackbar(
                  "Info",
                  "Menggunakan data lokal. Token mungkin expired.",
                  margin: const EdgeInsets.all(8),
                  backgroundColor: Colors.orange,
                  colorText: Colors.white,
                  icon: const Icon(Icons.info, color: Colors.white),
                  snackPosition: SnackPosition.BOTTOM,
                );
              } else {
                Get.snackbar(
                  "Info",
                  "Menggunakan data lokal tersimpan",
                  margin: const EdgeInsets.all(8),
                  backgroundColor: Colors.orange,
                  colorText: Colors.white,
                  icon: const Icon(Icons.info, color: Colors.white),
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
              // Data sudah diload dari lokal di awal
            }
          })
          .catchError((error) {
            print('Request error: $error');
            Get.snackbar(
              "Info",
              "Mode Offline - Menggunakan data lokal tersimpan",
              margin: const EdgeInsets.all(8),
              backgroundColor: Colors.orange,
              colorText: Colors.white,
              icon: const Icon(Icons.cloud_off, color: Colors.white),
              snackPosition: SnackPosition.BOTTOM,
              duration: const Duration(seconds: 2),
            );
            // Data sudah diload dari lokal di awal
          });
    } else {
      print('Token box not open');
    }
  }

  // Save dashboard data to local storage
  Future<void> saveToLocalStorage(Map<String, dynamic> data) async {
    if (Hive.isBoxOpen('glucoseData')) {
      var glucoseBox = await Hive.openBox('glucoseData');

      // Simpan juga dashboard data untuk offline access
      await glucoseBox.put('dashboardCache', data);

      List<dynamic> existingData =
          glucoseBox.get('GlucoseList', defaultValue: []);

      // Save latest_list to local storage
      if (data['latest_list'] != null) {
        List<dynamic> latestList = data['latest_list'];

        for (var item in latestList) {
          bool exists = existingData
              .any((existing) => existing['date'] == item['reading_time']);

          if (!exists) {
            existingData.add({
              'date': item['reading_time'],
              'blood_glucose': double.parse(item['blood_glucose'].toString()),
              'context': item['context'],
            });
          }
        }

        await glucoseBox.put('GlucoseList', existingData);
        print('Dashboard data saved to local storage');
      }
    }
  }

  // Load dashboard data from local storage (untuk mode offline)
  Future<void> loadDashboardFromLocal() async {
    if (Hive.isBoxOpen('glucoseData')) {
      var glucoseBox = await Hive.openBox('glucoseData');
      var cachedDashboard = glucoseBox.get('dashboardCache');

      if (cachedDashboard != null) {
        print('📦 Loading dashboard from local cache...');

        // Update latest glucose data
        if (cachedDashboard['latest'] != null) {
          var latest = cachedDashboard['latest'];
          date.value = latest['reading_time'];
          glucose.value = double.parse(latest['blood_glucose'].toString());
          context.value =
              latest['context_label'] ?? translateContext(latest['context']);
        }

        // Update summary 90 days
        if (cachedDashboard['summary_90_days'] != null) {
          var summary = cachedDashboard['summary_90_days'];
          lowCount.value = summary['low'] ?? 0;
          normalCount.value = summary['normal'] ?? 0;
          highCount.value = summary['high'] ?? 0;
          totalCount.value =
              lowCount.value + normalCount.value + highCount.value;
        }

        // Update average 90 days
        if (cachedDashboard['average_90_days'] != null) {
          avg90days.value = cachedDashboard['average_90_days']['all'] != null
              ? double.parse(
                  cachedDashboard['average_90_days']['all'].toString())
              : 0.0;
          avgAllGlucose.value = avg90days.value;

          avgFastingGlucose.value =
              cachedDashboard['average_90_days']['fasting'] != null
                  ? double.parse(
                      cachedDashboard['average_90_days']['fasting'].toString())
                  : 0.0;

          avgPostMealGlucose.value = cachedDashboard['average_90_days']
                      ['post_meal'] !=
                  null
              ? double.parse(
                  cachedDashboard['average_90_days']['post_meal'].toString())
              : 0.0;

          glucoseStatus.value =
              cachedDashboard['average_90_days']['status']?.toString() ?? '';
        }

        // Update recent activities from latest_list
        if (cachedDashboard['latest_list'] != null) {
          List<dynamic> latestList = cachedDashboard['latest_list'];
          recentActivities.value = latestList.take(5).map((entry) {
            double glucoseValue =
                double.parse(entry['blood_glucose'].toString());
            String category;
            if (glucoseValue < 70) {
              category = 'Rendah';
            } else if (glucoseValue > 130) {
              category = 'Tinggi';
            } else {
              category = 'Normal';
            }

            return {
              'date': entry['reading_time'],
              'glucose': glucoseValue,
              'category': category,
              'context':
                  entry['context_label'] ?? translateContext(entry['context']),
            };
          }).toList();
        }

        // Load chart data
        await getGlucose();

        // Notify UI to update
        update();

        print('✅ Dashboard loaded from local cache');
      } else {
        print('📦 No cached dashboard data, loading glucose data only');
        await getGlucose();
      }
    }
  }

  // Method to refresh all data
  Future<void> refreshData() async {
    try {
      isLoading.value = true;

      // Reset all observable values
      glucose.value = 0.0;
      context.value = '';
      avg90days.value = 0.0;
      normalCount.value = 0;
      lowCount.value = 0;
      highCount.value = 0;
      totalCount.value = 0;
      glucoseSpots.clear();
      recentActivities.clear();

      // Reset detailed average values
      avgAllGlucose.value = 0.0;
      avgFastingGlucose.value = 0.0;
      avgPostMealGlucose.value = 0.0;
      glucoseStatus.value = '';

      // Trigger auto-sync untuk semua pending data (sebagai fallback)
      await triggerAutoSyncAll();

      // Reload data from dashboard API
      await getDashboardData();

      // Force update UI
      update();

      Get.snackbar(
        'Berhasil',
        'Data berhasil dimuat ulang',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.teal,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal memuat ulang data: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// ========== AUTO-SYNC TRIGGER ==========

  /// Method untuk reload dashboard dari server (dipanggil dari controller lain)
  Future<void> reloadDashboardFromServer() async {
    print('🔄 Reloading dashboard from server...');
    await getDashboardData();
  }

  /// Trigger auto-sync untuk semua controller
  Future<void> triggerAutoSyncAll() async {
    print('🔄 Memulai auto-sync untuk semua data pending...');

    // Import controllers jika belum
    try {
      // Sync glucose data (manual + device)
      final manualController = Get.find<ManualDataController>();
      await manualController.syncPendingGlucoseData();
    } catch (e) {
      print('⚠️ ManualDataController belum di-init, skip glucose sync');
    }

    try {
      // Sync weight data
      final weightController = Get.find<WeightController>();
      await weightController.syncPendingWeightData();
    } catch (e) {
      print('⚠️ WeightController belum di-init, skip weight sync');
    }

    try {
      // Sync device glucose data
      final connectController = Get.find<ConnectPageController>();
      await connectController.syncPendingDeviceGlucoseData();
    } catch (e) {
      print('⚠️ ConnectPageController belum di-init, skip device sync');
    }

    print('✅ Auto-sync selesai');
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../service/utils_service.dart';
import '../view/login_page.dart';

class SettingsPageController extends GetxController {
  final UtilService utilService = UtilService();
  final isConnect = false.obs;
  final name = 'Guest'.obs;
  final gender = '-'.obs;
  final dateOfBirth = '-'.obs;
  
  // Meal time settings
  final fastingStartTime = '20:00'.obs; // Default jam mulai puasa
  final breakfastTime = '06:00'.obs; // Default jam sarapan
  final lastUpdated = ''.obs; // For showing when settings were last updated
  final isLoadingSettings = false.obs; // Loading state for settings

  var isMonitoringGlucose = false.obs;

  @override
  void onInit() {
    populateData();
    getMealTimeSettings(); // Changed to get from server
    super.onInit();
  }

  @override
  void onReady() {
    checkConnect();
    super.onInit();
  }

  Future<void> checkConnect() async {
    final connected = await FlutterBluePlus.connectedSystemDevices;
    isConnect.value = connected.isNotEmpty;
  }

  Future<void> populateData () async {
    if (Hive.isBoxOpen('user')) {
      var box = await Hive.openBox('user');
      var value = box.getAt(0);
      name.value = value['name'];
      gender.value = value['gender'];
      dateOfBirth.value = value['date_of_birth'];
    }
  }
  
  Future<void> logout () async {
    if (Hive.isBoxOpen('token')) {
      var box = await Hive.openBox('token');
      box.clear();
    }
    if (Hive.isBoxOpen('user')) {
      var box = await Hive.openBox('user');
      box.clear();
    }
    if (Hive.isBoxOpen('deviceData')) {
      var box = await Hive.openBox('deviceData');
      box.clear();
    }
    if (Hive.isBoxOpen('temperatureData')) {
      var box = await Hive.openBox('temperatureData');
      await box.clear();
    }
    Get.to(() => const LoginPage());
  }
  
  // Get meal time settings from server
  Future<void> getMealTimeSettings() async {
    isLoadingSettings.value = true;
    try {
      if (Hive.isBoxOpen('token')) {
        var tokenBox = await Hive.openBox('token');
        final token = tokenBox.getAt(0);

        if (token != null) {
          final connect = GetConnect();
          print('Getting meal time settings from server...');

          final response = await connect.get(
            '${utilService.url}/api/me/settings',
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
          );

          print('Settings response: ${response.statusCode}');
          print('Settings response body: ${response.body}');

          if (response.statusCode == 200) {
            var settings = response.body['settings'];
            if (settings != null) {
              fastingStartTime.value = settings['fasting_start_at'] ?? '20:00';
              breakfastTime.value = settings['breakfast_at'] ?? '06:00';
              lastUpdated.value = _formatUpdatedAt(settings['updated_at']);

              // Save to local storage as cache
              var box = await Hive.openBox('mealTimeSettings');
              await box.put('fasting_start_time', fastingStartTime.value);
              await box.put('breakfast_time', breakfastTime.value);
              await box.put('last_updated', settings['updated_at']);

              print('Settings loaded from server - Fasting: ${fastingStartTime.value}, Breakfast: ${breakfastTime.value}');

              Get.snackbar(
                "Berhasil",
                "Pengaturan berhasil dimuat dari server",
                margin: const EdgeInsets.all(8),
                icon: const Icon(Icons.check, color: Colors.green),
                duration: const Duration(seconds: 2),
              );
            }
          } else {
            print('Failed to get settings from server: ${response.statusCode}');
            Get.snackbar(
              "Info",
              "Gagal memuat dari server, menggunakan data lokal",
              margin: const EdgeInsets.all(8),
              icon: const Icon(Icons.info, color: Colors.orange),
              duration: const Duration(seconds: 2),
            );
            // Fallback to local storage
            await loadMealTimeSettingsFromLocal();
          }
        } else {
          await loadMealTimeSettingsFromLocal();
        }
      } else {
        await loadMealTimeSettingsFromLocal();
      }
    } catch (e) {
      print('Error getting meal time settings: $e');
      Get.snackbar(
        "Error",
        "Terjadi kesalahan saat memuat pengaturan",
        margin: const EdgeInsets.all(8),
        icon: const Icon(Icons.error, color: Colors.red),
        duration: const Duration(seconds: 2),
      );
      await loadMealTimeSettingsFromLocal();
    } finally {
      isLoadingSettings.value = false;
    }
  }

  // Load meal time settings from local storage (fallback)
  Future<void> loadMealTimeSettingsFromLocal() async {
    try {
      var box = await Hive.openBox('mealTimeSettings');
      fastingStartTime.value = box.get('fasting_start_time', defaultValue: '20:00');
      breakfastTime.value = box.get('breakfast_time', defaultValue: '06:00');
      String lastUpdatedString = box.get('last_updated', defaultValue: '');
      if (lastUpdatedString.isNotEmpty) {
        lastUpdated.value = _formatUpdatedAt(lastUpdatedString);
      } else {
        lastUpdated.value = 'Belum pernah diperbarui';
      }
      print('Loaded meal time settings from local - Fasting: ${fastingStartTime.value}, Breakfast: ${breakfastTime.value}');
    } catch (e) {
      print('Error loading meal time settings from local: $e');
    }
  }
  
  // Update fasting start time
  Future<void> updateFastingStartTime(String time) async {
    try {
      bool success = await updateMealTimeSettings(
        fastingStartAt: time,
        breakfastAt: breakfastTime.value
      );

      if (success) {
        fastingStartTime.value = time;
        Get.snackbar(
          "Berhasil",
          "Jam mulai puasa berhasil diperbarui",
          margin: const EdgeInsets.all(8),
          icon: const Icon(Icons.check, color: Colors.green),
        );
      } else {
        Get.snackbar(
          "Gagal",
          "Gagal memperbarui jam mulai puasa",
          margin: const EdgeInsets.all(8),
          icon: const Icon(Icons.error, color: Colors.red),
        );
      }
    } catch (e) {
      print('Error updating fasting start time: $e');
      Get.snackbar(
        "Error",
        "Terjadi kesalahan: $e",
        margin: const EdgeInsets.all(8),
        icon: const Icon(Icons.error, color: Colors.red),
      );
    }
  }
  
  // Update breakfast time
  Future<void> updateBreakfastTime(String time) async {
    try {
      bool success = await updateMealTimeSettings(
        fastingStartAt: fastingStartTime.value,
        breakfastAt: time
      );

      if (success) {
        breakfastTime.value = time;
        Get.snackbar(
          "Berhasil",
          "Jam sarapan berhasil diperbarui",
          margin: const EdgeInsets.all(8),
          icon: const Icon(Icons.check, color: Colors.green),
        );
      } else {
        Get.snackbar(
          "Gagal",
          "Gagal memperbarui jam sarapan",
          margin: const EdgeInsets.all(8),
          icon: const Icon(Icons.error, color: Colors.red),
        );
      }
    } catch (e) {
      print('Error updating breakfast time: $e');
      Get.snackbar(
        "Error",
        "Terjadi kesalahan: $e",
        margin: const EdgeInsets.all(8),
        icon: const Icon(Icons.error, color: Colors.red),
      );
    }
  }

  // Update meal time settings to server
  Future<bool> updateMealTimeSettings({required String fastingStartAt, required String breakfastAt}) async {
    try {
      if (Hive.isBoxOpen('token')) {
        var tokenBox = await Hive.openBox('token');
        final token = tokenBox.getAt(0);

        if (token != null) {
          final connect = GetConnect();
          print('Updating meal time settings to server...');
          print('Data: fasting_start_at=$fastingStartAt, breakfast_at=$breakfastAt');

          final response = await connect.patch(
            '${utilService.url}/api/me/settings',
            {
              'fasting_start_at': fastingStartAt,
              'breakfast_at': breakfastAt,
            },
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
          );

          print('Update response: ${response.statusCode}');
          print('Update response body: ${response.body}');

          if (response.statusCode == 200) {
            // Update local cache
            var box = await Hive.openBox('mealTimeSettings');
            await box.put('fasting_start_time', fastingStartAt);
            await box.put('breakfast_time', breakfastAt);

            // Update lastUpdated from response if available
            if (response.body['settings'] != null && response.body['settings']['updated_at'] != null) {
              lastUpdated.value = _formatUpdatedAt(response.body['settings']['updated_at']);
              await box.put('last_updated', response.body['settings']['updated_at']);
            } else {
              // Use current time if not provided
              String currentTime = DateTime.now().toIso8601String();
              lastUpdated.value = _formatUpdatedAt(currentTime);
              await box.put('last_updated', currentTime);
            }

            return true;
          } else {
            print('Failed to update settings: ${response.statusCode}');
            return false;
          }
        }
      }
      return false;
    } catch (e) {
      print('Error updating meal time settings: $e');
      return false;
    }
  }

  // Format updated_at timestamp to human readable format
  String _formatUpdatedAt(String? updatedAt) {
    if (updatedAt == null || updatedAt.isEmpty) {
      return 'Belum pernah diperbarui';
    }

    try {
      DateTime updateTime = DateTime.parse(updatedAt);
      DateTime now = DateTime.now();
      Duration difference = now.difference(updateTime);

      if (difference.inMinutes < 1) {
        return 'Baru saja';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} menit yang lalu';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} jam yang lalu';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} hari yang lalu';
      } else if (difference.inDays < 30) {
        int weeks = (difference.inDays / 7).floor();
        return '$weeks minggu yang lalu';
      } else if (difference.inDays < 365) {
        int months = (difference.inDays / 30).floor();
        return '$months bulan yang lalu';
      } else {
        int years = (difference.inDays / 365).floor();
        return '$years tahun yang lalu';
      }
    } catch (e) {
      print('Error formatting updated_at: $e');
      return 'Waktu tidak valid';
    }
  }
  
  // TODO: Future API integration
  // Future<void> _sendMealTimeToServer() async {
  //   try {
  //     final response = await http.post(
  //       Uri.parse('$baseUrl/meal-time-settings'),
  //       headers: {'Content-Type': 'application/json'},
  //       body: jsonEncode({
  //         'fasting_start_time': fastingStartTime.value,
  //         'breakfast_time': breakfastTime.value,
  //       }),
  //     );
  //     
  //     if (response.statusCode == 200) {
  //       print('Meal time settings synced to server');
  //     } else {
  //       print('Failed to sync meal time settings');
  //     }
  //   } catch (e) {
  //     print('Error syncing meal time settings: $e');
  //   }
  // }
}

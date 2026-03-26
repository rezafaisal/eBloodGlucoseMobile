import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

import '../service/utils_service.dart';
import 'home_page_controller.dart';

class ManualDataController extends GetxController {
  final UtilService utilService = UtilService();
  final manualDataList = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;
  final token = ''.obs;

  @override
  void onInit() {
    super.onInit();
    getToken();
    loadManualData();
    // Auto-sync pending data saat controller init
    syncPendingGlucoseData();
  }

  Future<void> getToken() async {
    if (Hive.isBoxOpen('token')) {
      var box = await Hive.openBox('token');
      if (box.isNotEmpty) {
        token.value = box.getAt(0);
      }
    }
  }

  Future<void> loadManualData() async {
    isLoading.value = true;
    try {
      if (Hive.isBoxOpen('glucoseData')) {
        var box = await Hive.openBox('glucoseData');
        List<dynamic> allData = box.get('GlucoseList', defaultValue: []);

        // Ambil SEMUA data (manual + device) dan urutkan berdasarkan waktu terbaru
        List<Map<String, dynamic>> sortedData = allData.map((item) {
          // Determine source of data
          String source = 'manual'; // default
          if (item['context'] == 'random' && item['is_manual'] != true) {
            source = 'device'; // Data dari alat
          }

          // Get display label for meal time / context
          String displayLabel = '';
          if (item['meal_time'] != null) {
            displayLabel = item['meal_time'];
          } else if (item['context'] != null) {
            displayLabel = _contextToLabel(item['context']);
          }

          return {
            'date': item['date'],
            'blood_glucose': item['blood_glucose'],
            'meal_time': displayLabel,
            'context': item['context'],
            'source': source, // 'manual' atau 'device'
            'synced': item['synced'] ?? false, // Status sync
            'formatted_date': DateFormat('dd MMM yyyy, HH:mm')
                .format(DateTime.parse(item['date'])),
          };
        }).toList();

        // Urutkan berdasarkan tanggal terbaru
        sortedData.sort((a, b) =>
            DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));

        manualDataList.value = sortedData;
        print('📊 Total data loaded: ${sortedData.length} (manual + device)');
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "Gagal memuat data: $e",
        margin: const EdgeInsets.all(8),
        icon: const Icon(Icons.error, color: Colors.red),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Helper to convert context to display label
  String _contextToLabel(String context) {
    switch (context) {
      case 'before_breakfast':
        return 'Sebelum Sarapan';
      case 'after_breakfast':
        return 'Sesudah Sarapan';
      case 'random':
        return 'Sewaktu';
      default:
        return context;
    }
  }

  // Helper method to convert meal_time to context format
  String convertMealTimeToContext(String mealTime) {
    switch (mealTime.toLowerCase()) {
      case 'sebelum sarapan':
      case 'before breakfast':
        return 'before_breakfast';
      case 'setelah sarapan':
      case 'after breakfast':
        return 'after_breakfast';
      case 'sewaktu': // Mapping untuk UI frontend
      case 'acak':
      case 'random':
        return 'random';
      default:
        return 'random'; // Default fallback
    }
  }

  Future<void> addManualGlucoseData(
      String bloodGlucose, String readingTime, String mealTime) async {
    try {
      // LANGSUNG push ke server DULU (priority)
      bool serverSuccess =
          await sendDataToServer(bloodGlucose, readingTime, mealTime);

      if (serverSuccess) {
        // Jika server sukses, simpan ke lokal dengan flag synced: true
        await saveGlucoseToLocal(bloodGlucose, readingTime, mealTime,
            synced: true);

        Get.snackbar(
          "Success",
          "Data gula darah berhasil ditambahkan dan disinkronkan ke server",
          margin: const EdgeInsets.all(8),
          backgroundColor: Colors.teal,
          colorText: Colors.white,
          icon: const Icon(Icons.check, color: Colors.white),
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      } else {
        // Jika server gagal, simpan ke lokal dengan flag synced: false
        // Auto-sync nanti akan handle ini sebagai fallback
        await saveGlucoseToLocal(bloodGlucose, readingTime, mealTime,
            synced: false);

        Get.snackbar(
          "Info",
          "Data disimpan secara lokal. Akan disinkronkan saat terhubung internet.",
          margin: const EdgeInsets.all(8),
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          icon: const Icon(Icons.info, color: Colors.white),
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
      }

      // Refresh the data display
      loadManualData();

      // Trigger refresh dashboard dari server
      _triggerDashboardReload();
    } catch (e) {
      Get.snackbar(
        "Error",
        "Gagal menambahkan data: $e",
        margin: const EdgeInsets.all(8),
        backgroundColor: Colors.red,
        colorText: Colors.white,
        icon: const Icon(Icons.error, color: Colors.white),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Helper method to save glucose to local storage
  Future<void> saveGlucoseToLocal(
      String bloodGlucose, String readingTime, String mealTime,
      {required bool synced}) async {
    if (Hive.isBoxOpen('glucoseData')) {
      var glucoseBox = await Hive.openBox('glucoseData');
      List<dynamic> existingData =
          glucoseBox.get('GlucoseList', defaultValue: []);

      // Check if data already exists for this exact time
      bool exists = existingData.any((existing) =>
          DateTime.parse(existing['date'])
              .isAtSameMomentAs(DateTime.parse(readingTime)));

      if (!exists) {
        existingData.add({
          'date': readingTime,
          'blood_glucose': double.parse(bloodGlucose),
          'meal_time': mealTime, // Keep for display purposes
          'context':
              convertMealTimeToContext(mealTime), // Add context for new format
          'is_manual': true, // Flag untuk menandai data manual
          'synced': synced, // Set based on server response
        });

        await glucoseBox.put('GlucoseList', existingData);
        print(
            '✅ Data disimpan ke lokal: $readingTime -> $bloodGlucose mg/dL (synced: $synced)');
      } else {
        throw Exception('Data untuk waktu tersebut sudah ada');
      }
    }
  }

  Future<bool> sendDataToServer(
      String bloodGlucose, String readingTime, String mealTime) async {
    try {
      if (token.value.isEmpty) {
        await getToken();
      }

      if (token.value.isEmpty) {
        print('Token tidak tersedia, simpan ke lokal saja');
        return false;
      }

      final connect = GetConnect();

      // Convert mealTime to context format for new API
      String context = convertMealTimeToContext(mealTime);

      print('📤 Mengirim data ke server...');
      print(
          'Data: blood_glucose=$bloodGlucose, reading_time=$readingTime, context=$context (from meal_time: $mealTime)');

      final response = await connect.post(
        '${utilService.url}/api/blood-glucose',
        {
          'blood_glucose': double.parse(bloodGlucose), // Convert to number
          'reading_time': readingTime,
          'context': context,
        },
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${token.value}',
        },
      ).timeout(const Duration(seconds: 10)); // Timeout 10 detik

      print('📥 Response server: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Update flag synced di lokal
        await updateSyncedStatus(readingTime, true);
        return true;
      } else {
        print('❌ Server error: ${response.statusText}');
        return false;
      }
    } catch (e) {
      print('❌ Error mengirim ke server: $e');
      return false;
    }
  }

  // Update synced status for a specific entry
  Future<void> updateSyncedStatus(String readingTime, bool synced) async {
    if (Hive.isBoxOpen('glucoseData')) {
      var glucoseBox = await Hive.openBox('glucoseData');
      List<dynamic> existingData =
          glucoseBox.get('GlucoseList', defaultValue: []);

      for (var item in existingData) {
        if (item['date'] == readingTime) {
          item['synced'] = synced;
          break;
        }
      }

      await glucoseBox.put('GlucoseList', existingData);
    }
  }

  /// ========== AUTO-SYNC MECHANISM ==========

  /// Sync semua data glucose yang belum ter-push ke server
  Future<void> syncPendingGlucoseData() async {
    try {
      if (token.value.isEmpty) {
        await getToken();
      }

      if (token.value.isEmpty) {
        print('🔒 Token tidak tersedia, skip auto-sync');
        return;
      }

      if (Hive.isBoxOpen('glucoseData')) {
        var glucoseBox = await Hive.openBox('glucoseData');
        List<dynamic> allData = glucoseBox.get('GlucoseList', defaultValue: []);

        // Filter data yang belum sync
        List<dynamic> pendingData = allData.where((item) {
          return item['synced'] == false || item['synced'] == null;
        }).toList();

        if (pendingData.isEmpty) {
          print('✅ Tidak ada data glucose pending untuk di-sync');
          return;
        }

        print(
            '🔄 Menemukan ${pendingData.length} data glucose yang belum sync');

        int successCount = 0;
        int failedCount = 0;

        for (var data in pendingData) {
          String bloodGlucose = data['blood_glucose'].toString();
          String readingTime = data['date'];
          String context = data['context'] ?? 'random';

          print('📤 Mencoba sync: $readingTime -> $bloodGlucose mg/dL');

          // Coba push ke server
          bool success = await _syncSingleGlucoseToServer(
              bloodGlucose, readingTime, context);

          if (success) {
            await updateSyncedStatus(readingTime, true);
            successCount++;
            print('✅ Sync berhasil: $readingTime');
          } else {
            failedCount++;
            print('❌ Sync gagal: $readingTime');
          }

          // Delay kecil untuk menghindari rate limiting
          await Future.delayed(const Duration(milliseconds: 300));
        }

        // Notifikasi hasil sync
        if (successCount > 0) {
          Get.snackbar(
            "Sinkronisasi Berhasil",
            "$successCount data gula darah berhasil disinkronkan ke server",
            margin: const EdgeInsets.all(8),
            backgroundColor: Colors.teal,
            colorText: Colors.white,
            icon: const Icon(Icons.cloud_done, color: Colors.white),
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 3),
          );
        }

        if (failedCount > 0) {
          print('⚠️ $failedCount data gagal sync, akan dicoba lagi nanti');
        }

        print('📊 Sync Summary - Success: $successCount, Failed: $failedCount');
      }
    } catch (e) {
      print('❌ Error saat auto-sync glucose: $e');
    }
  }

  /// Helper untuk sync single item (tanpa update UI/snackbar)
  Future<bool> _syncSingleGlucoseToServer(
      String bloodGlucose, String readingTime, String context) async {
    try {
      final connect = GetConnect();

      final response = await connect.post(
        '${utilService.url}/api/blood-glucose',
        {
          'blood_glucose': double.parse(bloodGlucose),
          'reading_time': readingTime,
          'context': context,
        },
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${token.value}',
        },
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  /// Method untuk manual sync (dipanggil dari UI)
  Future<void> manualSyncGlucoseData() async {
    isLoading.value = true;
    try {
      await syncPendingGlucoseData();
      await loadManualData(); // Refresh display
    } finally {
      isLoading.value = false;
    }
  }

  /// ========== DASHBOARD RELOAD TRIGGER ==========

  /// Trigger reload dashboard dari server (setelah input data baru)
  void _triggerDashboardReload() {
    try {
      final homeController = Get.find<HomePageController>();
      print('🔄 Triggering dashboard reload...');
      // Set flag untuk trigger reload
      homeController.shouldReload.value = true;
    } catch (e) {
      print('⚠️ HomePageController belum di-init, skip dashboard reload');
    }
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

import '../service/utils_service.dart';
import 'home_page_controller.dart';

class WeightController extends GetxController {
  final UtilService utilService = UtilService();
  final weightDataList = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;
  final token = ''.obs;

  @override
  void onInit() {
    super.onInit();
    getToken();
    loadWeightData(); // Hanya load data lokal
    // Auto-sync pending data saat controller init
    syncPendingWeightData();
  }

  Future<void> getToken() async {
    if (Hive.isBoxOpen('token')) {
      var box = await Hive.openBox('token');
      if (box.isNotEmpty) {
        token.value = box.getAt(0);
      }
    }
  }

  Future<void> loadWeightData() async {
    isLoading.value = true;
    try {
      if (Hive.isBoxOpen('weightData')) {
        var box = await Hive.openBox('weightData');
        List<dynamic> allData = box.get('WeightList', defaultValue: []);

        List<Map<String, dynamic>> sortedData = allData
            .map((item) => {
                  'date': item['date'],
                  'weight': item['weight'],
                  'synced': item['synced'] ?? false, // Tambah status sync
                  'formatted_date': DateFormat('dd MMM yyyy, HH:mm')
                      .format(DateTime.parse(item['date'])),
                })
            .toList();

        // Urutkan berdasarkan tanggal terbaru
        sortedData.sort((a, b) =>
            DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));

        weightDataList.value = sortedData;
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

  Future<void> addWeightData(String weight, String recordingTime) async {
    try {
      // LANGSUNG push ke server DULU (priority)
      bool serverSuccess = await sendWeightToServer(weight, recordingTime);

      if (serverSuccess) {
        // Jika server sukses, simpan ke lokal dengan flag synced: true
        await saveWeightToLocal(weight, recordingTime, synced: true);

        Get.snackbar(
          "Success",
          "Data berat badan berhasil ditambahkan dan disinkronkan ke server",
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
        await saveWeightToLocal(weight, recordingTime, synced: false);

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
      loadWeightData();

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

  // Helper method to save weight to local storage
  Future<void> saveWeightToLocal(String weight, String recordingTime,
      {required bool synced}) async {
    if (Hive.isBoxOpen('weightData')) {
      var weightBox = await Hive.openBox('weightData');
      List<dynamic> existingData =
          weightBox.get('WeightList', defaultValue: []);

      // Check if data already exists for this exact time
      bool exists = existingData.any((existing) =>
          DateTime.parse(existing['date'])
              .isAtSameMomentAs(DateTime.parse(recordingTime)));

      if (!exists) {
        existingData.add({
          'date': recordingTime,
          'weight': double.parse(weight),
          'is_manual': true,
          'synced': synced, // Set based on server response
        });

        await weightBox.put('WeightList', existingData);
        print(
            '✅ Data berat badan disimpan ke lokal: $recordingTime -> $weight kg (synced: $synced)');
      } else {
        throw Exception('Data untuk waktu tersebut sudah ada');
      }
    }
  }

  Future<bool> sendWeightToServer(String weight, String recordingTime) async {
    try {
      if (token.value.isEmpty) {
        await getToken();
      }

      if (token.value.isEmpty) {
        print('Token tidak tersedia, simpan ke lokal saja');
        return false;
      }

      final connect = GetConnect();
      print('📤 Mengirim data berat badan ke server...');

      // Convert to ISO 8601 format with Z timezone
      DateTime dateTime = DateTime.parse(recordingTime);
      String isoDateTime = dateTime.toUtc().toIso8601String();
      // Ensure it ends with Z
      if (!isoDateTime.endsWith('Z')) {
        isoDateTime = isoDateTime.replaceAll(RegExp(r'\+00:00$'), 'Z');
      }

      print('Data: weight=$weight, recorded_at=$isoDateTime');

      final response = await connect.post(
        '${utilService.url}/api/weight-readings',
        {
          'weight': double.parse(weight), // Convert to number
          'recorded_at': isoDateTime, // Use recorded_at field with ISO format
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
        await updateSyncedStatus(recordingTime, true);
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
  Future<void> updateSyncedStatus(String recordingTime, bool synced) async {
    if (Hive.isBoxOpen('weightData')) {
      var weightBox = await Hive.openBox('weightData');
      List<dynamic> existingData =
          weightBox.get('WeightList', defaultValue: []);

      for (var item in existingData) {
        if (item['date'] == recordingTime) {
          item['synced'] = synced;
          break;
        }
      }

      await weightBox.put('WeightList', existingData);
    }
  }

  /// ========== AUTO-SYNC MECHANISM ==========

  /// Sync semua data weight yang belum ter-push ke server
  Future<void> syncPendingWeightData() async {
    try {
      if (token.value.isEmpty) {
        await getToken();
      }

      if (token.value.isEmpty) {
        print('🔒 Token tidak tersedia, skip auto-sync weight');
        return;
      }

      if (Hive.isBoxOpen('weightData')) {
        var weightBox = await Hive.openBox('weightData');
        List<dynamic> allData = weightBox.get('WeightList', defaultValue: []);

        // Filter data yang belum sync
        List<dynamic> pendingData = allData.where((item) {
          return item['synced'] == false || item['synced'] == null;
        }).toList();

        if (pendingData.isEmpty) {
          print('✅ Tidak ada data berat badan pending untuk di-sync');
          return;
        }

        print(
            '🔄 Menemukan ${pendingData.length} data berat badan yang belum sync');

        int successCount = 0;
        int failedCount = 0;

        for (var data in pendingData) {
          String weight = data['weight'].toString();
          String recordingTime = data['date'];

          print('📤 Mencoba sync weight: $recordingTime -> $weight kg');

          // Coba push ke server
          bool success = await _syncSingleWeightToServer(weight, recordingTime);

          if (success) {
            await updateSyncedStatus(recordingTime, true);
            successCount++;
            print('✅ Sync weight berhasil: $recordingTime');
          } else {
            failedCount++;
            print('❌ Sync weight gagal: $recordingTime');
          }

          // Delay kecil untuk menghindari rate limiting
          await Future.delayed(const Duration(milliseconds: 300));
        }

        // Notifikasi hasil sync
        if (successCount > 0) {
          Get.snackbar(
            "Sinkronisasi Berhasil",
            "$successCount data berat badan berhasil disinkronkan ke server",
            margin: const EdgeInsets.all(8),
            backgroundColor: Colors.teal,
            colorText: Colors.white,
            icon: const Icon(Icons.cloud_done, color: Colors.white),
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 3),
          );
        }

        if (failedCount > 0) {
          print(
              '⚠️ $failedCount data weight gagal sync, akan dicoba lagi nanti');
        }

        print(
            '📊 Weight Sync Summary - Success: $successCount, Failed: $failedCount');
      }
    } catch (e) {
      print('❌ Error saat auto-sync weight: $e');
    }
  }

  /// Helper untuk sync single weight item (tanpa update UI/snackbar)
  Future<bool> _syncSingleWeightToServer(
      String weight, String recordingTime) async {
    try {
      final connect = GetConnect();

      // Convert to ISO 8601 format with Z timezone
      DateTime dateTime = DateTime.parse(recordingTime);
      String isoDateTime = dateTime.toUtc().toIso8601String();
      if (!isoDateTime.endsWith('Z')) {
        isoDateTime = isoDateTime.replaceAll(RegExp(r'\+00:00$'), 'Z');
      }

      final response = await connect.post(
        '${utilService.url}/api/weight-readings',
        {
          'weight': double.parse(weight),
          'recorded_at': isoDateTime,
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
  Future<void> manualSyncWeightData() async {
    isLoading.value = true;
    try {
      await syncPendingWeightData();
      await loadWeightData(); // Refresh display
    } finally {
      isLoading.value = false;
    }
  }

  // Method to fetch weight data from server
  Future<void> getWeightFromServer() async {
    final connect = GetConnect();
    print('Fetching weight data from server...');
    if (Hive.isBoxOpen('token')) {
      var box = await Hive.openBox('token');
      final token = box.getAt(0);
      print('Token for weight: $token');
      print('URL for weight: ${utilService.url}/api/weight-readings');

      await connect.get(
        '${utilService.url}/api/weight-readings',
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).then((response) async {
        print('Weight Response: ${response.statusCode}');
        print('Weight Response body: ${response.body}');
        if (response.statusCode == 200) {
          if (Hive.isBoxOpen('weightData')) {
            var weightBox = await Hive.openBox('weightData');
            List<dynamic> existingData =
                weightBox.get('WeightList', defaultValue: []);

            // Handle different response formats
            var tempData =
                response.body['data'] ?? response.body['weight_readings'];
            print('Raw weight data from server: $tempData');

            List<dynamic> newData = [];
            if (tempData is List) {
              newData = tempData;
            } else if (tempData is Map) {
              newData = [tempData];
            }

            print('Processed weight data count: ${newData.length}');

            for (var data in newData) {
              // Handle both 'recorded_at' and 'created_at' fields
              String? dateField =
                  data['recorded_at'] ?? data['created_at'] ?? data['date'];
              if (dateField != null && dateField.isNotEmpty) {
                bool exists = existingData.any((existing) =>
                    DateTime.parse(existing['date'])
                        .isAtSameMomentAs(DateTime.parse(dateField)));

                if (!exists) {
                  existingData.add({
                    'date': dateField,
                    'weight': double.parse(data['weight'].toString()),
                  });
                  print(
                      'Added new weight data: $dateField - ${data['weight']}');
                } else {
                  print('Weight data already exists: $dateField');
                }
              }
            }
            await weightBox.put('WeightList', existingData);
            print('Total weight data in storage: ${existingData.length}');

            // Update local data display
            loadWeightData();
          }
        } else {
          print(
              'Weight endpoint error: ${response.statusCode} - ${response.statusText}');
          if (response.statusCode == 401) {
            print('Token expired for weight endpoint');
          }
          // Always load from local storage as fallback
          await loadWeightData();
        }
      }).catchError((error) {
        print('Weight request error: $error');
        // Load from local storage as fallback
        loadWeightData();
      });
    } else {
      print('Token box not open for weight request');
    }
  }

  // Method to refresh weight data
  Future<void> refreshWeightData() async {
    try {
      isLoading.value = true;
      await getWeightFromServer();

      Get.snackbar(
        'Berhasil',
        'Data berat badan berhasil dimuat ulang',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.teal,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal memuat ulang data berat badan: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
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

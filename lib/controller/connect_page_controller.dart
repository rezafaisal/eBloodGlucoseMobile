import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

import '../service/utils_service.dart';
import 'home_page_controller.dart';

class ConnectPageController extends GetxController {
  final UtilService utilService = UtilService();

  late BluetoothCharacteristic et570NotifyChar;
  late BluetoothCharacteristic et570WriteChar;
  late StreamSubscription et570Stream;

  final token = ''.obs;

  @override
  void onInit() {
    super.onInit();
    getToken();
    // Auto-sync pending glucose data from device
    syncPendingDeviceGlucoseData();
  }

  /// Setup notification + write characteristic
  void setupET570Notifications(List<BluetoothService> services) async {
    try {
      // Get token first for API calls
      await getToken();

      var service = services.firstWhere((s) =>
          s.uuid.toString().toLowerCase() ==
          'f0080001-0451-4000-b000-000000000000');

      et570NotifyChar = service.characteristics.firstWhere((c) =>
          c.uuid.toString().toLowerCase() ==
          'f0080002-0451-4000-b000-000000000000');

      et570WriteChar = service.characteristics.firstWhere((c) =>
          c.uuid.toString().toLowerCase() ==
          'f0080003-0451-4000-b000-000000000000');

      await et570NotifyChar.setNotifyValue(true);

      et570Stream = et570NotifyChar.onValueReceived.listen((data) {
        if (data.isNotEmpty) {
          final head = data[0];

          if (head == 0x89) {
            _parseGlucoseDetect(data);
          } else if (head == 0xDF) {
            _parseGlucoseHistory(data);
          }
        }
      });

      await Future.delayed(const Duration(milliseconds: 500));
      await setGlucoseUnitMgdl();
    } catch (e) {
      print("setupET570Notifications error $e");
    }
  }

  /// Parsing manual glucose detect
  void _parseGlucoseDetect(List<int> data) async {
    try {
      print("📥 Raw glucose packet: $data");

      if (data.length < 7) return;

      final status = data[3];
      final progress = data[4];

      if (status == 0 || status == 1) {
        final raw = (data[5] & 0xFF) | ((data[6] & 0xFF) << 8);
        final glucoseMmol = raw / 100.0;
        final glucoseMgdl = glucoseMmol * 18.0;

        if (progress >= 100) {
          print(
              "✅ Final Glucose: ${glucoseMgdl.toStringAsFixed(1)} mg/dL (100%)");
          final now = DateTime.now().toIso8601String();

          // Push ke server dan simpan di lokal
          await saveGlucoseWithServerSync(glucoseMgdl, now);
        } else {
          print(
              "⏳ Glucose detecting... progress: $progress% | partial ${glucoseMgdl.toStringAsFixed(1)} mg/dL");
        }
      } else {
        String reason;
        switch (status) {
          case 2:
            reason = "Low Power";
            break;
          case 3:
            reason = "Busy";
            break;
          case 4:
            reason = "Wearing Error";
            break;
          default:
            reason = "Unknown Status";
        }
        print("⚠️ Detection error: $reason");
      }
    } catch (e) {
      print("❌ _parseGlucoseDetect error: $e");
    }
  }

  /// Parsing glucose history
  void _parseGlucoseHistory(List<int> data) {
    int dayIndex = data[1];
    print("Glucose History Packet (day=$dayIndex)");

    for (int i = 0; i < data.length - 3; i++) {
      if (data[i] == 0xB8) {
        int raw = (data[i + 2] & 0xFF) | ((data[i + 3] & 0xFF) << 8);
        double glucose = raw / 100.0;
        print("History glucose found: $glucose mmol/L (B8 block)");
        // TODO: tambahkan parsing timestamp (B1/B2 blok) biar ada tanggal
      }
    }
  }

  /// ---- COMMAND PAYLOADS ----

  /// Disconnect Device
  Future<void> sendDisconnectDevice() async {
    final payload = [
      0x89,
      0x03,
      0x02,
      0x01,
      0x01,
      0x02,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00
    ];
    await et570WriteChar.write(payload, withoutResponse: true);
    print("📴 Sent release/unbind command to device");
  }

  /// Set unit ke mg/dL
  Future<void> setGlucoseUnitMgdl() async {
    final payload = [
      0xB8,
      0x01,
      0x01,
      0x00,
      0x02,
      0x01,
      0x00,
      0x02,
      0x00,
      0x00,
      0x02,
      0x02,
      0x01,
      0x01,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x01
    ];
    await et570WriteChar.write(payload, withoutResponse: true);
    print("✅ Auto set Unit: mg/dL");
  }

  /// Aktifkan monitoring glukosa otomatis
  Future<void> sendGlucoseMonitoringOn() async {
    final payload = [
      0xB8,
      0x01,
      0x00,
      0x00,
      0x02,
      0x01,
      0x00,
      0x01,
      0x00,
      0x00,
      0x01,
      0x02,
      0x01,
      0x01,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x01
    ];
    await et570WriteChar.write(payload, withoutResponse: true);
    print("Sent Glucose Monitoring ON");
  }

  /// Nonaktifkan monitoring glukosa otomatis
  Future<void> sendGlucoseMonitoringOff() async {
    final payload = [
      0xB8,
      0x01,
      0x00,
      0x00,
      0x02,
      0x01,
      0x00,
      0x02,
      0x00,
      0x00,
      0x01,
      0x02,
      0x01,
      0x01,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x01
    ];
    await et570WriteChar.write(payload, withoutResponse: true);
    print("Sent Glucose Monitoring OFF");
  }

  /// Start manual glucose detect
  Future<void> startGlucoseDetect() async {
    final payload = [0x89, 0x01, 0x01, 0x00];
    await et570WriteChar.write(payload, withoutResponse: true);
    print("Sent Start Glucose Detect");
  }

  /// Stop glucose detect
  Future<void> stopGlucoseDetect() async {
    final payload = [0x89, 0x01, 0x02];
    await et570WriteChar.write(payload, withoutResponse: true);
    print("Sent Stop Glucose Detect");
  }

  /// Request glucose history: today
  Future<void> requestGlucoseToday() async {
    final payload = [0xDF, 0x01, 0x00, 0x00];
    await et570WriteChar.write(payload, withoutResponse: true);
    print("Request Glucose Today");
  }

  /// Request glucose history: yesterday
  Future<void> requestGlucoseYesterday() async {
    final payload = [0xDF, 0x01, 0x00, 0x01];
    await et570WriteChar.write(payload, withoutResponse: true);
    print("Request Glucose Yesterday");
  }

  /// Request glucose history: 2 days ago
  Future<void> requestGlucoseBeforeYesterday() async {
    final payload = [0xDF, 0x01, 0x00, 0x02];
    await et570WriteChar.write(payload, withoutResponse: true);
    print("Request Glucose Before Yesterday");
  }

  /// ---- HIVE STORAGE ----

  Future<void> getToken() async {
    if (Hive.isBoxOpen('token')) {
      var box = await Hive.openBox('token');
      if (box.isNotEmpty) {
        token.value = box.getAt(0);
      }
    }
  }

  /// Push ke server dan simpan di lokal untuk jaga-jaga jika offline
  Future<void> saveGlucoseWithServerSync(double glucose, String date) async {
    try {
      // Coba push ke server terlebih dahulu
      bool serverSuccess = await sendGlucoseToServer(glucose, date);

      if (serverSuccess) {
        print("✅ Data berhasil dikirim ke server");
      } else {
        print("⚠️ Gagal push ke server, tetap simpan di lokal");
      }

      // Simpan ke lokal (baik server sukses atau gagal)
      // Ini untuk memastikan data tetap tersedia jika offline
      await saveGlucoseDataToHive(glucose, date);

      // Trigger refresh dashboard dari server
      _triggerDashboardReload();
    } catch (e) {
      print("❌ Error sync glucose: $e");
      // Tetap simpan ke lokal walaupun ada error
      await saveGlucoseDataToHive(glucose, date);
    }
  }

  /// Send glucose data to server
  Future<bool> sendGlucoseToServer(double glucose, String date) async {
    try {
      if (token.value.isEmpty) {
        await getToken();
      }

      if (token.value.isEmpty) {
        print('Token tidak tersedia, skip push ke server');
        return false;
      }

      final connect = GetConnect();

      // Convert context dari 'random' karena ini dari device
      String context = 'random'; // Data dari device selalu 'random'

      print('📤 Mengirim data ke server...');
      print(
          'Data: blood_glucose=$glucose, reading_time=$date, context=$context');

      final response = await connect.post(
        '${utilService.url}/api/blood-glucose',
        {
          'blood_glucose': glucose,
          'reading_time': date,
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

  Future<void> saveGlucoseDataToHive(double glucose, String date) async {
    if (Hive.isBoxOpen('glucoseData')) {
      var box = await Hive.openBox('glucoseData');
      List<dynamic> existingData = box.get('GlucoseList', defaultValue: []);
      print('saveGlucoseDataToHive: $date -> $glucose');

      // Format tanggal agar sama seperti data lama
      DateTime parsedDate = DateTime.parse(date);
      String formattedDate =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(parsedDate);

      // Bulatkan nilai glukosa (misal 2 angka di belakang koma)
      double roundedGlucose = double.parse(glucose.toStringAsFixed(2));

      existingData.add({
        'date': formattedDate,
        'blood_glucose': roundedGlucose,
        'context': 'random',
      });

      print(existingData);

      await box.put('GlucoseList', existingData);
    }
  }

  Future<void> saveDeviceToHive(String data) async {
    if (Hive.isBoxOpen('deviceData')) {
      var box = await Hive.openBox('deviceData');
      await box.put('deviceId', data);
    }
  }

  Future<String?> getDeviceFromHive() async {
    var box = await Hive.openBox('deviceData');
    return box.get('deviceId');
  }

  /// ========== AUTO-SYNC MECHANISM ==========

  /// Sync semua data glucose dari device yang belum ter-push ke server
  Future<void> syncPendingDeviceGlucoseData() async {
    try {
      if (token.value.isEmpty) {
        await getToken();
      }

      if (token.value.isEmpty) {
        print('🔒 Token tidak tersedia, skip auto-sync device glucose');
        return;
      }

      if (Hive.isBoxOpen('glucoseData')) {
        var glucoseBox = await Hive.openBox('glucoseData');
        List<dynamic> allData = glucoseBox.get('GlucoseList', defaultValue: []);

        // Filter data yang belum sync dan context 'random' (dari device)
        List<dynamic> pendingData = allData.where((item) {
          bool isNotSynced = item['synced'] == false || item['synced'] == null;
          bool isFromDevice = item['context'] == 'random';
          return isNotSynced && isFromDevice;
        }).toList();

        if (pendingData.isEmpty) {
          print('✅ Tidak ada data glucose device pending untuk di-sync');
          return;
        }

        print(
            '🔄 Menemukan ${pendingData.length} data glucose device yang belum sync');

        int successCount = 0;
        int failedCount = 0;

        for (var data in pendingData) {
          double glucose = double.parse(data['blood_glucose'].toString());
          String date = data['date'];

          print('📤 Mencoba sync device data: $date -> $glucose mg/dL');

          // Coba push ke server
          bool success = await sendGlucoseToServer(glucose, date);

          if (success) {
            await updateDeviceGlucoseSyncStatus(date, true);
            successCount++;
            print('✅ Sync device glucose berhasil: $date');
          } else {
            failedCount++;
            print('❌ Sync device glucose gagal: $date');
          }

          // Delay kecil untuk menghindari rate limiting
          await Future.delayed(const Duration(milliseconds: 300));
        }

        if (successCount > 0) {
          print(
              '🎉 $successCount data glucose dari device berhasil sync ke server');
        }

        if (failedCount > 0) {
          print(
              '⚠️ $failedCount data glucose device gagal sync, akan dicoba lagi nanti');
        }

        print(
            '📊 Device Glucose Sync Summary - Success: $successCount, Failed: $failedCount');
      }
    } catch (e) {
      print('❌ Error saat auto-sync device glucose: $e');
    }
  }

  /// Update synced status for device glucose data
  Future<void> updateDeviceGlucoseSyncStatus(String date, bool synced) async {
    if (Hive.isBoxOpen('glucoseData')) {
      var glucoseBox = await Hive.openBox('glucoseData');
      List<dynamic> existingData =
          glucoseBox.get('GlucoseList', defaultValue: []);

      for (var item in existingData) {
        if (item['date'] == date) {
          item['synced'] = synced;
          break;
        }
      }

      await glucoseBox.put('GlucoseList', existingData);
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

  @override
  void onClose() {
    et570Stream.cancel();
    super.onClose();
  }
}

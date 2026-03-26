import 'package:e_fever_care/view/connect/connect_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:settings_ui/settings_ui.dart';

import '../controller/connect_page_controller.dart';
import '../controller/profile_controller.dart';
import '../controller/settings_page_controller.dart';

class SettingsPage extends GetView<SettingsPageController> {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ProfileController profileController = Get.find<ProfileController>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pengaturan",
            style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Obx(() => IconButton(
            onPressed: controller.isLoadingSettings.value 
                ? null 
                : () => controller.getMealTimeSettings(),
            icon: controller.isLoadingSettings.value
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.teal),
                  )
                : const Icon(Icons.refresh, color: Colors.teal),
          )),
        ],
      ),
      body: Obx(() => SettingsList(
        lightTheme:
        const SettingsThemeData(settingsListBackground: Colors.white),
        sections: [
          SettingsSection(
            title: const Text('Informasi Pribadi'),
            tiles: <SettingsTile>[
              SettingsTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.person, color: Colors.teal, size: 24),
                ),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(() => Text(
                      profileController.name.value.isEmpty ? 'Nama tidak tersedia' : profileController.name.value,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    )),
                    const SizedBox(height: 4),
                    Obx(() => Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            profileController.gender.value == 'male' ? 'Laki-laki' : 
                            profileController.gender.value == 'female' ? 'Perempuan' : '-',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (profileController.age.value.isNotEmpty)
                          Text(
                            '${profileController.age.value} tahun',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    )),
                  ],
                ),
              ),
            ],
          ),
          SettingsSection(
            title: Row(
              children: [
                const Text('Pengaturan Waktu Makan'),
                const Spacer(),
                Obx(() => controller.lastUpdated.value.isNotEmpty
                    ? Text(
                        'Terakhir diperbarui: ${controller.lastUpdated.value}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.normal,
                        ),
                      )
                    : const SizedBox.shrink()),
              ],
            ),
            tiles: <SettingsTile>[
              SettingsTile.navigation(
                leading: const Icon(Icons.bedtime, color: Colors.indigo),
                title: const Text('Jam Mulai Puasa'),
                trailing: Obx(() => Text(
                  controller.fastingStartTime.value,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                )),
                onPressed: (context) {
                  _showTimePickerDialog(
                    context,
                    'Pilih Jam Mulai Puasa',
                    controller.fastingStartTime.value,
                    (selectedTime) {
                      controller.updateFastingStartTime(selectedTime);
                    },
                  );
                },
              ),
              SettingsTile.navigation(
                leading: const Icon(Icons.free_breakfast, color: Colors.orange),
                title: const Text('Jam Sarapan'),
                trailing: Obx(() => Text(
                  controller.breakfastTime.value,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                )),
                onPressed: (context) {
                  _showTimePickerDialog(
                    context,
                    'Pilih Jam Sarapan',
                    controller.breakfastTime.value,
                    (selectedTime) {
                      controller.updateBreakfastTime(selectedTime);
                    },
                  );
                },
              ),
            ],
          ),
          SettingsSection(
            title: const Text('Device'),
            tiles: <SettingsTile>[
              SettingsTile.navigation(
                leading: const Icon(Icons.watch),
                title: const Text('Status Koneksi'),
                trailing: Row(
                  children: [
                    Text(controller.isConnect.value
                        ? 'Terhubung'
                        : 'Terputus'),
                    const Icon(Icons.navigate_next)
                  ],
                ),
                onPressed: (c) {
                  Get.to(() => const ConnectPage());
                },
              ),
              // if (controller.isConnect.value)
              //   SettingsTile.navigation(
              //     leading: const Icon(Icons.water_drop_rounded, color: Colors.teal),
              //     title: const Text('Mulai Ukur Glukosa Manual'),
              //     onPressed: (c) {
              //       Get.defaultDialog(
              //         title: 'Konfirmasi',
              //         middleText: 'Mulai pengukuran glukosa darah secara manual?',
              //         textCancel: 'Batal',
              //         textConfirm: 'Mulai',
              //         confirmTextColor: Colors.white,
              //         buttonColor: Colors.teal,
              //         onConfirm: () {
              //           Get.back();
              //           final connectController = Get.find<ConnectPageController>();
              //           connectController.startGlucoseDetect();
              //           Get.snackbar(
              //             "Sedang Mengukur",
              //             "Jam sedang melakukan pengukuran glukosa...",
              //             margin: const EdgeInsets.all(8),
              //             icon: const Icon(Icons.monitor_heart_rounded, color: Colors.orange),
              //           );
              //         },
              //       );
              //     },
              //   ),
              SettingsTile.navigation(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onPressed: (c) {
                  controller.logout();
                },
              ),
            ],
          ),
        ],
      )),
      resizeToAvoidBottomInset: false,
    );
  }
  
  void _showTimePickerDialog(
    BuildContext context,
    String title,
    String currentTime,
    Function(String) onTimeSelected,
  ) {
    // Parse current time
    final timeParts = currentTime.split(':');
    final currentHour = int.parse(timeParts[0]);
    final currentMinute = int.parse(timeParts[1]);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Waktu saat ini: $currentTime',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              const Text(
                'Tap "Pilih Waktu" untuk mengubah',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final TimeOfDay? picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(hour: currentHour, minute: currentMinute),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: Theme.of(context).colorScheme.copyWith(
                          primary: Colors.teal,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                
                if (picked != null) {
                  final selectedTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                  onTimeSelected(selectedTime);
                  Navigator.of(context).pop();
                  
                  // Show confirmation
                  Get.snackbar(
                    'Berhasil',
                    'Waktu berhasil diperbarui ke $selectedTime',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.teal.withOpacity(0.1),
                    colorText: Colors.teal,
                    icon: const Icon(Icons.check_circle, color: Colors.teal),
                    margin: const EdgeInsets.all(16),
                    borderRadius: 8,
                    duration: const Duration(seconds: 2),
                  );
                }
              },
              child: const Text('Pilih Waktu', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}

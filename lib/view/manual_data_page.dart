import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../controller/manual_data_controller.dart';

class ManualDataPage extends GetView<ManualDataController> {
  const ManualDataPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Data Gula Darah",
          style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.teal),
        actions: [
          // Button untuk manual sync
          IconButton(
            icon: const Icon(Icons.sync, color: Colors.teal),
            tooltip: 'Sinkronkan data',
            onPressed: () {
              controller.manualSyncGlucoseData();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "manual_glucose_fab", // Add unique hero tag
        onPressed: () => _showBloodGlucoseInputDialog(context),
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.teal),
          );
        }

        if (controller.manualDataList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.data_usage_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  "Belum ada data",
                  style: TextStyle(
                    fontSize: 18.sp,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Tap tombol + untuk menambah data",
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Info legend
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.teal.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline,
                          size: 18, color: Colors.teal),
                      const SizedBox(width: 8),
                      Text(
                        'Keterangan:',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.cloud_done,
                          size: 16, color: Colors.teal),
                      const SizedBox(width: 6),
                      Text('Tersinkron', style: TextStyle(fontSize: 12.sp)),
                      const SizedBox(width: 16),
                      const Icon(Icons.cloud_off,
                          size: 16, color: Colors.orange),
                      const SizedBox(width: 6),
                      Text('Belum tersinkron',
                          style: TextStyle(fontSize: 12.sp)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.blue, width: 1),
                        ),
                        child: Text(
                          'Alat',
                          style: TextStyle(
                              fontSize: 10.sp,
                              color: Colors.blue,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('Data dari device',
                          style: TextStyle(fontSize: 12.sp)),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.grey, width: 1),
                        ),
                        child: Text(
                          'Manual',
                          style: TextStyle(
                              fontSize: 10.sp,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('Input manual', style: TextStyle(fontSize: 12.sp)),
                    ],
                  ),
                ],
              ),
            ),
            // List data
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: controller.manualDataList.length,
                itemBuilder: (context, index) {
                  final data = controller.manualDataList[index];
                  final glucose = data['blood_glucose'];
                  final bool isSynced = data['synced'] ?? false;
                  final String source = data['source'] ?? 'manual';

                  Color glucoseColor = Colors.green;

                  if (glucose > 130) {
                    glucoseColor = Colors.red;
                  } else if (glucose < 70) {
                    glucoseColor = Colors.purple;
                  }

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: glucoseColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Icon(
                          Icons.bloodtype,
                          color: glucoseColor,
                          size: 28,
                        ),
                      ),
                      title: Row(
                        children: [
                          Text(
                            "${glucose.toStringAsFixed(1)} mg/dL",
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: glucoseColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Icon status sync
                          Icon(
                            isSynced ? Icons.cloud_done : Icons.cloud_off,
                            size: 18,
                            color: isSynced ? Colors.teal : Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          // Badge source (manual/device)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: source == 'device'
                                  ? Colors.blue.withOpacity(0.1)
                                  : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: source == 'device'
                                    ? Colors.blue
                                    : Colors.grey,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              source == 'device' ? 'Alat' : 'Manual',
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: source == 'device'
                                    ? Colors.blue
                                    : Colors.grey[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            data['formatted_date'],
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (data['meal_time'] != null &&
                              data['meal_time'].isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.restaurant,
                                    size: 14,
                                    color: Colors.teal,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    data['meal_time'],
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: Colors.teal,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          // Status sync text
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              isSynced
                                  ? 'Tersinkron ke server'
                                  : 'Belum tersinkron',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: isSynced ? Colors.teal : Colors.orange,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      }),
    );
  }

  void _showBloodGlucoseInputDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    final _dropdownKey = GlobalKey<FormFieldState>();
    final TextEditingController glucoseController = TextEditingController();
    final TextEditingController timeController = TextEditingController();
    String? selectedMealTime;
    timeController.text = DateTime.now().toString().substring(0, 19);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.bloodtype, color: Colors.teal, size: 28),
                      SizedBox(width: 8),
                      Text('Tambah Data',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Masukkan nilai gula darah, waktu makan, dan konfirmasi waktu pengukuran.',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.8,
                    maxHeight: MediaQuery.of(context).size.height * 0.6,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: glucoseController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            labelText: 'Nilai Gula Darah',
                            suffixText: 'mg/dL',
                            prefixIcon: const Icon(Icons.monitor_heart,
                                color: Colors.teal),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.teal.withOpacity(0.06),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Nilai gula darah wajib diisi';
                            }
                            final num? val = num.tryParse(value);
                            if (val == null) {
                              return 'Masukkan angka yang valid';
                            }
                            if (val < 0) {
                              return 'Tidak boleh kurang dari 0';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        DropdownButtonFormField<String>(
                          key: _dropdownKey,
                          value: selectedMealTime,
                          decoration: InputDecoration(
                            labelText: 'Waktu Makan',
                            prefixIcon: const Icon(Icons.restaurant,
                                color: Colors.teal),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.teal.withOpacity(0.06),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'Sebelum sarapan',
                                child: Text('Sebelum sarapan')),
                            DropdownMenuItem(
                                value: 'Setelah sarapan',
                                child: Text('Setelah sarapan')),
                            DropdownMenuItem(
                                value: 'Sewaktu', child: Text('Sewaktu')),
                          ],
                          onChanged: (value) {
                            if (value == 'Sebelum sarapan') {
                              _showMealTimeConfirmation(
                                context,
                                'Konfirmasi Sebelum Sarapan',
                                'Apakah sudah puasa selama 10 jam?',
                                () {
                                  setState(() {
                                    selectedMealTime = value;
                                  });
                                },
                                () {
                                  // Reset dropdown ke null jika tidak dikonfirmasi
                                  setState(() {
                                    selectedMealTime = null;
                                  });
                                  _dropdownKey.currentState?.reset();
                                },
                              );
                            } else if (value == 'Setelah sarapan') {
                              _showMealTimeConfirmation(
                                context,
                                'Konfirmasi Setelah Sarapan',
                                'Apakah sudah 1 jam setelah sarapan?',
                                () {
                                  setState(() {
                                    selectedMealTime = value;
                                  });
                                },
                                () {
                                  // Reset dropdown ke null jika tidak dikonfirmasi
                                  setState(() {
                                    selectedMealTime = null;
                                  });
                                  _dropdownKey.currentState?.reset();
                                },
                              );
                            } else {
                              setState(() {
                                selectedMealTime = value;
                              });
                            }
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Waktu makan wajib dipilih';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        TextFormField(
                          controller: timeController,
                          readOnly: true,
                          enabled: false,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.grey),
                          decoration: InputDecoration(
                            labelText: 'Waktu Pengukuran (Sekarang)',
                            prefixIcon: const Icon(Icons.access_time,
                                color: Colors.grey),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.grey.withOpacity(0.1),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Batal'),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                    ),
                    icon: const Icon(Icons.save, color: Colors.white),
                    label: const Text('Simpan',
                        style: TextStyle(color: Colors.white)),
                    onPressed: () {
                      if (_formKey.currentState?.validate() ?? false) {
                        controller.addManualGlucoseData(
                          glucoseController.text,
                          timeController.text,
                          selectedMealTime!,
                        );
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showMealTimeConfirmation(BuildContext context, String title,
      String message, VoidCallback onConfirm,
      [VoidCallback? onCancel]) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(
            title,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.teal),
          ),
          content: Text(
            message,
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog konfirmasi
                // Panggil onCancel jika ada
                if (onCancel != null) {
                  onCancel();
                }
              },
              child: const Text('Belum', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog konfirmasi
                onConfirm(); // Set selectedMealTime
              },
              child: const Text('Ya, Sudah',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}

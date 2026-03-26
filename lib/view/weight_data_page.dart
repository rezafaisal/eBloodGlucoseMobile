import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../controller/weight_controller.dart';

class WeightDataPage extends GetView<WeightController> {
  const WeightDataPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Ensure WeightController is initialized
    Get.put(WeightController());

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Data Berat Badan",
          style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.teal),
        actions: [
          // Manual sync button
          IconButton(
            icon: const Icon(Icons.sync, color: Colors.teal),
            tooltip: 'Sinkronkan data',
            onPressed: () {
              controller.manualSyncWeightData();
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'refresh') {
                controller.refreshWeightData();
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
      floatingActionButton: FloatingActionButton(
        heroTag: "weight_fab", // Add unique hero tag
        onPressed: () => _showWeightInputDialog(context),
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.teal),
          );
        }

        if (controller.weightDataList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.scale_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  "Belum ada data berat badan",
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
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 18, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    'Keterangan:',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.cloud_done, size: 16, color: Colors.teal),
                  const SizedBox(width: 6),
                  Text('Tersinkron', style: TextStyle(fontSize: 12.sp)),
                  const SizedBox(width: 12),
                  const Icon(Icons.cloud_off, size: 16, color: Colors.orange),
                  const SizedBox(width: 6),
                  Text('Belum tersinkron', style: TextStyle(fontSize: 12.sp)),
                ],
              ),
            ),
            // List data
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: controller.weightDataList.length,
                itemBuilder: (context, index) {
                  final data = controller.weightDataList[index];
                  final weight = data['weight'];
                  final bool isSynced = data['synced'] ?? false;

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
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: const Icon(
                          Icons.scale,
                          color: Colors.blue,
                          size: 28,
                        ),
                      ),
                      title: Row(
                        children: [
                          Text(
                            "${weight.toStringAsFixed(1)} kg",
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Icon status sync
                          Icon(
                            isSynced ? Icons.cloud_done : Icons.cloud_off,
                            size: 18,
                            color: isSynced ? Colors.teal : Colors.orange,
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

  void _showWeightInputDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    final TextEditingController weightController = TextEditingController();
    final TextEditingController timeController = TextEditingController();
    timeController.text = DateTime.now().toString().substring(0, 19);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.scale, color: Colors.blue, size: 28),
                  SizedBox(width: 8),
                  Text('Tambah Data',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Masukkan berat badan Anda saat ini.',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ],
          ),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: weightController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: 'Berat Badan',
                    suffixText: 'kg',
                    prefixIcon: const Icon(Icons.scale, color: Colors.blue),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.blue.withOpacity(0.06),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Berat badan wajib diisi';
                    }
                    final num? val = num.tryParse(value);
                    if (val == null) {
                      return 'Masukkan angka yang valid';
                    }
                    if (val <= 0) {
                      return 'Berat badan harus lebih dari 0';
                    }
                    if (val > 300) {
                      return 'Berat badan tidak valid';
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
                    labelText: 'Waktu Pencatatan (Sekarang)',
                    prefixIcon:
                        const Icon(Icons.access_time, color: Colors.grey),
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
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                ),
                icon: const Icon(Icons.save, color: Colors.white),
                label:
                    const Text('Simpan', style: TextStyle(color: Colors.white)),
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    controller.addWeightData(
                      weightController.text,
                      timeController.text,
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
  }
}

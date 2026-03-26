import 'package:e_fever_care/view/widgets/blood_sugar_history_chart.dart';
import 'package:e_fever_care/view/widgets/weight_line_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../controller/history_page_controller.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> with WidgetsBindingObserver {
  late HistoryPageController controller;
  bool _hasRefreshed = false;

  @override
  void initState() {
    super.initState();
    controller = Get.find<HistoryPageController>();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App resumed, mark for refresh
      controller.markForRefresh();
      _hasRefreshed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Refresh data only once when this page is displayed
    if (!_hasRefreshed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.refreshCurrentData();
        _hasRefreshed = true;
      });
    }

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text("Riwayat",
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Blood Sugar History Section - Card format (consistent with weight section)
            Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card Header with navigation
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(
                          "Riwayat Gula Darah",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Monthly Navigation
                        Obx(() => Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  icon:
                                      const Icon(Icons.chevron_left, size: 24),
                                  color:
                                      controller.canGoPreviousBloodSugarMonth()
                                          ? Colors.teal
                                          : Colors.grey[300],
                                  onPressed: controller
                                          .canGoPreviousBloodSugarMonth()
                                      ? () =>
                                          controller.previousBloodSugarMonth()
                                      : null,
                                ),
                                Column(
                                  children: [
                                    Text(
                                      controller
                                          .getCurrentBloodSugarMonthLabel(),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.teal,
                                      ),
                                    ),
                                    Obx(() {
                                      final stats = controller.bloodSugarStats;
                                      final count = stats['count'] ?? 0;
                                      if (count > 0) {
                                        return Container(
                                          margin: const EdgeInsets.only(top: 4),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.teal.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            'Total: $count pembacaan',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.teal,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    }),
                                  ],
                                ),
                                IconButton(
                                  icon:
                                      const Icon(Icons.chevron_right, size: 24),
                                  color: controller.canGoNextBloodSugarMonth()
                                      ? Colors.teal
                                      : Colors.grey[300],
                                  onPressed: controller
                                          .canGoNextBloodSugarMonth()
                                      ? () => controller.nextBloodSugarMonth()
                                      : null,
                                ),
                              ],
                            )),
                      ],
                    ),
                  ),

                  // Divider
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: Colors.grey[200],
                  ),

                  // Blood Sugar Chart - Professional medical style
                  Obx(() {
                    if (controller.isLoadingBloodSugarHistory.value) {
                      return Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 20.0, vertical: 40.0),
                        child: const Center(
                          child: Column(
                            children: [
                              CircularProgressIndicator(color: Colors.teal),
                              SizedBox(height: 16),
                              Text(
                                'Memuat data gula darah...',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      );
                    } else if (controller.bloodSugarHistorySpots.isNotEmpty) {
                      return BloodSugarHistoryChart(
                        bloodSugarSpots: controller.bloodSugarHistorySpots,
                        dates: controller.bloodSugarHistoryDates,
                        rawData: controller.bloodSugarHistoryRawData,
                      );
                    } else {
                      return Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 20.0, vertical: 10.0),
                        padding: const EdgeInsets.all(40.0),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(18.0),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.bloodtype_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Belum Ada Data Gula Darah',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Untuk bulan ${controller.getCurrentBloodSugarMonthLabel()}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  }),

                  // Divider before statistics
                  // Divider(
                  //   height: 1,
                  //   thickness: 1,
                  //   color: Colors.grey[200],
                  // ),

                  // Blood Sugar Statistics - part of the same card with proper spacing
                  // Padding(
                  //   padding: const EdgeInsets.all(20),
                  //   child: Obx(() {
                  //     final stats = controller.bloodSugarStats;
                  //     final average = stats['average'] ?? 0.0;
                  //     final min = stats['min'] ?? 0.0;
                  //     final max = stats['max'] ?? 0.0;

                  //     return Column(
                  //       children: [
                  //         Text(
                  //           "Statistik Bulanan",
                  //           style: TextStyle(
                  //             fontSize: 14,
                  //             fontWeight: FontWeight.w600,
                  //             color: Colors.teal,
                  //           ),
                  //         ),
                  //         const SizedBox(height: 16),
                  //         Row(
                  //           mainAxisAlignment: MainAxisAlignment.spaceAround,
                  //           children: [
                  //             _buildStatItem(
                  //               Icons.trending_up,
                  //               max.toStringAsFixed(0),
                  //               'Tertinggi',
                  //               Colors.red,
                  //             ),
                  //             _buildStatItem(
                  //               Icons.analytics,
                  //               average.toStringAsFixed(0),
                  //               'Rata-Rata',
                  //               Colors.green,
                  //             ),
                  //             _buildStatItem(
                  //               Icons.trending_down,
                  //               min.toStringAsFixed(0),
                  //               'Terendah',
                  //               Colors.blue,
                  //             ),
                  //           ],
                  //         ),
                  //       ],
                  //     );
                  //   }),
                  // ),
                ],
              ),
            ),

            // Gap between sections
            Container(
              height: 20,
              color: Colors.grey[200],
            ),

            // Weight History Section - Card format
            Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card Header with navigation
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(
                          "Riwayat Berat Badan",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Monthly Navigation
                        Obx(() => Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  icon:
                                      const Icon(Icons.chevron_left, size: 24),
                                  color: controller.canGoPreviousWeightMonth()
                                      ? Colors.teal
                                      : Colors.grey[300],
                                  onPressed: controller
                                          .canGoPreviousWeightMonth()
                                      ? () => controller.previousWeightMonth()
                                      : null,
                                ),
                                Column(
                                  children: [
                                    Text(
                                      controller.getCurrentWeightMonthLabel(),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.teal,
                                      ),
                                    ),
                                    if (controller.weightChange.value != '0')
                                      Container(
                                        margin: const EdgeInsets.only(top: 4),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.teal.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          'Perubahan: ${controller.weightChange.value} kg',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.teal,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                IconButton(
                                  icon:
                                      const Icon(Icons.chevron_right, size: 24),
                                  color: controller.canGoNextWeightMonth()
                                      ? Colors.teal
                                      : Colors.grey[300],
                                  onPressed: controller.canGoNextWeightMonth()
                                      ? () => controller.nextWeightMonth()
                                      : null,
                                ),
                              ],
                            )),
                      ],
                    ),
                  ),

                  // Divider
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: Colors.grey[200],
                  ),

                  // Weight Chart - Professional medical style
                  Obx(() {
                    if (controller.isLoadingWeightData.value) {
                      return Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 20.0, vertical: 40.0),
                        child: const Center(
                          child: Column(
                            children: [
                              CircularProgressIndicator(color: Colors.teal),
                              SizedBox(height: 16),
                              Text(
                                'Memuat data berat badan...',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      );
                    } else if (controller.weightSpots.isNotEmpty) {
                      return WeightLineChart(
                          weightSpots: controller.weightSpots);
                    } else {
                      return Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 20.0, vertical: 10.0),
                        padding: const EdgeInsets.all(40.0),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(18.0),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.monitor_weight_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Belum Ada Data Berat Badan',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Untuk bulan ${controller.getCurrentWeightMonthLabel()}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
      resizeToAvoidBottomInset: false,
    );
  }

  Widget _buildStatItem(
      IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class Summary90DayCard extends StatelessWidget {
  final int normalCount;
  final int lowCount;
  final int highCount;
  final int totalCount;

  const Summary90DayCard({
    Key? key,
    required this.normalCount,
    required this.lowCount,
    required this.highCount,
    required this.totalCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Hitung persentase
    double normalPercent = totalCount > 0 ? normalCount / totalCount : 0;
    double lowPercent = totalCount > 0 ? lowCount / totalCount : 0;
    double highPercent = totalCount > 0 ? highCount / totalCount : 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 4,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ringkasan 90 Hari',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Total: $totalCount pembacaan',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 16),

            // Progress bar
            Container(
              height: 12,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: Colors.grey[200],
              ),
              child: Row(
                children: [
                  // Bagian rendah (ungu)
                  if (lowPercent > 0)
                    Expanded(
                      flex: (lowPercent * 100).round(),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.purple,
                          borderRadius: BorderRadius.horizontal(
                            left: Radius.circular(6),
                          ),
                        ),
                      ),
                    ),
                  // Bagian normal (hijau)
                  if (normalPercent > 0)
                    Expanded(
                      flex: (normalPercent * 100).round(),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: lowPercent == 0 && highPercent == 0
                              ? BorderRadius.circular(6)
                              : lowPercent == 0
                                  ? BorderRadius.horizontal(
                                      left: Radius.circular(6))
                                  : highPercent == 0
                                      ? BorderRadius.horizontal(
                                          right: Radius.circular(6))
                                      : BorderRadius.zero,
                        ),
                      ),
                    ),
                  // Bagian tinggi (merah)
                  if (highPercent > 0)
                    Expanded(
                      flex: (highPercent * 100).round(),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.horizontal(
                            right: Radius.circular(6),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLegendItem(
                  'Rendah',
                  lowCount,
                  Colors.purple,
                  totalCount > 0
                      ? (lowPercent * 100).toStringAsFixed(1) + '%'
                      : '0%',
                ),
                _buildLegendItem(
                  'Normal',
                  normalCount,
                  Colors.green,
                  totalCount > 0
                      ? (normalPercent * 100).toStringAsFixed(1) + '%'
                      : '0%',
                ),
                _buildLegendItem(
                  'Tinggi',
                  highCount,
                  Colors.red,
                  totalCount > 0
                      ? (highPercent * 100).toStringAsFixed(1) + '%'
                      : '0%',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(
      String label, int count, Color color, String percentage) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        SizedBox(height: 4),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          percentage,
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

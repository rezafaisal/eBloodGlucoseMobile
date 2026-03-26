import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BloodSugarHistoryChart extends StatelessWidget {
  final List<FlSpot> bloodSugarSpots;
  final List<DateTime> dates; // Add dates for proper X-axis labels
  final List<Map<String, dynamic>> rawData; // Add raw data for tooltip

  const BloodSugarHistoryChart({
    Key? key,
    required this.bloodSugarSpots,
    this.dates = const [],
    this.rawData = const [],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (bloodSugarSpots.isEmpty) {
      return Container(
        height: 300,
        margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(18.0),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bloodtype_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Belum Ada Data Gula Darah',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Data akan tampil di sini setelah tersedia',
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

    return Padding(
      padding: const EdgeInsets.only(
          left: 20.0, right: 20.0, top: 10.0, bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and average
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Gula Darah (mg/dL)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _calculateAverage().toStringAsFixed(0),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                  const Text(
                    'Rata-rata bulan ini',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Statistics Row - Overall summary
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                // Overall stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildCompactStatItem(
                        'Tertinggi', _getMaxBloodSugar(), Colors.red.shade600),
                    Container(
                      width: 1,
                      height: 30,
                      color: Colors.grey.shade300,
                    ),
                    _buildCompactStatItem(
                        'Rata-rata', _calculateAverage(), Colors.teal.shade600),
                    Container(
                      width: 1,
                      height: 30,
                      color: Colors.grey.shade300,
                    ),
                    _buildCompactStatItem(
                        'Terendah', _getMinBloodSugar(), Colors.blue.shade600),
                  ],
                ),

                const SizedBox(height: 12),

                // Divider
                Divider(height: 1, color: Colors.grey.shade300),

                const SizedBox(height: 8),

                // Header for breakdown section
                Text(
                  'Rata-rata Per Tipe Pengukuran',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 10),

                // Breakdown by meal type
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMealTypeAverage('Sebelum Makan', Colors.red.shade400),
                    _buildMealTypeAverage(
                        'Sesudah Makan', Colors.blue.shade400),
                    _buildMealTypeAverage('Lainnya', Colors.green.shade400),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Chart with horizontal scroll
          SizedBox(
            height: 400, // Increased height for better readability
            child: LayoutBuilder(
              builder: (context, constraints) {
                double chartWidth = _getChartWidth();
                // Use the larger of: calculated chart width OR parent width
                // This ensures chart fills parent on large screens, but can scroll on small screens
                double finalWidth = chartWidth > constraints.maxWidth
                    ? chartWidth
                    : constraints.maxWidth;

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Container(
                    width: finalWidth,
                    padding: const EdgeInsets.only(
                        top: 24.0,
                        left: 8.0,
                        right: 24.0,
                        bottom: 5.0), // More compact padding
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50, // Teal background
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: LineChart(
                      _buildLineChartData(),
                      duration: const Duration(milliseconds: 150),
                      curve: Curves.linear,
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Legend untuk tipe pengukuran
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 24, // Increased spacing between legend items
            runSpacing: 12, // Increased vertical spacing
            children: [
              _buildLegendItem('Sebelum Sarapan', Colors.red.shade400),
              _buildLegendItem('Sesudah Sarapan', Colors.blue.shade400),
              _buildLegendItem('Lainnya', Colors.green.shade400),
            ],
          ),

          const SizedBox(height: 12),

          // Info text with scroll hint
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.swipe_left,
                size: 14,
                color: Colors.grey[500],
              ),
              const SizedBox(width: 4),
              Text(
                'Geser untuk melihat data lengkap',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatItem(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.toStringAsFixed(0),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          'mg/dL',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildMealTypeAverage(String label, Color color) {
    double average = _getAverageByMealType(label);
    int count = _getCountByMealType(label);

    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            average > 0 ? average.toStringAsFixed(0) : '-',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: average > 0 ? color : Colors.grey[400],
            ),
          ),
          if (average > 0) ...[
            Text(
              'mg/dL',
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count hari',
                style: TextStyle(
                  fontSize: 9,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // Get chart width based on number of days in month
  double _getChartWidth() {
    int daysInMonth = _getDaysInMonth();

    // Width per day - increased for better spacing between dates
    double widthPerDay = 35.0;
    return daysInMonth * widthPerDay;
  } // Get actual number of days in the current month

  int _getDaysInMonth() {
    if (rawData.isNotEmpty && rawData.length > 1) {
      for (int i = 1; i < rawData.length; i++) {
        if (rawData[i]['date'] != null) {
          DateTime date = DateTime.parse(rawData[i]['date']);
          return DateTime(date.year, date.month + 1, 0).day;
        }
      }
    }
    return 31; // Default
  }

  // Get month name for bottom titles
  String _getMonthName() {
    if (rawData.isNotEmpty && rawData.length > 1) {
      for (int i = 1; i < rawData.length; i++) {
        if (rawData[i]['date'] != null) {
          DateTime date = DateTime.parse(rawData[i]['date']);
          try {
            return DateFormat('MMM', 'id_ID').format(date);
          } catch (e) {
            return DateFormat('MMM', 'en_US').format(date);
          }
        }
      }
    }
    return 'Okt'; // Default
  }

  // Get average by meal type
  double _getAverageByMealType(String mealType) {
    if (rawData.isEmpty || rawData.length < 2) return 0.0;

    double sum = 0.0;
    int count = 0;
    String fieldName = '';

    // Map label to field name
    if (mealType == 'Sebelum Makan') {
      fieldName = 'beforeBreakfast';
    } else if (mealType == 'Sesudah Makan') {
      fieldName = 'afterBreakfast';
    } else if (mealType == 'Lainnya') {
      fieldName = 'other';
    }

    // Skip first element which contains mealTypeSpots
    for (int i = 1; i < rawData.length; i++) {
      var data = rawData[i];

      if (data[fieldName] != null && data[fieldName]['avg'] != null) {
        sum += (data[fieldName]['avg'] is int)
            ? (data[fieldName]['avg'] as int).toDouble()
            : data[fieldName]['avg'];
        count++;
      }
    }

    return count > 0 ? sum / count : 0.0;
  }

  // Get count of days with data by meal type
  int _getCountByMealType(String mealType) {
    if (rawData.isEmpty || rawData.length < 2) return 0;

    int count = 0;
    String fieldName = '';

    // Map label to field name
    if (mealType == 'Sebelum Makan') {
      fieldName = 'beforeBreakfast';
    } else if (mealType == 'Sesudah Makan') {
      fieldName = 'afterBreakfast';
    } else if (mealType == 'Lainnya') {
      fieldName = 'other';
    }

    // Skip first element which contains mealTypeSpots
    for (int i = 1; i < rawData.length; i++) {
      var data = rawData[i];

      if (data[fieldName] != null && data[fieldName]['avg'] != null) {
        count++;
      }
    }

    return count;
  }

  double _calculateAverage() {
    if (rawData.isEmpty || rawData.length < 2) return 0.0;

    // Skip first element which contains mealTypeSpots
    double sum = 0.0;
    int count = 0;

    for (int i = 1; i < rawData.length; i++) {
      var data = rawData[i];

      // Calculate average from all meal types
      if (data['beforeBreakfast'] != null &&
          data['beforeBreakfast']['avg'] != null) {
        sum += (data['beforeBreakfast']['avg'] is int)
            ? (data['beforeBreakfast']['avg'] as int).toDouble()
            : data['beforeBreakfast']['avg'];
        count++;
      }
      if (data['afterBreakfast'] != null &&
          data['afterBreakfast']['avg'] != null) {
        sum += (data['afterBreakfast']['avg'] is int)
            ? (data['afterBreakfast']['avg'] as int).toDouble()
            : data['afterBreakfast']['avg'];
        count++;
      }
      if (data['other'] != null && data['other']['avg'] != null) {
        sum += (data['other']['avg'] is int)
            ? (data['other']['avg'] as int).toDouble()
            : data['other']['avg'];
        count++;
      }
    }

    return count > 0 ? sum / count : 0.0;
  }

  double _getMaxBloodSugar() {
    if (rawData.isEmpty || rawData.length < 2) return 0.0;

    double maxValue = 0.0;

    // Skip first element which contains mealTypeSpots
    for (int i = 1; i < rawData.length; i++) {
      var data = rawData[i];

      // Check all meal types for max
      if (data['beforeBreakfast'] != null &&
          data['beforeBreakfast']['max'] != null) {
        double dayMax = (data['beforeBreakfast']['max'] is int)
            ? (data['beforeBreakfast']['max'] as int).toDouble()
            : data['beforeBreakfast']['max'];
        if (dayMax > maxValue) maxValue = dayMax;
      }
      if (data['afterBreakfast'] != null &&
          data['afterBreakfast']['max'] != null) {
        double dayMax = (data['afterBreakfast']['max'] is int)
            ? (data['afterBreakfast']['max'] as int).toDouble()
            : data['afterBreakfast']['max'];
        if (dayMax > maxValue) maxValue = dayMax;
      }
      if (data['other'] != null && data['other']['max'] != null) {
        double dayMax = (data['other']['max'] is int)
            ? (data['other']['max'] as int).toDouble()
            : data['other']['max'];
        if (dayMax > maxValue) maxValue = dayMax;
      }
    }

    return maxValue;
  }

  double _getMinBloodSugar() {
    if (rawData.isEmpty || rawData.length < 2) return 0.0;

    double minValue = double.infinity;

    // Skip first element which contains mealTypeSpots
    for (int i = 1; i < rawData.length; i++) {
      var data = rawData[i];

      // Check all meal types for min
      if (data['beforeBreakfast'] != null &&
          data['beforeBreakfast']['min'] != null) {
        double dayMin = (data['beforeBreakfast']['min'] is int)
            ? (data['beforeBreakfast']['min'] as int).toDouble()
            : data['beforeBreakfast']['min'];
        if (dayMin < minValue && dayMin > 0) minValue = dayMin;
      }
      if (data['afterBreakfast'] != null &&
          data['afterBreakfast']['min'] != null) {
        double dayMin = (data['afterBreakfast']['min'] is int)
            ? (data['afterBreakfast']['min'] as int).toDouble()
            : data['afterBreakfast']['min'];
        if (dayMin < minValue && dayMin > 0) minValue = dayMin;
      }
      if (data['other'] != null && data['other']['min'] != null) {
        double dayMin = (data['other']['min'] is int)
            ? (data['other']['min'] as int).toDouble()
            : data['other']['min'];
        if (dayMin < minValue && dayMin > 0) minValue = dayMin;
      }
    }

    return minValue == double.infinity ? 0.0 : minValue;
  }

  LineChartData _buildLineChartData() {
    // Get actual number of days in the month from data
    int daysInMonth = _getDaysInMonth();

    // Use actual days for the month range
    double minX = 1; // Day 1
    double maxX = daysInMonth.toDouble(); // Actual last day of month

    // Fixed Y-axis range for blood sugar (50-300 mg/dL as per endpoint limit)
    double minY = 50.0; // Fixed minimum from endpoint
    double maxY = 300.0; // Fixed maximum from endpoint

    // Extract meal type spots from rawData
    List<FlSpot> beforeBreakfastSpots = [];
    List<FlSpot> afterBreakfastSpots = [];
    List<FlSpot> otherSpots = [];

    if (rawData.isNotEmpty && rawData[0]['mealTypeSpots'] != null) {
      var mealTypeSpots = rawData[0]['mealTypeSpots'];
      beforeBreakfastSpots =
          List<FlSpot>.from(mealTypeSpots['beforeBreakfast'] ?? []);
      afterBreakfastSpots =
          List<FlSpot>.from(mealTypeSpots['afterBreakfast'] ?? []);
      otherSpots = List<FlSpot>.from(mealTypeSpots['other'] ?? []);
    }

    return LineChartData(
      minX: minX,
      maxX: maxX,
      minY: minY,
      maxY: maxY,
      titlesData: FlTitlesData(
        show: true,
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 45, // Reduced for compact display
            interval: 1, // Show every day
            getTitlesWidget: _bottomTitleWidgets,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 25, // Fixed interval of 25 mg/dL
            getTitlesWidget: _leftTitleWidgets,
            reservedSize: 42, // Slightly increased for better spacing
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        drawHorizontalLine: true,
        horizontalInterval: 25, // Fixed interval of 25 mg/dL for grid lines
        verticalInterval: 1, // Show grid every day
        getDrawingHorizontalLine: (value) => FlLine(
          color: Colors.grey.withOpacity(0.2),
          strokeWidth: 1,
        ),
        getDrawingVerticalLine: (value) => FlLine(
          color: Colors.grey.withOpacity(0.1),
          strokeWidth: 0.5,
        ),
      ),
      lineBarsData: [
        // Sebelum Sarapan (Red) - only dots, no lines
        if (beforeBreakfastSpots.isNotEmpty)
          LineChartBarData(
            spots: beforeBreakfastSpots,
            isCurved: false,
            color: Colors.red.shade400,
            barWidth: 0, // No line, only dots
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                radius: 5,
                color: Colors.red.shade400,
                strokeWidth: 0,
              ),
            ),
            belowBarData: BarAreaData(show: false),
          ),

        // Sesudah Sarapan (Blue) - only dots, no lines
        if (afterBreakfastSpots.isNotEmpty)
          LineChartBarData(
            spots: afterBreakfastSpots,
            isCurved: false,
            color: Colors.blue.shade400,
            barWidth: 0, // No line, only dots
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                radius: 5,
                color: Colors.blue.shade400,
                strokeWidth: 0,
              ),
            ),
            belowBarData: BarAreaData(show: false),
          ),

        // Lainnya (Green) - only dots, no lines
        if (otherSpots.isNotEmpty)
          LineChartBarData(
            spots: otherSpots,
            isCurved: false,
            color: Colors.green.shade400,
            barWidth: 0, // No line, only dots
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                radius: 5,
                color: Colors.green.shade400,
                strokeWidth: 0,
              ),
            ),
            belowBarData: BarAreaData(show: false),
          ),
      ],
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          tooltipBgColor: Colors.teal.shade700,
          tooltipRoundedRadius: 8,
          tooltipPadding: const EdgeInsets.all(12),
          tooltipMargin: 8,
          fitInsideHorizontally: true,
          fitInsideVertically: true,
          maxContentWidth: 220,
          getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
            return touchedBarSpots.map((barSpot) {
              final flSpot = barSpot;
              int day = flSpot.x.round();

              // Determine meal type from bar data index
              String mealType = '';

              if (barSpot.barIndex == 0) {
                mealType = 'Sebelum Sarapan';
              } else if (barSpot.barIndex == 1) {
                mealType = 'Sesudah Sarapan';
              } else if (barSpot.barIndex == 2) {
                mealType = 'Lainnya';
              }

              // Find the corresponding raw data for this day and meal type
              String dateText = 'Tanggal $day';
              double avgValue = flSpot.y;
              double minValue = 0;
              double maxValue = 0;
              int count = 0;

              // Search for matching data in rawData (skip first element with mealTypeSpots)
              for (int i = 1; i < rawData.length; i++) {
                var data = rawData[i];
                if (data['date'] != null) {
                  DateTime dataDate = DateTime.parse(data['date']);
                  if (dataDate.day == day) {
                    dateText = DateFormat('dd MMM').format(dataDate);

                    // Get data for the specific meal type
                    Map<String, dynamic>? mealData;
                    if (barSpot.barIndex == 0 &&
                        data['beforeBreakfast'] != null) {
                      mealData = data['beforeBreakfast'];
                    } else if (barSpot.barIndex == 1 &&
                        data['afterBreakfast'] != null) {
                      mealData = data['afterBreakfast'];
                    } else if (barSpot.barIndex == 2 && data['other'] != null) {
                      mealData = data['other'];
                    }

                    if (mealData != null) {
                      minValue = (mealData['min'] is int)
                          ? (mealData['min'] as int).toDouble()
                          : (mealData['min'] ?? 0);
                      maxValue = (mealData['max'] is int)
                          ? (mealData['max'] as int).toDouble()
                          : (mealData['max'] ?? 0);
                      count = mealData['count'] ?? 0;
                    }
                    break;
                  }
                }
              }

              return LineTooltipItem(
                '$dateText\n$mealType\nRata-rata: ${avgValue.round()} mg/dL\nMin: ${minValue.round()} mg/dL\nMax: ${maxValue.round()} mg/dL\nJumlah: ${count}x',
                TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                  height: 1.3,
                ),
              );
            }).toList();
          },
        ),
        touchSpotThreshold: 20,
        getTouchedSpotIndicator:
            (LineChartBarData barData, List<int> spotIndexes) {
          return spotIndexes.map((spotIndex) {
            Color indicatorColor = Colors.teal;

            // Use the same color as the dot
            if (barData.color != null) {
              indicatorColor = barData.color!;
            }

            return TouchedSpotIndicatorData(
              FlLine(
                color: indicatorColor.withOpacity(0.5),
                strokeWidth: 2,
                dashArray: [5, 5],
              ),
              FlDotData(
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                  radius: 7, // Slightly larger when touched
                  color: indicatorColor,
                  strokeWidth: 3,
                  strokeColor: Colors.white,
                ),
              ),
            );
          }).toList();
        },
      ),
    );
  }

  Widget _bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.w500,
      fontSize: 8, // Smaller font for compact display
      color: Colors.black87,
    );

    int day = value.toInt();
    int daysInMonth = _getDaysInMonth();

    // Only show days that exist in the current month
    if (day >= 1 && day <= daysInMonth) {
      String monthName = _getMonthName();
      String text = '$day $monthName';

      return SideTitleWidget(
        axisSide: meta.axisSide,
        child: Padding(
          padding: const EdgeInsets.only(top: 6), // Reduced padding
          child: Transform.rotate(
            angle: -0.5, // Slight angle for better readability
            child: Text(text, style: style),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.w500,
      fontSize: 10,
      color: Colors.black87,
    );

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text('${value.toInt()}', style: style),
    );
  }
}

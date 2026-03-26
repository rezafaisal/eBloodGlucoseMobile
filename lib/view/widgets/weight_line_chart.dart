import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class WeightLineChart extends StatelessWidget {
  final List<FlSpot> weightSpots;
  final double? maxY;
  final double? minY;

  const WeightLineChart({
    Key? key,
    required this.weightSpots,
    this.maxY,
    this.minY,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18.0),
      ),
      color: Colors.white,
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and average
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Berat Badan (kg)',
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
                      _calculateAverage().toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    const Text(
                      'Rata-rata 30 hari',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16), // Reduced spacing

            // Statistics Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Tertinggi', _getMaxWeight(), Colors.black87),
                _buildStatItem(
                    'Rata-rata', _calculateAverage(), Colors.black87),
                _buildStatItem('Terendah', _getMinWeight(), Colors.black87),
              ],
            ),
            const SizedBox(height: 16), // Reduced spacing

            // Chart with optimized padding
            SizedBox(
              height: 300,
              child: Padding(
                padding: const EdgeInsets.only(
                    top: 20.0, left: 0.0, right: 0.0, bottom: 10.0),
                child: LineChart(
                  _buildLineChartData(),
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.linear,
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Info text
            Text(
              'Data berat badan 30 hari terakhir',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${value.toStringAsFixed(1)} kg',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  double _calculateAverage() {
    if (weightSpots.isEmpty) return 0.0;
    double sum = weightSpots.fold(0.0, (prev, spot) => prev + spot.y);
    return sum / weightSpots.length;
  }

  double _getMaxWeight() {
    if (weightSpots.isEmpty) return 0.0;
    return weightSpots.map((e) => e.y).reduce((a, b) => a > b ? a : b);
  }

  double _getMinWeight() {
    if (weightSpots.isEmpty) return 0.0;
    return weightSpots.map((e) => e.y).reduce((a, b) => a < b ? a : b);
  }

  LineChartData _buildLineChartData() {
    // Hitung range dinamis dengan padding yang sesuai untuk kesehatan
    double computedMaxY = 100.0;
    double computedMinY = 40.0;

    if (weightSpots.isNotEmpty) {
      final weights = weightSpots.map((e) => e.y).toList();
      final maxWeight = weights.reduce((a, b) => a > b ? a : b);
      final minWeight = weights.reduce((a, b) => a < b ? a : b);
      final range = maxWeight - minWeight;

      // Padding adaptif berdasarkan range data
      double paddingPercent = range < 5 ? 0.2 : (range < 10 ? 0.15 : 0.1);

      computedMaxY =
          maxY ?? (maxWeight + (range * paddingPercent)).ceilToDouble();
      computedMinY = minY ??
          (minWeight - (range * paddingPercent))
              .clamp(0, double.infinity)
              .floorToDouble();

      // Pastikan minimal range 10kg untuk readability
      if (computedMaxY - computedMinY < 10) {
        double center = (computedMaxY + computedMinY) / 2;
        computedMaxY = center + 5;
        computedMinY = (center - 5).clamp(0, double.infinity);
      }
    }

    return LineChartData(
      minX: 1,
      maxX: 31, // 31 days in a month
      minY: computedMinY,
      maxY: computedMaxY,
      titlesData: FlTitlesData(
        show: true,
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40, // Increased reserved size for better spacing
            interval: 5,
            getTitlesWidget: _bottomTitleWidgets,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: _calculateYInterval(computedMaxY - computedMinY),
            getTitlesWidget: _leftTitleWidgets,
            reservedSize: 20, // Reduced reserved size
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
        getDrawingHorizontalLine: (value) => FlLine(
          color: Colors.grey.withOpacity(0.2),
          strokeWidth: 1,
        ),
        getDrawingVerticalLine: (value) => FlLine(
          color: Colors.grey.withOpacity(0.2),
          strokeWidth: 1,
        ),
      ),
      lineBarsData: [
        // Garis utama berat badan (removed average line to prevent duplicate tooltips)
        LineChartBarData(
          spots: weightSpots,
          isCurved: false, // Changed to straight lines
          gradient: LinearGradient(
            colors: [
              Colors.teal.shade300,
              Colors.teal.shade600,
            ],
          ),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) =>
                FlDotCirclePainter(
              radius: 3, // Made dots smaller so other data points are visible
              color: Colors.teal.shade600,
              strokeWidth: 1.5, // Thinner stroke
              strokeColor: Colors.white,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                Colors.teal.withOpacity(0.1),
                Colors.teal.withOpacity(0.05),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          tooltipBgColor: Colors.black87,
          fitInsideHorizontally: true,
          fitInsideVertically: true,
          tooltipMargin: 32, // Increased margin for edge cases
          tooltipPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          tooltipRoundedRadius: 8,
          maxContentWidth: 120, // Limit tooltip width
          tooltipHorizontalAlignment: FLHorizontalAlignment.center,
          tooltipHorizontalOffset: 0,
          getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
            return touchedBarSpots.map((barSpot) {
              int dayOfMonth = barSpot.x.toInt();

              return LineTooltipItem(
                'Tanggal $dayOfMonth',
                const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
                children: [
                  TextSpan(
                    text: '\n${barSpot.y.toStringAsFixed(1)} kg',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              );
            }).toList();
          },
        ),
        getTouchedSpotIndicator:
            (LineChartBarData barData, List<int> spotIndexes) {
          return spotIndexes.map((spotIndex) {
            return TouchedSpotIndicatorData(
              FlLine(
                color: Colors.teal.withOpacity(0.8),
                strokeWidth: 2,
                dashArray: [5, 5],
              ),
              FlDotData(
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                  radius: 6,
                  color: Colors.teal,
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

  double _calculateYInterval(double range) {
    if (range <= 5) return 1;
    if (range <= 10) return 2;
    if (range <= 20) return 3;
    if (range <= 40) return 5;
    return 10;
  }

  Widget _bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.w500,
      fontSize: 10,
      color: Colors.grey,
    );

    String text = '';
    int day = value.toInt();

    // For monthly view, show day of month
    if (day >= 1 && day <= 31) {
      // Show every 5th day or significant days
      if (day == 1 ||
          day == 5 ||
          day == 10 ||
          day == 15 ||
          day == 20 ||
          day == 25 ||
          day == 30) {
        text = day.toString();
      }
    }

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Padding(
        padding: const EdgeInsets.only(top: 8), // Increased padding from axis
        child: Text(text, style: style),
      ),
    );
  }

  Widget _leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.w500,
      fontSize: 10,
      color: Colors.grey,
    );

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text('${value.toInt()}', style: style),
    );
  }
}

// Legacy function untuk backward compatibility
LineChartData weightLineData(List<FlSpot> weightSpots,
    {double? maxY, double? minY}) {
  final chart =
      WeightLineChart(weightSpots: weightSpots, maxY: maxY, minY: minY);
  return chart._buildLineChartData();
}

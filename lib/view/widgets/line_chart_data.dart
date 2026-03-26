import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

LineChartData lineData(List<FlSpot> glucoseSpots, {double? maxY}) {
  // Hitung maxY otomatis jika tidak diberikan
  double computedMaxY = 200.0;
  if (glucoseSpots.isNotEmpty) {
    final maxSpot = glucoseSpots.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    computedMaxY = (maxSpot > 200) ? (maxSpot / 100).ceil() * 100 : 200.0;
  }
  return LineChartData(
    minX: 0,
    maxX: 143,
    minY: 0.0,
    maxY: maxY ?? computedMaxY,
    baselineY: 0.0,
    baselineX: 0,
    titlesData: FlTitlesData(
      show: true,
      rightTitles: AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      topTitles: AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          interval: 1,
          getTitlesWidget: bottomTitleWidgets,
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: 100,
          getTitlesWidget: (value, meta) => leftTitleWidgets(value, meta, maxY: maxY ?? computedMaxY),
          reservedSize: 80,
        ),
      ),
    ),
    borderData: FlBorderData(
      show: true,
      border: Border.all(color: Colors.blueGrey),
    ),
    lineTouchData: const LineTouchData(
        touchTooltipData: LineTouchTooltipData(tooltipBgColor: Colors.white)),
    lineBarsData: [
      LineChartBarData(
        spots: glucoseSpots,
        isCurved: true,
        gradient: const LinearGradient(
          colors: [Colors.teal, Colors.blue],
        ),
        barWidth: 5,
        isStrokeCapRound: true,
        dotData: const FlDotData(
          show: false,
        ),
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            colors: [
              Colors.teal.withOpacity(0.4),
              Colors.blue.withOpacity(0.4)
            ],
          ),
        ),
      ),
    ],
  );
}

Widget bottomTitleWidgets(double value, TitleMeta meta) {
  const style = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 16,
  );
  Widget text;
  switch (value.toInt()) {
    case 0:
      text = const Text('0', style: style);
      break;
    case 143:
      text = const Text('24', style: style);
      break;
    default:
      text = const Text('', style: style);
      break;
  }

  return SideTitleWidget(
    axisSide: meta.axisSide,
    child: text,
  );
}

Widget leftTitleWidgets(double value, TitleMeta meta, {double maxY = 200}) {
  const style = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 12,
  );
  if (value % 100 == 0 && value <= maxY) {
    return Text('${value.toInt()} mg/dL', style: style, textAlign: TextAlign.left);
  }
  return Container();
}

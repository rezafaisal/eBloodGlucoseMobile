import 'package:fl_chart/fl_chart.dart';

class UtilService {

  final url = 'https://blood-glucose.temantekno.com';

  DateTime dateToday = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  List<FlSpot> chartData(List<dynamic> data , {DateTime? dateDiff}) {
    if (data.isEmpty) return [const FlSpot(1, 1)];
    dateDiff ??= dateToday;
    List<FlSpot> spots = [];
    for (var entry in data) {
      try {
        if (entry == null || entry['date'] == null) continue;
        final DateTime date = DateTime.parse(entry['date']);
        final double x = date.difference(dateDiff).inMinutes.toDouble() / 10.0;
        dynamic yRaw = entry['blood_glucose'] ?? entry['glucose'];
        if (yRaw == null) continue;
        final double y = yRaw is double ? yRaw : double.tryParse(yRaw.toString()) ?? double.nan;
        if (y.isNaN) continue;
        spots.add(FlSpot(x, y));
      } catch (_) {
        continue;
      }
    }
    return spots.isNotEmpty ? spots : [const FlSpot(1, 1)];
  }

}

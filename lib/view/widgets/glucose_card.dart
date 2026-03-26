import 'package:flutter/material.dart';

class GlucoseCard extends StatelessWidget {
  final String date;
  final double glucose;

  const GlucoseCard({
    super.key,
    required this.date,
    required this.glucose,
  });

  @override
  Widget build(BuildContext context) {
    MaterialColor color = Colors.green;
    String text = 'NORMAL';
    if (glucose > 140) {
      text = 'TINGGI';
      color = Colors.red;
    } else if (glucose < 70) {
      text = 'RENDAH';
      color = Colors.blue;
    }
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.all(20.0),
      child: Padding(
        padding: const EdgeInsets.only(
          left: 30,
          right: 30,
          top: 10,
          bottom: 10,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  date != '' ? date.substring(0, 10) : '--/--',
                  style: const TextStyle(fontSize: 20),
                ),
                Text(
                  date != '' ? date.substring(10, 16) : '--/--',
                  style: const TextStyle(fontSize: 20),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  glucose.toStringAsFixed(0),
                  style: const TextStyle(fontSize: 80),
                ),
                const SizedBox(
                  width: 5,
                ),
                const Column(
                  children: [
                    Text('mg/dL', style: TextStyle(fontSize: 20)),
                  ],
                ),
              ],
            ),
            Text(text,
                style: TextStyle(
                    fontSize: 25, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}

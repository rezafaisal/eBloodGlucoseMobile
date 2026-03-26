import 'dart:developer';

import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:intl/intl.dart';

class GlucoseGaugeCard extends StatefulWidget {
  final int glucose;
  final String date;
  final String? condition; // Tambahan untuk kondisi pengambilan
  final String? context; // Context dari endpoint baru
  final double? avg90days; // Tambahan rata-rata 90 hari terakhir
  final double? avgFasting; // Rata-rata puasa
  final double? avgPostMeal; // Rata-rata setelah makan
  final String? status; // Status diabetes
  final bool isLandscape; // Flag untuk mode landscape

  const GlucoseGaugeCard({
    Key? key,
    required this.glucose,
    required this.date,
    this.condition,
    this.context,
    this.avg90days,
    this.avgFasting,
    this.avgPostMeal,
    this.status,
    this.isLandscape = false,
  }) : super(key: key);

  @override
  State<GlucoseGaugeCard> createState() => _GlucoseGaugeCardState();
}

class _GlucoseGaugeCardState extends State<GlucoseGaugeCard>
    with TickerProviderStateMixin {
  late AnimationController _pointerAnimationController;
  late Animation<double> _pointerScaleAnimation;
  late Animation<Color?> _pointerColorAnimation;

  @override
  void initState() {
    super.initState();

    // Animation controller untuk pointer (berulang)
    _pointerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    // Scale animation (0.8x to 1.5x)
    _pointerScaleAnimation = Tween<double>(
      begin: 0.7,
      end: 1.4,
    ).animate(CurvedAnimation(
      parent: _pointerAnimationController,
      curve: Curves.easeInOut,
    ));

    // Color animation (opacity saja, warna tetap hitam)
    _pointerColorAnimation = ColorTween(
      begin: Colors.black.withOpacity(1),
      end: Colors.black.withOpacity(0.3),
    ).animate(CurvedAnimation(
      parent: _pointerAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pointerAnimationController.dispose();
    super.dispose();
  }

  Color _getColor(double value) {
    if (value < 70) {
      return Colors.purple;
    } else if (value > 130) {
      return Colors.red;
    } else {
      return Colors.green;
    }
  }

  String _getStatusLabel(double value) {
    if (value < 70) {
      return 'Rendah';
    } else if (value > 130) {
      return 'Tinggi';
    } else {
      return 'Normal';
    }
  }

  String _getHumanReadableDate(String dateString) {
    try {
      // Parsing tanggal dari string
      final DateTime parsedDate = DateTime.parse(dateString);
      final DateTime now = DateTime.now();
      final DateTime today = DateTime(now.year, now.month, now.day);
      final DateTime yesterday = today.subtract(const Duration(days: 1));
      final DateTime inputDate =
          DateTime(parsedDate.year, parsedDate.month, parsedDate.day);

      final int diffInDays = today.difference(inputDate).inDays;

      if (inputDate == today) {
        return 'Hari ini';
      } else if (inputDate == yesterday) {
        return 'Kemarin';
      } else if (diffInDays > 0 && diffInDays < 7) {
        return '$diffInDays hari yang lalu';
      } else if (diffInDays >= 7 && diffInDays < 30) {
        final int weeks = (diffInDays / 7).floor();
        return weeks == 1 ? '1 minggu yang lalu' : '$weeks minggu yang lalu';
      } else if (diffInDays >= 30 && diffInDays < 365) {
        final int months = (diffInDays / 30).floor();
        return months == 1 ? '1 bulan yang lalu' : '$months bulan yang lalu';
      } else if (diffInDays >= 365) {
        final int years = (diffInDays / 365).floor();
        return years == 1 ? '1 tahun yang lalu' : '$years tahun yang lalu';
      } else {
        // Tanggal di masa depan
        try {
          return DateFormat('dd MMM yyyy', 'id_ID').format(parsedDate);
        } catch (localeError) {
          // Fallback to English if Indonesian locale is not available
          return DateFormat('dd MMM yyyy', 'en_US').format(parsedDate);
        }
      }
    } catch (e) {
      // Jika parsing gagal, kembalikan string asli
      return dateString;
    }
  }

  String _getCategory(double value) {
    if (value < 70) {
      return 'rendah';
    } else if (value > 130) {
      return 'tinggi';
    } else {
      return 'normal';
    }
  }

  // Method untuk membuat item rata-rata - Desain Minimalist
  Widget _buildAverageItem(
      String label, double value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          // Icon dengan background subtle
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(height: 8),
          // Label dengan font yang lebih kecil
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          // Nilai dengan emphasis
          Text(
            value > 0 ? value.toStringAsFixed(1) : '-',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey[900],
              height: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          // Unit
          Text(
            'mg/dL',
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.grey[500],
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  // Method untuk mode landscape - lebih compact
  Widget _buildCompactAverage(String label, double value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value > 0 ? value.toStringAsFixed(0) : '-',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey[900],
            ),
          ),
        ],
      ),
    );
  }

  // Method untuk mendapatkan warna berdasarkan status string
  Color _getStatusColorFromString(String status) {
    String lowerStatus = status.toLowerCase();
    if (lowerStatus.contains('normal')) {
      return Colors.green;
    } else if (lowerStatus.contains('prediabetes') ||
        lowerStatus.contains('pra')) {
      return Colors.orange;
    } else if (lowerStatus.contains('diabetes')) {
      return Colors.red;
    } else if (lowerStatus.contains('rendah') || lowerStatus.contains('low')) {
      return Colors.purple;
    } else if (lowerStatus.contains('tinggi') || lowerStatus.contains('high')) {
      return Colors.red;
    }
    return Colors.grey;
  }

  // Method untuk mendapatkan deskripsi status
  String _getStatusDescription(String status) {
    String lowerStatus = status.toLowerCase();
    if (lowerStatus.contains('normal')) {
      return 'Kadar gula darah Anda dalam rentang normal. Pertahankan pola hidup sehat!';
    } else if (lowerStatus.contains('prediabetes') ||
        lowerStatus.contains('pra')) {
      return 'Risiko diabetes meningkat. Konsultasikan dengan dokter dan terapkan gaya hidup sehat.';
    } else if (lowerStatus.contains('diabetes')) {
      return 'Memerlukan perhatian medis. Konsultasikan dengan dokter untuk pengelolaan yang tepat.';
    }
    return 'Pantau terus kadar gula darah Anda secara rutin.';
  }

  // Method untuk mendapatkan icon untuk status display
  IconData _getStatusIconForDisplay(String status) {
    String lowerStatus = status.toLowerCase();
    if (lowerStatus.contains('normal')) {
      return Icons.check_circle;
    } else if (lowerStatus.contains('prediabetes') ||
        lowerStatus.contains('pra')) {
      return Icons.warning_amber_rounded;
    } else if (lowerStatus.contains('diabetes')) {
      return Icons.error;
    } else if (lowerStatus.contains('rendah') || lowerStatus.contains('low')) {
      return Icons.arrow_circle_down;
    } else if (lowerStatus.contains('tinggi') || lowerStatus.contains('high')) {
      return Icons.arrow_circle_up;
    }
    return Icons.info;
  }

  @override
  Widget build(BuildContext context) {
    final double min = 40;
    final double max = 200;
    final double value = widget.glucose.toDouble().clamp(min, max);

    String avgLabel = _getStatusLabel(widget.avg90days ?? 0);
    String activeCategory = _getCategory(value);

    // Cek ukuran layar untuk menentukan layout
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 1000; // Tablet biasanya >= 600px

    // Layout compact untuk landscape tablet saja
    if (widget.isLandscape) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 4,
        color: Colors.white,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: isTablet
                ? 600
                : 200, // Minimum height untuk landscape - ditingkatkan agar gauge tidak keluar
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header dengan tanggal (lebih compact)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      _getHumanReadableDate(widget.date),
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Gauge
                  SizedBox(
                    height: isTablet ? 420 : 320,
                    child: AnimatedBuilder(
                      animation: _pointerAnimationController,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: _GaugePainter(
                            value: value,
                            getColor: _getColor,
                            activeCategory: activeCategory,
                            scaleAnimation: _pointerScaleAnimation,
                            colorAnimation: _pointerColorAnimation,
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(height: 25),
                                Text(
                                  widget.glucose.toString(),
                                  style: TextStyle(
                                    fontSize: 28.sp,
                                    fontWeight: FontWeight.bold,
                                    color: _getColor(value),
                                  ),
                                ),
                                Text(
                                  'mg/dL',
                                  style: TextStyle(
                                      fontSize: 13.sp, color: Colors.grey[700]),
                                ),
                                const SizedBox(height: 6),
                                if (widget.context != null &&
                                    widget.context!.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: Colors.grey.shade400),
                                    ),
                                    child: Text(
                                      widget.context!,
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade800,
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
                  const SizedBox(height: 12),
                  // Rata-rata compact
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey[300]!, width: 1),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.analytics_outlined,
                                color: Colors.grey[700], size: 14),
                            const SizedBox(width: 6),
                            Text(
                              'Rata-rata 90 Hari',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: Colors.grey[800],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildCompactAverage(
                                'Semua', widget.avg90days ?? 0),
                            Container(
                                width: 1, height: 30, color: Colors.grey[300]),
                            _buildCompactAverage(
                                'Puasa', widget.avgFasting ?? 0),
                            Container(
                                width: 1, height: 30, color: Colors.grey[300]),
                            _buildCompactAverage(
                                'Stlh Mkn', widget.avgPostMeal ?? 0),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Status compact
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getStatusColorFromString(widget.status ?? avgLabel)
                              .withOpacity(0.15),
                          _getStatusColorFromString(widget.status ?? avgLabel)
                              .withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color:
                            _getStatusColorFromString(widget.status ?? avgLabel)
                                .withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getStatusIconForDisplay(widget.status ?? avgLabel),
                          color: _getStatusColorFromString(
                              widget.status ?? avgLabel),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.status ?? avgLabel,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: _getStatusColorFromString(
                                  widget.status ?? avgLabel),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ], // Column children
              ), // Column
            ), // Padding
          ), // SingleChildScrollView
        ), // ConstrainedBox
      ); // Card
    }

    // Layout portrait (original)
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 4,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header dengan tanggal di sudut kanan atas (badge)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    _getHumanReadableDate(widget.date),
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            SizedBox(
              height: isTablet ? 420 : 200,
              child: AnimatedBuilder(
                animation: _pointerAnimationController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _GaugePainter(
                      value: value,
                      getColor: _getColor,
                      activeCategory: activeCategory,
                      scaleAnimation: _pointerScaleAnimation,
                      colorAnimation: _pointerColorAnimation,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(height: 40),
                          // Nilai glukosa
                          Text(
                            widget.glucose.toString(),
                            style: TextStyle(
                              fontSize: 32.sp,
                              fontWeight: FontWeight.bold,
                              color: _getColor(value),
                            ),
                          ),
                          Text(
                            'mg/dL',
                            style: TextStyle(
                                fontSize: 15.sp, color: Colors.grey[700]),
                          ),
                          SizedBox(height: 10),
                          // Kondisi pengambilan
                          if (widget.context != null &&
                              widget.context!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: Colors.grey.shade400),
                              ),
                              child: Text(
                                widget.context!,
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade800,
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
            SizedBox(height: 16),
            // Box rata-rata 90 hari - DESAIN MINIMALIST NETRAL
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!, width: 1),
              ),
              child: Column(
                children: [
                  // Header minimalist
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.analytics_outlined,
                          color: Colors.grey[700],
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Rata-rata 90 Hari',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.grey[800],
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Tiga data rata-rata dengan desain netral
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildAverageItem(
                        'Semua',
                        widget.avg90days ?? 0,
                        Icons.assessment_outlined,
                        Colors.grey[700]!,
                      ),
                      Container(
                        width: 1,
                        height: 55,
                        color: Colors.grey[300],
                      ),
                      _buildAverageItem(
                        'Puasa',
                        widget.avgFasting ?? 0,
                        Icons.brightness_3_outlined,
                        Colors.grey[700]!,
                      ),
                      Container(
                        width: 1,
                        height: 55,
                        color: Colors.grey[300],
                      ),
                      _buildAverageItem(
                        'Setelah Makan',
                        widget.avgPostMeal ?? 0,
                        Icons.restaurant_outlined,
                        Colors.grey[700]!,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Separator dengan padding
                  Container(
                    height: 1,
                    color: Colors.grey[300],
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                  ),

                  const SizedBox(height: 16),

                  // Status dengan desain INFORMATIF
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getStatusColorFromString(widget.status ?? avgLabel)
                              .withOpacity(0.15),
                          _getStatusColorFromString(widget.status ?? avgLabel)
                              .withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color:
                            _getStatusColorFromString(widget.status ?? avgLabel)
                                .withOpacity(0.5),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _getStatusColorFromString(
                                  widget.status ?? avgLabel)
                              .withOpacity(0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Icon status
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _getStatusColorFromString(
                                        widget.status ?? avgLabel)
                                    .withOpacity(0.2),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: _getStatusColorFromString(
                                            widget.status ?? avgLabel)
                                        .withOpacity(0.3),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Icon(
                                _getStatusIconForDisplay(
                                    widget.status ?? avgLabel),
                                color: _getStatusColorFromString(
                                    widget.status ?? avgLabel),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            // Text status
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Status Kesehatan',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: Colors.grey[800],
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.status ?? avgLabel,
                                    style: TextStyle(
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.bold,
                                      color: _getStatusColorFromString(
                                          widget.status ?? avgLabel),
                                      letterSpacing: 0.5,
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Deskripsi informatif
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 16,
                                color: Colors.grey[700],
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _getStatusDescription(
                                      widget.status ?? avgLabel),
                                  style: TextStyle(
                                    fontSize: 11.5.sp,
                                    color: Colors.grey[700],
                                    height: 1.4,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Terakhir: ${widget.date}',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value;
  final Color Function(double) getColor;
  final String activeCategory;
  final Animation<double> scaleAnimation;
  final Animation<Color?> colorAnimation;

  _GaugePainter({
    required this.value,
    required this.getColor,
    required this.activeCategory,
    required this.scaleAnimation,
    required this.colorAnimation,
  }) : super(repaint: scaleAnimation); // Repaint when animation changes

  @override
  void paint(Canvas canvas, Size size) {
    final double startAngle = 180 * math.pi / 180; // π
    final double sweepAngle = 180 * math.pi / 180; // π rad
    final double radius = size.width / 2.1;
    final Offset center = Offset(size.width / 2, size.height * 0.95);

    final rect = Rect.fromCircle(center: center, radius: radius);

    const double strokeWidth = 20;
    const double gap = 0.15; // gap antar segmen

    void drawSegment({
      required double start,
      required double sweep,
      required Color color,
    }) {
      final paint = Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, start, sweep, false, paint);
    }

    // === Pembagian warna ===
    // Total = π radian (180 derajat)
    // Ungu = 30%, Hijau = 40%, Merah = 30%
    final double purpleSweep = sweepAngle * 0.30 - gap;
    final double greenSweep = sweepAngle * 0.45 - gap;
    final double redSweep = sweepAngle * 0.25;

    // Rendah (ungu)
    drawSegment(
      start: startAngle,
      sweep: purpleSweep,
      color: Colors.purple,
    );

    // Normal (hijau)
    drawSegment(
      start: startAngle + (sweepAngle * 0.30),
      sweep: greenSweep,
      color: Colors.green,
    );

    // Tinggi (merah)
    drawSegment(
      start: startAngle + (sweepAngle * 0.75),
      sweep: redSweep,
      color: Colors.red,
    );

    // ---- Tambahkan text 70 & 130 ----
    void drawLabel(String text, double angle) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black,
            fontWeight: FontWeight.w400,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();

      final double textRadius =
          radius + strokeWidth + 12; // diberi jarak ekstra biar tidak mepet
      final Offset offset = Offset(
        center.dx + textRadius * math.cos(angle) - textPainter.width / 2,
        center.dy + textRadius * math.sin(angle) - textPainter.height / 2,
      );

      textPainter.paint(canvas, offset);
    }

    // Posisi 70 (antara ungu & hijau)
    final double angle70 = startAngle + (sweepAngle * 0.30);
    drawLabel("70", angle70);

    // Posisi 130 (antara hijau & merah)
    final double angle130 = startAngle + (sweepAngle * 0.70);
    drawLabel("130", angle130);

    // ---- Penanda segitiga ----
    final double purpleStart = startAngle;
    final double purpleEnd = purpleStart + purpleSweep;

    final double greenStart = purpleEnd + gap;
    final double greenEnd = greenStart + greenSweep;

    final double redStart = greenEnd + gap;
    final double redEnd = redStart + redSweep;

    final double triangleRadius = radius + strokeWidth / 2 + 8;
    const double triangleSize = 14;

    // Ambil tengah segmen
    final double angleLow = (purpleStart + purpleEnd) / 2;
    final double angleNormal = (greenStart + greenEnd) / 2;
    final double angleHigh = (redStart + redEnd) / 2;

    void drawTriangle(double angle, Color color) {
      // Gunakan animasi untuk ukuran dan warna
      final double animatedSize = triangleSize * scaleAnimation.value;
      final Color animatedColor = colorAnimation.value ?? color;

      // Titik ujung (tip) segitiga, menghadap keluar lingkaran
      final Offset tip = Offset(
        center.dx + triangleRadius * math.cos(angle),
        center.dy + triangleRadius * math.sin(angle),
      );

      // Sudut basis diarahkan ke pusat gauge
      final double baseAngle = angle - math.pi * 2; // menghadap ke center
      final double baseWidth = animatedSize * 0.8;

      final Offset base1 = Offset(
        tip.dx + baseWidth * math.cos(baseAngle + math.pi / 10),
        tip.dy + baseWidth * math.sin(baseAngle + math.pi / 10),
      );
      final Offset base2 = Offset(
        tip.dx + baseWidth * math.cos(baseAngle - math.pi / 10),
        tip.dy + baseWidth * math.sin(baseAngle - math.pi / 10),
      );

      final path = Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(base1.dx, base1.dy)
        ..lineTo(base2.dx, base2.dy)
        ..close();

      // Tambahkan glow effect dengan shadow
      final shadowPaint = Paint()
        ..color = animatedColor.withOpacity(0.3)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      // Draw shadow/glow
      final shadowPath = path.shift(const Offset(0, 2));
      canvas.drawPath(shadowPath, shadowPaint);

      // Fill segitiga
      final paintFill = Paint()
        ..color = animatedColor
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, paintFill);

      // Stroke dengan sudut rounded
      final paintStroke = Paint()
        ..color = animatedColor.withOpacity(0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(path, paintStroke);
    }

    // Tampilkan hanya pointer sesuai kategori nilai glukosa (warna hitam)
    if (activeCategory == 'rendah') {
      drawTriangle(angleLow, Colors.black);
    } else if (activeCategory == 'normal') {
      drawTriangle(angleNormal, Colors.black);
    } else if (activeCategory == 'tinggi') {
      drawTriangle(angleHigh, Colors.black);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

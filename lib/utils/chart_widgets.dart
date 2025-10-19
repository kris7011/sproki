import 'package:flutter/material.dart';
import 'dart:math' as math;

class Sparkline extends StatelessWidget {
  const Sparkline({
    super.key,
    required this.values, // 0..1 typisk
    this.height = 40,
    this.strokeWidth = 2,
  });

  final List<double> values;
  final double height;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _SparklinePainter(
          values: values.isEmpty ? const [0] : values,
          color: Theme.of(context).colorScheme.primary,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.values,
    required this.color,
    required this.strokeWidth,
  });

  final List<double> values;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length == 1) {
      final y = size.height * (1 - values.first.clamp(0.0, 1.0));
      final p = Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
      return;
    }

    final maxV = values.fold<double>(values.first, math.max);
    final minV = values.fold<double>(values.first, math.min);
    final range = (maxV - minV).abs() < 1e-6 ? 1.0 : (maxV - minV);

    final dx = size.width / (values.length - 1);
    final path = Path();

    double yAt(int i) {
      final norm = (values[i] - minV) / range; // 0..1
      return size.height * (1 - norm);
    }

    path.moveTo(0, yAt(0));
    for (int i = 1; i < values.length; i++) {
      path.lineTo(dx * i, yAt(i));
    }

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

class BarChartMini extends StatelessWidget {
  const BarChartMini({
    super.key,
    required this.bins, // hver 0..1
    this.height = 60,
    this.barSpacing = 4,
  });

  final List<double> bins;
  final double height;
  final double barSpacing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _BarChartMiniPainter(
          bins: bins,
          color: Theme.of(context).colorScheme.primary,
          barSpacing: barSpacing,
        ),
      ),
    );
  }
}

class _BarChartMiniPainter extends CustomPainter {
  _BarChartMiniPainter({
    required this.bins,
    required this.color,
    required this.barSpacing,
  });

  final List<double> bins;
  final Color color;
  final double barSpacing;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: 0.9); // modern API
    final n = bins.isEmpty ? 1 : bins.length;
    final barWidth = (size.width - barSpacing * (n - 1)) / n;

    for (int i = 0; i < n; i++) {
      final v = (bins.isEmpty ? 0.0 : bins[i]).clamp(0.0, 1.0);
      final h = v * size.height;
      final left = i * (barWidth + barSpacing);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, size.height - h, barWidth, h),
        const Radius.circular(3),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartMiniPainter oldDelegate) {
    return oldDelegate.bins != bins ||
        oldDelegate.color != color ||
        oldDelegate.barSpacing != barSpacing;
  }
}

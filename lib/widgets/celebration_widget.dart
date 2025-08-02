import 'package:flutter/material.dart';
import 'dart:math' as math;

class CelebrationWidget extends StatefulWidget {
  final Widget child;
  final bool show;

  const CelebrationWidget({super.key, required this.child, required this.show});

  @override
  CelebrationWidgetState createState() => CelebrationWidgetState();
}

class CelebrationWidgetState extends State<CelebrationWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _particles = List.generate(50, (index) => Particle());

    if (widget.show) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(CelebrationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show && !oldWidget.show) {
      _particles = List.generate(50, (index) => Particle());
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.show)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: ParticlePainter(_particles, _controller.value),
                size: Size.infinite,
              );
            },
          ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class Particle {
  late double x;
  late double y;
  late double vx;
  late double vy;
  late Color color;
  late double size;
  late String emoji;

  Particle() {
    final random = math.Random();
    x = random.nextDouble();
    y = 1.0;
    vx = (random.nextDouble() - 0.5) * 2;
    vy = -random.nextDouble() * 3 - 1;
    color = [
      Colors.yellow,
      Colors.orange,
      Colors.pink,
      Colors.purple,
    ][random.nextInt(4)];
    size = random.nextDouble() * 10 + 5;
    emoji = ['⭐', '🎉', '✨', '💫', '🌟'][random.nextInt(5)];
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double progress;

  ParticlePainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {

    for (final particle in particles) {
      final x = (particle.x + particle.vx * progress) * size.width;
      final y = (particle.y + particle.vy * progress) * size.height;

      if (y < size.height && y > 0 && x > 0 && x < size.width) {
        // Draw emoji
        final textPainter = TextPainter(
          text: TextSpan(
            text: particle.emoji,
            style: TextStyle(fontSize: particle.size),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(x, y));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

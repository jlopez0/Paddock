import 'dart:math';

import 'package:flutter/material.dart';

/// Carta que se voltea en 3D al pasar [revealed] a `true`.
class FlipCard extends StatelessWidget {
  const FlipCard({super.key, required this.revealed, required this.back, required this.front});

  final bool revealed;
  final Widget back;
  final Widget front;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: revealed ? 1 : 0),
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeInOutCubic,
      builder: (context, t, _) {
        final angle = t * pi;
        final showFront = t > 0.5;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0015)
            ..rotateY(angle),
          child: showFront
              ? Transform(alignment: Alignment.center, transform: Matrix4.rotationY(pi), child: front)
              : back,
        );
      },
    );
  }
}

/// Lluvia de confeti de un solo disparo.
class Confetti extends StatefulWidget {
  const Confetti({super.key, this.colors = const [Colors.amber, Colors.pink, Colors.cyan, Colors.lime]});

  final List<Color> colors;

  @override
  State<Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<Confetti> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 3200))..forward();
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    final r = Random();
    _particles = List.generate(120, (i) {
      return _Particle(
        x: r.nextDouble(),
        delay: r.nextDouble() * 0.35,
        speed: 0.6 + r.nextDouble() * 0.7,
        drift: (r.nextDouble() - 0.5) * 0.3,
        spin: (r.nextDouble() - 0.5) * 20,
        size: 6 + r.nextDouble() * 7,
        color: widget.colors[i % widget.colors.length],
      );
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: CustomPaint(
          painter: _ConfettiPainter(_c, _particles),
          size: Size.infinite,
        ),
      );
}

class _Particle {
  _Particle({
    required this.x,
    required this.delay,
    required this.speed,
    required this.drift,
    required this.spin,
    required this.size,
    required this.color,
  });

  final double x, delay, speed, drift, spin, size;
  final Color color;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.anim, this.particles) : super(repaint: anim);

  final Animation<double> anim;
  final List<_Particle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in particles) {
      final t = ((anim.value - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (t <= 0) continue;
      final y = -20 + t * p.speed * (size.height + 60);
      final x = (p.x + p.drift * t + sin(t * 8 + p.spin) * 0.02) * size.width;
      paint.color = p.color.withValues(alpha: 1 - Curves.easeIn.transform(t) * 0.6);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(t * p.spin);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.5),
            const Radius.circular(1.5)),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => false;
}

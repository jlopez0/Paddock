import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Piezas de identidad dibujadas por código (sin assets ni recursos de
/// terceros): la mascota "el Jockey" y el trofeo de la Copa.

const Color _gold = Color(0xFFE8B84A);
const Color _brass = Color(0xFFB8862B);
const Color _paper = Color(0xFFF3EFE0);
const Color _burgundy = Color(0xFF7A2430);
const Color _ink = Color(0xFF0B1611);

enum JockeyPose { neutral, celebra }

/// Mascota: cabeza de caballo de perfil con monóculo y gorrilla.
class Jockey extends StatelessWidget {
  const Jockey({super.key, this.pose = JockeyPose.neutral, this.size = 96});

  final JockeyPose pose;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: JockeyPainter(pose)),
      ),
    );
  }
}

class JockeyPainter extends CustomPainter {
  JockeyPainter(this.pose);
  final JockeyPose pose;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    final fill = Paint()..style = PaintingStyle.fill;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Crin (detrás de la cabeza).
    final mane = Path()
      ..moveTo(40, 22)
      ..quadraticBezierTo(14, 34, 20, 62)
      ..quadraticBezierTo(14, 80, 22, 100)
      ..lineTo(40, 100)
      ..lineTo(38, 40)
      ..close();
    canvas.drawPath(mane, fill..color = _gold);
    canvas.drawPath(
      mane,
      line
        ..color = _brass
        ..strokeWidth = 2,
    );

    // Oreja.
    final ear = Path()
      ..moveTo(40, 26)
      ..lineTo(40, 6)
      ..lineTo(54, 22)
      ..close();
    canvas.drawPath(ear, fill..color = _paper);
    canvas.drawPath(
      ear,
      line
        ..color = _brass
        ..strokeWidth = 2,
    );

    // Cabeza y cuello.
    final head = Path()
      ..moveTo(32, 100)
      ..lineTo(34, 50)
      ..quadraticBezierTo(36, 28, 52, 24)
      ..lineTo(66, 34)
      ..quadraticBezierTo(80, 56, 90, 72)
      ..quadraticBezierTo(95, 82, 87, 90)
      ..quadraticBezierTo(76, 94, 68, 86)
      ..quadraticBezierTo(58, 80, 54, 74)
      ..quadraticBezierTo(52, 88, 66, 100)
      ..close();
    canvas.drawPath(head, fill..color = _paper);
    canvas.drawPath(
      head,
      line
        ..color = _brass
        ..strokeWidth = 2.5,
    );

    // Filete de mejilla.
    canvas.drawPath(
      Path()
        ..moveTo(48, 62)
        ..quadraticBezierTo(46, 72, 54, 76),
      line
        ..color = _brass
        ..strokeWidth = 1.8,
    );

    // Fosa nasal.
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(86, 80), width: 3.6, height: 5),
      fill..color = _ink,
    );

    // Boca.
    final mouth = Path();
    if (pose == JockeyPose.celebra) {
      mouth
        ..moveTo(66, 86)
        ..quadraticBezierTo(76, 94, 86, 85);
    } else {
      mouth
        ..moveTo(70, 87)
        ..lineTo(84, 88);
    }
    canvas.drawPath(
      mouth,
      line
        ..color = _ink
        ..strokeWidth = 2,
    );

    // Gorrilla: cúpula burdeos, visera y botón.
    final cap = Path()
      ..moveTo(34, 38)
      ..quadraticBezierTo(34, 12, 52, 12)
      ..quadraticBezierTo(70, 12, 70, 38)
      ..close();
    canvas.drawPath(cap, fill..color = _burgundy);
    canvas.drawPath(
      cap,
      line
        ..color = _gold
        ..strokeWidth = 2,
    );
    final brim = Path()
      ..moveTo(32, 37)
      ..lineTo(80, 37)
      ..lineTo(76, 43)
      ..lineTo(32, 43)
      ..close();
    canvas.drawPath(brim, fill..color = _gold);
    canvas.drawCircle(const Offset(52, 11), 3, fill..color = _gold);
    line
      ..color = _gold
      ..strokeWidth = 1.6;
    canvas.drawLine(const Offset(46, 14), const Offset(44, 36), line);
    canvas.drawLine(const Offset(58, 14), const Offset(60, 36), line);

    // Ojo.
    const eye = Offset(60, 54);
    if (pose == JockeyPose.celebra) {
      canvas.drawPath(
        Path()
          ..moveTo(54, 56)
          ..quadraticBezierTo(60, 47, 66, 56),
        line
          ..color = _ink
          ..strokeWidth = 3,
      );
    } else {
      canvas.drawCircle(eye, 3.6, fill..color = _ink);
      canvas.drawCircle(const Offset(61, 53), 1.1, fill..color = _paper);
      canvas.drawPath(
        Path()
          ..moveTo(53, 46)
          ..quadraticBezierTo(60, 41, 67, 45),
        line
          ..color = _ink
          ..strokeWidth = 2,
      );
    }

    // Monóculo: cristal, aro y cadena.
    canvas.drawCircle(
      eye,
      10,
      fill
        ..color = _gold.withValues(
          alpha: pose == JockeyPose.celebra ? 0.3 : 0.16,
        ),
    );
    canvas.drawCircle(
      eye,
      10,
      line
        ..color = _gold
        ..strokeWidth = 3,
    );
    canvas.drawPath(
      Path()
        ..moveTo(60, 64)
        ..quadraticBezierTo(62, 78, 48, 84)
        ..quadraticBezierTo(44, 88, 46, 94),
      line
        ..color = _gold
        ..strokeWidth = 1.6,
    );
    if (pose == JockeyPose.celebra) {
      _sparkle(canvas, const Offset(68, 47), 6, fill..color = _paper);
      _sparkle(canvas, const Offset(86, 28), 5, fill..color = _gold);
      _sparkle(canvas, const Offset(12, 18), 4, fill..color = _gold);
    }
    canvas.restore();
  }

  void _sparkle(Canvas canvas, Offset c, double r, Paint p) {
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx, c.dy, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx, c.dy, c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r)
      ..close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(JockeyPainter old) => old.pose != pose;
}

/// Trofeo de latón con asas, base y brillo (para el podio de la Copa).
class TrophyIllustration extends StatelessWidget {
  const TrophyIllustration({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _TrophyPainter()),
      ),
    );
  }
}

class _TrophyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    final fill = Paint()..style = PaintingStyle.fill;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Asas.
    line
      ..color = _brass
      ..strokeWidth = 5;
    for (final s in [-1.0, 1.0]) {
      canvas.drawPath(
        Path()
          ..moveTo(50 + s * 27, 22)
          ..cubicTo(50 + s * 52, 20, 50 + s * 50, 46, 50 + s * 19, 48),
        line,
      );
    }

    // Copa.
    final cup = Path()
      ..moveTo(22, 14)
      ..lineTo(78, 14)
      ..quadraticBezierTo(78, 56, 50, 62)
      ..quadraticBezierTo(22, 56, 22, 14)
      ..close();
    canvas.drawPath(
      cup,
      Paint()
        ..shader = const LinearGradient(
          colors: [_gold, _brass],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(const Rect.fromLTWH(20, 10, 60, 55)),
    );
    canvas.drawPath(
      cup,
      line
        ..color = _brass
        ..strokeWidth = 2,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(19, 10, 62, 7),
        const Radius.circular(3),
      ),
      fill..color = _gold,
    );
    // Brillo.
    canvas.drawPath(
      Path()
        ..moveTo(30, 24)
        ..quadraticBezierTo(31, 44, 42, 52),
      line
        ..color = _paper.withValues(alpha: 0.85)
        ..strokeWidth = 3.5,
    );
    _star(canvas, const Offset(56, 34), 9, fill..color = _burgundy);

    // Pie y base.
    canvas.drawRect(const Rect.fromLTWH(45, 62, 10, 14), fill..color = _brass);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(34, 74, 32, 8),
        const Radius.circular(2),
      ),
      fill..color = _gold,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(24, 82, 52, 12),
        const Radius.circular(2),
      ),
      fill..color = _brass,
    );
    canvas.drawRect(const Rect.fromLTWH(24, 82, 52, 3), fill..color = _gold);
    canvas.restore();
  }

  void _star(Canvas canvas, Offset c, double r, Paint p) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final rad = i.isEven ? r : r * 0.45;
      final a = -math.pi / 2 + i * math.pi / 5;
      final pt = Offset(c.dx + rad * math.cos(a), c.dy + rad * math.sin(a));
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    canvas.drawPath(path..close(), p);
  }

  @override
  bool shouldRepaint(_TrophyPainter old) => false;
}

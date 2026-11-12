import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../app/theme.dart';
import '../domain/country.dart';
import '../domain/geo_map.dart';
import '../geo_data.dart';

const geoColor = Color(0xFF3CC9C0);

/// Bandera con esquinas redondeadas y sombra.
class FlagView extends StatelessWidget {
  const FlagView(this.country, {super.key, this.width = 300, this.radius = 14});

  final Country country;
  final double width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: width * 3 / 4,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 24, offset: Offset(0, 10))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: SvgPicture.asset(country.flagAsset, fit: BoxFit.cover),
      ),
    );
  }
}

/// Silueta de un país, centrada y escalada para caber en el espacio disponible.
class SilhouetteView extends ConsumerWidget {
  const SilhouetteView(this.iso, {super.key, this.color = geoColor});

  final String iso;
  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shape = ref.watch(silhouettesProvider).value?[iso];
    if (shape == null) return const SizedBox.shrink();
    return CustomPaint(painter: _SilhouettePainter(shape, color), size: Size.infinite);
  }
}

class _SilhouettePainter extends CustomPainter {
  _SilhouettePainter(this.shape, this.color);

  final Silhouette shape;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = min(size.width / shape.width, size.height / shape.height);
    final dx = (size.width - shape.width * scale) / 2;
    final dy = (size.height - shape.height * scale) / 2;
    canvas.save();
    canvas.translate(dx, dy);
    canvas.scale(scale);
    final box = Rect.fromLTWH(0, 0, shape.width.toDouble(), shape.height.toDouble());
    // Resplandor suave y simétrico alrededor de la forma.
    canvas.drawPath(
      shape.path,
      Paint()
        ..color = color.withValues(alpha: 0.35)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 14 / scale),
    );
    canvas.drawPath(
      shape.path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, Color.lerp(color, const Color(0xFF0B1611), 0.35)!],
        ).createShader(box),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SilhouettePainter old) => old.shape != shape || old.color != color;
}

final _regionPaths = Expando<Path>();
Path _regionPath(MapRegion r) => _regionPaths[r] ??= pathFromRings(r.rings);

/// Mapa completo con una región resaltada. Las regiones diminutas llevan además
/// un anillo alrededor para que se vean.
class RegionMapView extends StatelessWidget {
  const RegionMapView({super.key, required this.map, required this.highlightId, this.color = geoColor});

  final GeoMap map;
  final String? highlightId;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: map.width / map.height,
      child: CustomPaint(painter: _MapPainter(map, highlightId, color)),
    );
  }
}

class _MapPainter extends CustomPainter {
  _MapPainter(this.map, this.highlightId, this.color);

  final GeoMap map;
  final String? highlightId;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / map.width;
    canvas.save();
    canvas.scale(scale);
    final px = 1 / scale; // 1 píxel en unidades del mapa

    final frame = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 * px
      ..color = AppColors.outline;
    for (final f in map.frames) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(f[0].toDouble(), f[1].toDouble(), f[2].toDouble(), f[3].toDouble()),
          Radius.circular(10 * px),
        ),
        frame,
      );
    }

    final fill = Paint()..color = AppColors.surfaceHigh;
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8 * px
      ..color = AppColors.background;
    MapRegion? target;
    for (final r in map.regions) {
      if (r.id == highlightId) {
        target = r;
        continue;
      }
      final p = _regionPath(r);
      canvas.drawPath(p, fill);
      canvas.drawPath(p, border);
    }

    if (target != null) {
      final p = _regionPath(target);
      canvas.drawPath(
        p,
        Paint()
          ..color = color.withValues(alpha: 0.45)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 * px),
      );
      canvas.drawPath(p, Paint()..color = color);
      canvas.drawPath(p, border);

      final maxSide = max(map.width, map.height).toDouble();
      if (target.size < maxSide * 0.03) {
        final c = Offset(target.center.$1.toDouble(), target.center.$2.toDouble());
        final radius = max(target.size * 0.9, maxSide * 0.03);
        canvas.drawCircle(c, radius, Paint()..color = color.withValues(alpha: 0.15));
        canvas.drawCircle(
          c,
          radius,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2 * px
            ..color = color,
        );
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MapPainter old) => old.map != map || old.highlightId != highlightId || old.color != color;
}

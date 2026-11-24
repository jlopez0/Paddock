import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'theme.dart';

/// Sistema gráfico de la app (docs/DISENO_ALMA.md, secciones b y d).
///
/// Las pantallas usan SOLO estos widgets: ninguna importa Phosphor. Estilo por
/// defecto: duotono, capa principal en oro y capa secundaria en el color del
/// juego o de la categoría.

const Color _kInk = Color(0xFF241A00);
const Color _kOrange = Color(0xFFF2994A);
const Color _kTeal = Color(0xFF3CC9C0);

Widget _duo(
  _Duo icon,
  double size,
  Color primary,
  Color secondary, {
  String? semanticLabel,
}) => Stack(
  alignment: Alignment.center,
  children: [
    Opacity(
      opacity: 0.5,
      child: Icon(icon.secondary, size: size, color: secondary),
    ),
    Icon(
      icon.primary,
      size: size,
      color: primary,
      semanticLabel: semanticLabel,
    ),
  ],
);

// ---------------------------------------------------------------------------
// Iconos de juego
// ---------------------------------------------------------------------------

/// Juegos con icono propio. [id] coincide con `GameModule.id`.
enum GameIconKind {
  carrera('carrera', Color(0xFFE8B84A)),
  infiltrado('infiltrado', Color(0xFF8E6BE0)),
  trivia('trivia', _kOrange),
  geografia('geografia', _kTeal),
  abecedario('abecedario', Color(0xFF4C8DFF)),
  quienEsMasProbable('quien-es-mas-probable', Color(0xFF3FA796)),
  quePreferirias('que-preferirias', Color(0xFFB57BEE)),
  yoNunca('yo-nunca', Color(0xFFE5575C)),
  copa('copa', AppColors.brass);

  const GameIconKind(this.id, this.color);

  final String id;
  final Color color;

  _Duo get _data => switch (this) {
    carrera => _D.horse,
    infiltrado => _D.detective,
    trivia => _D.brain,
    geografia => _D.globeHemisphereWest,
    abecedario => _D.textAa,
    quienEsMasProbable => _D.handPointing,
    quePreferirias => _D.scales,
    yoNunca => _D.fingerprint,
    copa => _D.trophy,
  };

  static GameIconKind? fromId(String id) {
    for (final k in values) {
      if (k.id == id) return k;
    }
    return null;
  }
}

/// Icono de un juego: oro + color del juego. Un id desconocido pinta un
/// icono genérico (nunca lanza).
class GameIcon extends StatelessWidget {
  GameIcon(String id, {super.key, this.size = 44, this.semanticLabel})
    : kind = GameIconKind.fromId(id);

  const GameIcon.kind(
    GameIconKind this.kind, {
    super.key,
    this.size = 44,
    this.semanticLabel,
  });

  final GameIconKind? kind;
  final double size;
  final String? semanticLabel;

  /// Ids de juego con icono propio.
  static List<String> get ids => [for (final k in GameIconKind.values) k.id];

  static bool hasIcon(String id) => GameIconKind.fromId(id) != null;

  @override
  Widget build(BuildContext context) {
    final k = kind;
    return _duo(
      k?._data ?? _D.puzzlePiece,
      size,
      AppColors.gold,
      k?.color ?? AppColors.textMuted,
      semanticLabel: semanticLabel,
    );
  }
}

// ---------------------------------------------------------------------------
// Medallas
// ---------------------------------------------------------------------------

/// Medalla de puesto (1 oro, 2 plata, 3 bronce; otros, bronce) con el número
/// en Alfa Slab One. El número no escala con el texto del sistema: es parte
/// del dibujo.
class MedalIcon extends StatelessWidget {
  const MedalIcon(this.place, {super.key, this.size = 32});

  final int place;
  final double size;

  Color get _color => switch (place) {
    1 => AppColors.medalGold,
    2 => AppColors.medalSilver,
    _ => AppColors.medalBronze,
  };

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Puesto $place',
      excludeSemantics: true,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(_fillMedal, size: size, color: _color),
            Align(
              alignment: const Alignment(0, 0.38),
              child: Text(
                '$place',
                textScaler: TextScaler.noScaling,
                style: TextStyle(
                  fontFamily: AppFonts.display,
                  fontSize: size * 0.32,
                  height: 1,
                  color: _kInk,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Niveles de los mazos
// ---------------------------------------------------------------------------

/// Icono de nivel: `suave` (smiley verde), `picante` (pimiento naranja),
/// `atrevido` (llama roja). Coincide con `PromptLevel.name`.
class LevelIcon extends StatelessWidget {
  const LevelIcon(this.level, {super.key, this.size = 20});

  final String level;
  final double size;

  static const ids = ['suave', 'picante', 'atrevido'];

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (level) {
      'picante' => (_D.pepper, _kOrange),
      'atrevido' => (_D.flame, AppColors.danger),
      _ => (_D.smiley, AppColors.success),
    };
    return _duo(icon, size, color, color);
  }
}

// ---------------------------------------------------------------------------
// Categorías de Trivia y Geografía
// ---------------------------------------------------------------------------

/// Icono de categoría. Trivia: historia, ciencia, naturaleza, arte, deporte,
/// ocio (alias cine), curiosidades. Geografía: banderas, capitales,
/// capital-a-pais, siluetas, mezcla.
class CategoryIcon extends StatelessWidget {
  const CategoryIcon(this.id, {super.key, this.size = 24, this.color});

  final String id;
  final double size;

  /// Sustituye al color secundario de la categoría.
  final Color? color;

  static const triviaIds = [
    'historia',
    'ciencia',
    'naturaleza',
    'arte',
    'deporte',
    'ocio',
    'curiosidades',
  ];
  static const geoIds = [
    'banderas',
    'capitales',
    'capital-a-pais',
    'siluetas',
    'mezcla',
  ];

  static bool hasIcon(String id) => _lookup(id) != null;

  static (_Duo, Color)? _lookup(String id) => switch (id) {
    'historia' => (_D.bank, _kOrange),
    'ciencia' => (_D.flask, _kOrange),
    'naturaleza' => (_D.plant, _kOrange),
    'arte' => (_D.paintBrush, _kOrange),
    'deporte' => (_D.soccerBall, _kOrange),
    'ocio' || 'cine' => (_D.filmSlate, _kOrange),
    'curiosidades' => (_D.puzzlePiece, _kOrange),
    'banderas' => (_D.flag, _kTeal),
    'capitales' => (_D.bank, _kTeal),
    'capital-a-pais' => (_D.mapPin, _kTeal),
    'siluetas' => (_D.mapTrifold, _kTeal),
    'mezcla' => (_D.shuffle, _kTeal),
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final entry = _lookup(id);
    return _duo(
      entry?.$1 ?? _D.puzzlePiece,
      size,
      AppColors.gold,
      color ?? entry?.$2 ?? AppColors.textMuted,
    );
  }
}

// ---------------------------------------------------------------------------
// Iconos sueltos
// ---------------------------------------------------------------------------

/// Iconos sueltos tipados. `AppIcon.trophy.widget(size: 56)`.
enum AppIcon {
  trophy(_D.trophy, AppColors.gold),
  crown(_D.crown, AppColors.gold),
  confetti(_D.confetti, AppColors.success),
  coins(_D.coins, AppColors.danger),
  trendDown(_D.trendDown, AppColors.danger),
  flagCheckered(_D.flagCheckered, AppColors.gold),
  target(_D.target, AppColors.danger),
  scales(_D.scales, AppColors.gold),
  deviceMobile(_D.deviceMobile, AppColors.gold),
  detective(_D.detective, Color(0xFF8E6BE0)),
  flame(_D.flame, AppColors.danger),
  flag(_D.flag, _kTeal),
  horse(_D.horse, AppColors.gold),
  brain(_D.brain, _kOrange),
  globe(_D.globeHemisphereWest, _kTeal),
  medal(_D.medal, AppColors.gold),
  smiley(_D.smiley, AppColors.success),
  pepper(_D.pepper, _kOrange),
  shareNetwork(_D.shareNetwork, AppColors.gold),
  // Interfaz (sustituyen a los iconos redondeados de Material).
  close(_D.x, AppColors.textMuted),
  replay(_D.arrowCounterClockwise, AppColors.gold),
  restart(_D.arrowCounterClockwise, AppColors.gold),
  undo(_D.arrowUUpLeft, AppColors.gold),
  pause(_D.pause, AppColors.gold),
  fastForward(_D.fastForward, AppColors.gold),
  add(_D.plus, AppColors.gold),
  remove(_D.minus, AppColors.gold),
  delete(_D.trash, AppColors.danger),
  settings(_D.gear, AppColors.gold),
  volume(_D.speakerHigh, AppColors.gold),
  volumeOff(_D.speakerSlash, AppColors.textMuted),
  privacy(_D.shieldCheck, AppColors.success),
  help(_D.question, AppColors.gold),
  info(_D.info, AppColors.gold),
  tag(_D.tag, AppColors.gold),
  external(_D.arrowSquareOut, AppColors.gold),
  chevronRight(_D.caretRight, AppColors.gold),
  chevronLeft(_D.caretLeft, AppColors.gold),
  shuffle(_D.shuffle, AppColors.gold),
  check(_D.check, AppColors.success),
  checkCircle(_D.checkCircle, AppColors.success),
  cancel(_D.xCircle, AppColors.danger),
  visibility(_D.eye, AppColors.gold),
  keyboard(_D.keyboard, AppColors.gold),
  grid(_D.squaresFour, AppColors.gold);

  const AppIcon(this._data, this.accent);

  final _Duo _data;

  /// Codigos de glifo (principal y secundario) en la fuente PhosphorDuotone.
  @visibleForTesting
  List<int> get codePoints => [
    _data.primary.codePoint,
    _data.secondary.codePoint,
  ];

  /// Color de la capa secundaria (y del trazo si no se indica [color]).
  final Color accent;

  /// [color] pinta ambas capas; si es null, oro + [accent].
  Widget widget({double size = 24, Color? color, String? semanticLabel}) =>
      _duo(
        _data,
        size,
        color ?? AppColors.gold,
        color ?? accent,
        semanticLabel: semanticLabel,
      );
}

// ---------------------------------------------------------------------------
// Ficha de apuesta
// ---------------------------------------------------------------------------

/// Ficha de apuesta dibujada: disco, aro de latón punteado y valor en Alfa
/// Slab One.
class ChipToken extends StatelessWidget {
  const ChipToken(this.value, {super.key, this.size = 40, this.color});

  final int value;
  final double size;

  /// Color del disco; por defecto burdeos.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Ficha de $value',
      excludeSemantics: true,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _ChipPainter(value, color ?? AppColors.burgundy),
        ),
      ),
    );
  }
}

class _ChipPainter extends CustomPainter {
  _ChipPainter(this.value, this.color);

  final int value;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;

    canvas.drawCircle(c, r, Paint()..color = AppColors.brass);
    canvas.drawCircle(c, r * 0.92, Paint()..color = color);

    // Aro punteado de latón claro.
    final dash = Paint()
      ..color = AppColors.paper
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.16
      ..strokeCap = StrokeCap.butt;
    final ringR = r * 0.78;
    const n = 16;
    for (var i = 0; i < n; i++) {
      final a = i * 2 * math.pi / n;
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: ringR),
        a,
        math.pi / n,
        false,
        dash,
      );
    }

    canvas.drawCircle(
      c,
      r * 0.6,
      Paint()
        ..color = AppColors.brass
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.05,
    );

    // Valor: se reduce hasta caber dentro del aro interior.
    final maxW = r * 1.0;
    var fs = r * 0.8;
    late TextPainter tp;
    while (true) {
      tp = TextPainter(
        text: TextSpan(
          text: '$value',
          style: TextStyle(
            fontFamily: AppFonts.display,
            fontSize: fs,
            height: 1,
            color: AppColors.paper,
          ),
        ),
        textDirection: TextDirection.ltr,
        textScaler: TextScaler.noScaling,
      )..layout();
      if (tp.width <= maxW || fs < 6) break;
      fs -= 1;
    }
    tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_ChipPainter old) =>
      old.value != value || old.color != color;
}

// ---------------------------------------------------------------------------
// Boleto
// ---------------------------------------------------------------------------

/// Boleto: rectángulo de papel con muescas laterales. Sin [stub], la muesca
/// queda a media altura. Con [stub], el boleto se parte en cuerpo y matriz
/// separados por una línea de puntos con las muescas en la unión.
class TicketCard extends StatelessWidget {
  const TicketCard({
    super.key,
    required this.child,
    this.stub,
    this.color = AppColors.paper,
    this.padding = const EdgeInsets.all(16),
    this.notchRadius = 10,
  });

  final Widget child;
  final Widget? stub;
  final Color color;
  final EdgeInsetsGeometry padding;
  final double notchRadius;

  @override
  Widget build(BuildContext context) {
    final hasStub = stub != null;
    final body = DecoratedBox(
      decoration: ShapeDecoration(
        color: color,
        shape: _TicketBorder(
          radius: notchRadius,
          notch: hasStub ? _Notch.bottom : _Notch.middle,
        ),
      ),
      child: Padding(padding: padding, child: child),
    );
    if (!hasStub) return body;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        body,
        DecoratedBox(
          decoration: ShapeDecoration(
            color: color,
            shape: _TicketBorder(radius: notchRadius, notch: _Notch.top),
          ),
          child: Stack(
            children: [
              Positioned(
                left: notchRadius + 4,
                right: notchRadius + 4,
                top: 0,
                child: CustomPaint(
                  size: const Size(0, 1),
                  painter: _DottedLinePainter(
                    AppColors.brass.withValues(alpha: 0.7),
                  ),
                ),
              ),
              Padding(padding: padding, child: stub),
            ],
          ),
        ),
      ],
    );
  }
}

enum _Notch { top, bottom, middle }

class _TicketBorder extends ShapeBorder {
  const _TicketBorder({required this.radius, required this.notch});

  final double radius;
  final _Notch notch;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect, textDirection: textDirection);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final body = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(10)));
    final y = switch (notch) {
      _Notch.top => rect.top,
      _Notch.bottom => rect.bottom,
      _Notch.middle => rect.center.dy,
    };
    final holes = Path()
      ..addOval(Rect.fromCircle(center: Offset(rect.left, y), radius: radius))
      ..addOval(Rect.fromCircle(center: Offset(rect.right, y), radius: radius));
    return Path.combine(PathOperation.difference, body, holes);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) =>
      _TicketBorder(radius: radius * t, notch: notch);
}

class _DottedLinePainter extends CustomPainter {
  _DottedLinePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (var x = 0.0; x < size.width; x += 7) {
      canvas.drawLine(Offset(x, 0), Offset(x + 2.5, 0), p);
    }
  }

  @override
  bool shouldRepaint(_DottedLinePainter old) => old.color != color;
}

// ---------------------------------------------------------------------------
// Glifos Phosphor (MIT). `phosphor_flutter` 2.1.0 no compila con Flutter 3.50
// (IconData ahora es `final`), asi que se empaquetan las fuentes de iconos
// Phosphor-Duotone y Phosphor-Fill (assets/fonts/) y se usan los codigos
// directamente. Ver docs/decisions.md.
// ---------------------------------------------------------------------------

/// Icono duotono: capa principal + capa secundaria (translucida).
class _Duo {
  const _Duo(this.primary, this.secondary);

  final IconData primary;
  final IconData secondary;
}

const _fillMedal = IconData(0xe320, fontFamily: 'PhosphorFill');

abstract final class _D {
  static const horse = _Duo(
    IconData(0xe2b1, fontFamily: 'PhosphorDuotone'),
    IconData(0xe2b0, fontFamily: 'PhosphorDuotone'),
  );
  static const detective = _Duo(
    IconData(0xe83f, fontFamily: 'PhosphorDuotone'),
    IconData(0xe83e, fontFamily: 'PhosphorDuotone'),
  );
  static const brain = _Duo(
    IconData(0xe74f, fontFamily: 'PhosphorDuotone'),
    IconData(0xe74e, fontFamily: 'PhosphorDuotone'),
  );
  static const globeHemisphereWest = _Duo(
    IconData(0xe28d, fontFamily: 'PhosphorDuotone'),
    IconData(0xe28c, fontFamily: 'PhosphorDuotone'),
  );
  static const textAa = _Duo(
    IconData(0xe6ef, fontFamily: 'PhosphorDuotone'),
    IconData(0xe6ee, fontFamily: 'PhosphorDuotone'),
  );
  static const handPointing = _Duo(
    IconData(0xe29b, fontFamily: 'PhosphorDuotone'),
    IconData(0xe29a, fontFamily: 'PhosphorDuotone'),
  );
  static const scales = _Duo(
    IconData(0xe751, fontFamily: 'PhosphorDuotone'),
    IconData(0xe750, fontFamily: 'PhosphorDuotone'),
  );
  static const fingerprint = _Duo(
    IconData(0xe23f, fontFamily: 'PhosphorDuotone'),
    IconData(0xe23e, fontFamily: 'PhosphorDuotone'),
  );
  static const trophy = _Duo(
    IconData(0xe67f, fontFamily: 'PhosphorDuotone'),
    IconData(0xe67e, fontFamily: 'PhosphorDuotone'),
  );
  static const smiley = _Duo(
    IconData(0xe437, fontFamily: 'PhosphorDuotone'),
    IconData(0xe436, fontFamily: 'PhosphorDuotone'),
  );
  static const pepper = _Duo(
    IconData(0xe94b, fontFamily: 'PhosphorDuotone'),
    IconData(0xe94a, fontFamily: 'PhosphorDuotone'),
  );
  static const flame = _Duo(
    IconData(0xe625, fontFamily: 'PhosphorDuotone'),
    IconData(0xe624, fontFamily: 'PhosphorDuotone'),
  );
  static const bank = _Duo(
    IconData(0xe0b5, fontFamily: 'PhosphorDuotone'),
    IconData(0xe0b4, fontFamily: 'PhosphorDuotone'),
  );
  static const flask = _Duo(
    IconData(0xe79f, fontFamily: 'PhosphorDuotone'),
    IconData(0xe79e, fontFamily: 'PhosphorDuotone'),
  );
  static const plant = _Duo(
    IconData(0xebaf, fontFamily: 'PhosphorDuotone'),
    IconData(0xebae, fontFamily: 'PhosphorDuotone'),
  );
  static const paintBrush = _Duo(
    IconData(0xe6f1, fontFamily: 'PhosphorDuotone'),
    IconData(0xe6f0, fontFamily: 'PhosphorDuotone'),
  );
  static const soccerBall = _Duo(
    IconData(0xe717, fontFamily: 'PhosphorDuotone'),
    IconData(0xe716, fontFamily: 'PhosphorDuotone'),
  );
  static const filmSlate = _Duo(
    IconData(0xe8c3, fontFamily: 'PhosphorDuotone'),
    IconData(0xe8c2, fontFamily: 'PhosphorDuotone'),
  );
  static const puzzlePiece = _Duo(
    IconData(0xe597, fontFamily: 'PhosphorDuotone'),
    IconData(0xe596, fontFamily: 'PhosphorDuotone'),
  );
  static const flag = _Duo(
    IconData(0xe245, fontFamily: 'PhosphorDuotone'),
    IconData(0xe244, fontFamily: 'PhosphorDuotone'),
  );
  static const mapPin = _Duo(
    IconData(0xe317, fontFamily: 'PhosphorDuotone'),
    IconData(0xe316, fontFamily: 'PhosphorDuotone'),
  );
  static const mapTrifold = _Duo(
    IconData(0xe31b, fontFamily: 'PhosphorDuotone'),
    IconData(0xe31a, fontFamily: 'PhosphorDuotone'),
  );
  static const shuffle = _Duo(
    IconData(0xe423, fontFamily: 'PhosphorDuotone'),
    IconData(0xe422, fontFamily: 'PhosphorDuotone'),
  );
  static const crown = _Duo(
    IconData(0xe615, fontFamily: 'PhosphorDuotone'),
    IconData(0xe614, fontFamily: 'PhosphorDuotone'),
  );
  static const confetti = _Duo(
    IconData(0xe81b, fontFamily: 'PhosphorDuotone'),
    IconData(0xe81a, fontFamily: 'PhosphorDuotone'),
  );
  static const coins = _Duo(
    IconData(0xe78f, fontFamily: 'PhosphorDuotone'),
    IconData(0xe78e, fontFamily: 'PhosphorDuotone'),
  );
  static const trendDown = _Duo(
    IconData(0xe4ad, fontFamily: 'PhosphorDuotone'),
    IconData(0xe4ac, fontFamily: 'PhosphorDuotone'),
  );
  static const flagCheckered = _Duo(
    IconData(0xea39, fontFamily: 'PhosphorDuotone'),
    IconData(0xea38, fontFamily: 'PhosphorDuotone'),
  );
  static const target = _Duo(
    IconData(0xe47d, fontFamily: 'PhosphorDuotone'),
    IconData(0xe47c, fontFamily: 'PhosphorDuotone'),
  );
  static const deviceMobile = _Duo(
    IconData(0xe1e1, fontFamily: 'PhosphorDuotone'),
    IconData(0xe1e0, fontFamily: 'PhosphorDuotone'),
  );
  static const medal = _Duo(
    IconData(0xe321, fontFamily: 'PhosphorDuotone'),
    IconData(0xe320, fontFamily: 'PhosphorDuotone'),
  );
  static const shareNetwork = _Duo(
    IconData(0xe40b, fontFamily: 'PhosphorDuotone'),
    IconData(0xe408, fontFamily: 'PhosphorDuotone'),
  );
  static const x = _Duo(
    IconData(0xe4f7, fontFamily: 'PhosphorDuotone'),
    IconData(0xe4f6, fontFamily: 'PhosphorDuotone'),
  );
  static const arrowCounterClockwise = _Duo(
    IconData(0xe039, fontFamily: 'PhosphorDuotone'),
    IconData(0xe038, fontFamily: 'PhosphorDuotone'),
  );
  static const arrowUUpLeft = _Duo(
    IconData(0xe08b, fontFamily: 'PhosphorDuotone'),
    IconData(0xe08a, fontFamily: 'PhosphorDuotone'),
  );
  static const pause = _Duo(
    IconData(0xe39f, fontFamily: 'PhosphorDuotone'),
    IconData(0xe39e, fontFamily: 'PhosphorDuotone'),
  );
  static const fastForward = _Duo(
    IconData(0xe6a7, fontFamily: 'PhosphorDuotone'),
    IconData(0xe6a6, fontFamily: 'PhosphorDuotone'),
  );
  static const plus = _Duo(
    IconData(0xe3d5, fontFamily: 'PhosphorDuotone'),
    IconData(0xe3d4, fontFamily: 'PhosphorDuotone'),
  );
  static const minus = _Duo(
    IconData(0xe32b, fontFamily: 'PhosphorDuotone'),
    IconData(0xe32a, fontFamily: 'PhosphorDuotone'),
  );
  static const trash = _Duo(
    IconData(0xe4a7, fontFamily: 'PhosphorDuotone'),
    IconData(0xe4a6, fontFamily: 'PhosphorDuotone'),
  );
  static const gear = _Duo(
    IconData(0xe271, fontFamily: 'PhosphorDuotone'),
    IconData(0xe270, fontFamily: 'PhosphorDuotone'),
  );
  static const speakerHigh = _Duo(
    IconData(0xe44b, fontFamily: 'PhosphorDuotone'),
    IconData(0xe44a, fontFamily: 'PhosphorDuotone'),
  );
  static const speakerSlash = _Duo(
    IconData(0xe45b, fontFamily: 'PhosphorDuotone'),
    IconData(0xe45a, fontFamily: 'PhosphorDuotone'),
  );
  static const shieldCheck = _Duo(
    IconData(0xe40f, fontFamily: 'PhosphorDuotone'),
    IconData(0xe40c, fontFamily: 'PhosphorDuotone'),
  );
  static const question = _Duo(
    IconData(0xe3eb, fontFamily: 'PhosphorDuotone'),
    IconData(0xe3e8, fontFamily: 'PhosphorDuotone'),
  );
  static const info = _Duo(
    IconData(0xe2cf, fontFamily: 'PhosphorDuotone'),
    IconData(0xe2ce, fontFamily: 'PhosphorDuotone'),
  );
  static const tag = _Duo(
    IconData(0xe479, fontFamily: 'PhosphorDuotone'),
    IconData(0xe478, fontFamily: 'PhosphorDuotone'),
  );
  static const arrowSquareOut = _Duo(
    IconData(0xe5df, fontFamily: 'PhosphorDuotone'),
    IconData(0xe5de, fontFamily: 'PhosphorDuotone'),
  );
  static const caretRight = _Duo(
    IconData(0xe13b, fontFamily: 'PhosphorDuotone'),
    IconData(0xe13a, fontFamily: 'PhosphorDuotone'),
  );
  static const caretLeft = _Duo(
    IconData(0xe139, fontFamily: 'PhosphorDuotone'),
    IconData(0xe138, fontFamily: 'PhosphorDuotone'),
  );
  static const check = _Duo(
    IconData(0xe183, fontFamily: 'PhosphorDuotone'),
    IconData(0xe182, fontFamily: 'PhosphorDuotone'),
  );
  static const checkCircle = _Duo(
    IconData(0xe185, fontFamily: 'PhosphorDuotone'),
    IconData(0xe184, fontFamily: 'PhosphorDuotone'),
  );
  static const xCircle = _Duo(
    IconData(0xe4f9, fontFamily: 'PhosphorDuotone'),
    IconData(0xe4f8, fontFamily: 'PhosphorDuotone'),
  );
  static const eye = _Duo(
    IconData(0xe221, fontFamily: 'PhosphorDuotone'),
    IconData(0xe220, fontFamily: 'PhosphorDuotone'),
  );
  static const keyboard = _Duo(
    IconData(0xe2d9, fontFamily: 'PhosphorDuotone'),
    IconData(0xe2d8, fontFamily: 'PhosphorDuotone'),
  );
  static const squaresFour = _Duo(
    IconData(0xe465, fontFamily: 'PhosphorDuotone'),
    IconData(0xe464, fontFamily: 'PhosphorDuotone'),
  );
}

import 'dart:async';
import 'dart:math';

import 'package:material_ui/material_ui.dart';
import '../../../core/audio/app_sound.dart';
import '../../../core/settings/app_feedback.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_icons.dart';
import '../../../app/mascot.dart';
import '../../../app/theme.dart';
import '../../prompt_deck/bounce_in.dart';
import '../abecedario_data.dart';

enum _Phase { thinking, revealed }

class AbecedarioPlayScreen extends ConsumerStatefulWidget {
  const AbecedarioPlayScreen({super.key});

  @override
  ConsumerState<AbecedarioPlayScreen> createState() =>
      _AbecedarioPlayScreenState();
}

class _AbecedarioPlayScreenState extends ConsumerState<AbecedarioPlayScreen> {
  static const _tick = Duration(milliseconds: 100);

  late final AbecedarioSetup _setup = ref.read(abecedarioSetupProvider);
  List<AbecedarioEntry>? _entries;
  int _index = 0;
  bool _finished = false;
  bool _paused = false;
  _Phase _phase = _Phase.thinking;
  int _elapsedMs = 0;
  Timer? _timer;

  AbecedarioEntry get _entry => _entries![_index];
  int get _phaseMs =>
      (_phase == _Phase.thinking ? _setup.seconds : _setup.readSeconds) * 1000;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _begin(List<AbecedarioEntry> bank) {
    setState(
      () => _entries = generateAbecedario(bank, Random(), level: _setup.level),
    );
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(_tick, (_) {
      if (_paused || !mounted) return;
      final before = _elapsedMs;
      setState(() => _elapsedMs += _tick.inMilliseconds);
      if (_phase == _Phase.thinking) {
        // Un toque suave en cada uno de los últimos 3 segundos.
        final left = _phaseMs - _elapsedMs;
        if (left > 0 &&
            left <= 3000 &&
            (before ~/ 1000) != (_elapsedMs ~/ 1000)) {
          AppFeedback.selection();
        }
        if (_elapsedMs >= _phaseMs) _reveal();
      } else if (_setup.auto && _elapsedMs >= _phaseMs) {
        _next();
      }
    });
  }

  void _reveal() {
    AppFeedback.medium();
    playSound(AppSound.card);
    setState(() {
      _phase = _Phase.revealed;
      _elapsedMs = 0;
    });
  }

  void _next() {
    if (_index + 1 >= _entries!.length) {
      _timer?.cancel();
      AppFeedback.medium();
      playSound(AppSound.podium);
      setState(() => _finished = true);
      return;
    }
    setState(() {
      _index++;
      _phase = _Phase.thinking;
      _elapsedMs = 0;
    });
  }

  void _restart() {
    setState(() {
      _entries = generateAbecedario(
        ref.read(abecedarioBankProvider).requireValue,
        Random(),
        level: _setup.level,
      );
      _index = 0;
      _finished = false;
      _phase = _Phase.thinking;
      _elapsedMs = 0;
    });
    _startTimer();
  }

  Future<void> _exit() async {
    if (_finished) {
      context.go('/');
      return;
    }
    _paused = true;
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Salir de la partida?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Seguir'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    _paused = false;
    if (leave == true && mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    if (_entries == null) {
      return ref
          .watch(abecedarioBankProvider)
          .when(
            loading: () => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => Scaffold(
              appBar: AppBar(),
              body: Center(
                child: Text(
                  'No se pudo cargar el contenido. Vuelve atrás e inténtalo de nuevo.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            data: (b) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _entries == null) _begin(b);
              });
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            },
          );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _exit();
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Salir',
                      onPressed: _exit,
                      icon: AppIcon.close.widget(),
                    ),
                    const Spacer(),
                  ],
                ),
                Expanded(
                  child: _finished
                      ? _Finished(onAgain: _restart)
                      : _buildRound(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// La definición se encoge según su longitud para caber siempre en su hueco sin mover el abecedario.
  static double _definitionSize(int length) => switch (length) {
    <= 55 => 32,
    <= 90 => 28,
    <= 120 => 25,
    _ => 22,
  };

  Widget _buildRound() {
    final revealed = _phase == _Phase.revealed;
    final leftMs = (_phaseMs - _elapsedMs).clamp(0, _phaseMs);
    final seconds = (leftMs / 1000).ceil();
    final progress = _phaseMs == 0 ? 0.0 : _elapsedMs / _phaseMs;

    return Column(
      children: [
        // Abecedario arriba, lo más grande que quepa (deja sitio a la definición, la respuesta y el botón).
        LayoutBuilder(
          builder: (context, box) {
            // Con letra grande del sistema, el abecedario cede sitio a la tarjeta.
            final big = MediaQuery.textScalerOf(context).scale(10) > 13;
            final room = MediaQuery.sizeOf(context).height * (big ? 0.3 : 0.36);
            return _Abecedario(
              size: room,
              index: _index,
              letter: _entry.letter,
              seconds: revealed ? null : seconds,
              progress: revealed ? 1 : progress,
            );
          },
        ),
        // Tarjeta central: ocupa todo el espacio libre. Etiqueta fija arriba, definición grande en el
        // medio y hueco fijo para la respuesta abajo, así que al desvelarla no se mueve nada.
        const SizedBox(height: 14),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.outline),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: abecedarioColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _entry.clue.toUpperCase(),
                      style: const TextStyle(
                        color: abecedarioColor,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.4,
                        fontSize: 22,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Text(
                        _entry.definition,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: _definitionSize(_entry.definition.length),
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 64,
                  width: double.infinity,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (c, a) => FadeTransition(
                      opacity: a,
                      child: ScaleTransition(
                        scale: Tween(begin: 0.9, end: 1.0).animate(a),
                        child: c,
                      ),
                    ),
                    child: revealed
                        ? Container(
                            key: const ValueKey('answer'),
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(horizontal: 22),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.success,
                                width: 2,
                              ),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _entry.answer.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(key: ValueKey('hidden')),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        // Barra de lectura (solo en automático) y botón: ocupan siempre el mismo sitio.
        SizedBox(
          height: 6,
          child: revealed && _setup.auto
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: 1 - progress,
                    color: abecedarioColor,
                    backgroundColor: AppColors.surfaceHigh,
                  ),
                )
              : null,
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: revealed
              ? FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: abecedarioColor,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: _next,
                  child: Text(
                    _index + 1 >= _entries!.length ? 'Terminar' : 'Siguiente',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                )
              : OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: abecedarioColor,
                    side: const BorderSide(color: abecedarioColor),
                  ),
                  onPressed: _reveal,
                  child: const Text(
                    'Desvelar ya',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                ),
        ),
      ],
    );
  }
}

/// Cuadrícula A–Z de progreso y, debajo, la letra actual con su cuenta atrás.
class _Abecedario extends StatelessWidget {
  const _Abecedario({
    required this.size,
    required this.index,
    required this.letter,
    required this.seconds,
    required this.progress,
  });

  /// Alto máximo disponible.
  final double size;
  final int index;
  final String letter;

  /// `null` cuando ya se ha desvelado la respuesta.
  final int? seconds;
  final double progress;

  static const _columns = 9;

  @override
  Widget build(BuildContext context) {
    final ring = min(size * 0.5, 130.0);
    final danger = seconds != null && seconds! <= 3;
    return SizedBox(
      height: size,
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, box) {
              const gap = 5.0;
              final cell = (box.maxWidth - gap * (_columns - 1)) / _columns;
              return Semantics(
                label: 'Letra ${index + 1} de ${abecedarioLetters.length}',
                excludeSemantics: true,
                child: Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (var i = 0; i < abecedarioLetters.length; i++)
                      _Tile(
                        letter: abecedarioLetters[i],
                        size: cell,
                        state: i == index
                            ? LetterChipState.current
                            : i < index
                            ? LetterChipState.done
                            : LetterChipState.pending,
                      ),
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: Center(
              child: SizedBox(
                width: ring,
                height: ring,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: 1 - progress.clamp(0.0, 1.0),
                        strokeWidth: 8,
                        strokeCap: StrokeCap.round,
                        color: danger ? AppColors.danger : abecedarioColor,
                        backgroundColor: AppColors.surfaceHigh,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // La letra es ilustración: no escala con el texto del sistema.
                        Text(
                          letter,
                          textScaler: TextScaler.noScaling,
                          style: TextStyle(
                            fontFamily: AppFonts.display,
                            fontWeight: FontWeight.w400,
                            fontSize: ring * 0.42,
                            color: AppColors.gold,
                            height: 1,
                          ),
                        ),
                        // El hueco del número se conserva al desvelar para que la letra no se mueva.
                        Opacity(
                          opacity: seconds == null ? 0 : 1,
                          child: Text(
                            '${seconds ?? 0}',
                            style: TextStyle(
                              fontSize: ring * 0.15,
                              fontWeight: FontWeight.w800,
                              color: danger
                                  ? AppColors.danger
                                  : AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Baldosa del abecedario: una ficha dibujada con la letra. La actual rebota
/// al llegar su turno (salvo con "quitar animaciones").
class _Tile extends StatelessWidget {
  const _Tile({required this.letter, required this.size, required this.state});

  final String letter;
  final double size;
  final LetterChipState state;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return AnimatedScale(
      scale: state == LetterChipState.current ? 1.14 : 1,
      duration: reduce ? Duration.zero : const Duration(milliseconds: 420),
      curve: Curves.elasticOut,
      child: LetterChip(letter, size: size, state: state),
    );
  }
}

enum LetterChipState { pending, done, current }

/// Ficha de letra dibujada con la paleta de la casa: pendiente (fieltro con aro
/// apagado), hecha (burdeos con aro de papel) y actual (oro con brillo).
/// La letra va en Alfa Slab One y no escala con el texto del sistema.
class LetterChip extends StatelessWidget {
  const LetterChip(
    this.letter, {
    super.key,
    required this.size,
    this.state = LetterChipState.pending,
  });

  final String letter;
  final double size;
  final LetterChipState state;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _LetterChipPainter(letter, state)),
    );
  }
}

class _LetterChipPainter extends CustomPainter {
  _LetterChipPainter(this.letter, this.state);

  final String letter;
  final LetterChipState state;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final (disc, rim, ink) = switch (state) {
      LetterChipState.pending => (
        AppColors.surface,
        AppColors.outline,
        AppColors.textMuted,
      ),
      LetterChipState.done => (
        AppColors.burgundy,
        AppColors.brass,
        AppColors.paper,
      ),
      LetterChipState.current => (
        AppColors.gold,
        AppColors.brass,
        const Color(0xFF241A00),
      ),
    };

    if (state == LetterChipState.current) {
      canvas.drawCircle(
        c,
        r * 1.05,
        Paint()
          ..color = AppColors.gold.withValues(alpha: 0.55)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
    canvas.drawCircle(c, r, Paint()..color = rim);
    canvas.drawCircle(c, r * 0.9, Paint()..color = disc);

    // Aro punteado: solo si la ficha es lo bastante grande para que se lea.
    if (state != LetterChipState.pending && size.shortestSide >= 24) {
      final dash = Paint()
        ..color = ink.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.1;
      const n = 14;
      for (var i = 0; i < n; i++) {
        canvas.drawArc(
          Rect.fromCircle(center: c, radius: r * 0.74),
          i * 2 * pi / n,
          pi / n,
          false,
          dash,
        );
      }
    }

    final tp = TextPainter(
      text: TextSpan(
        text: letter,
        style: TextStyle(
          fontFamily: AppFonts.display,
          fontWeight: FontWeight.w400,
          fontSize: r * 0.92,
          height: 1,
          color: ink,
        ),
      ),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
    )..layout();
    tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_LetterChipPainter old) =>
      old.letter != letter || old.state != state;
}

class _Finished extends StatelessWidget {
  const _Finished({required this.onAgain});
  final VoidCallback onAgain;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: box.hasBoundedHeight ? box.maxHeight : 0,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BounceIn(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const LetterChip(
                      'A',
                      size: 48,
                      state: LetterChipState.done,
                    ),
                    const SizedBox(width: 8),
                    const Jockey(pose: JockeyPose.celebra, size: 96),
                    const SizedBox(width: 8),
                    const LetterChip(
                      'Z',
                      size: 48,
                      state: LetterChipState.current,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Llegasteis a la Z',
                textAlign: TextAlign.center,
                textScaler: MediaQuery.textScalerOf(
                  context,
                ).clamp(maxScaleFactor: 1.5),
                style: const TextStyle(
                  fontFamily: AppFonts.display,
                  fontWeight: FontWeight.w400,
                  fontSize: 28,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.go('/'),
                      child: const Text('Menú'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: abecedarioColor,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: onAgain,
                      child: const Text('Otra vuelta'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

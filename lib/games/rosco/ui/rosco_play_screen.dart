import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../rosco_data.dart';

enum _Phase { thinking, revealed }

class RoscoPlayScreen extends ConsumerStatefulWidget {
  const RoscoPlayScreen({super.key});

  @override
  ConsumerState<RoscoPlayScreen> createState() => _RoscoPlayScreenState();
}

class _RoscoPlayScreenState extends ConsumerState<RoscoPlayScreen> {
  static const _tick = Duration(milliseconds: 100);

  late final RoscoSetup _setup = ref.read(roscoSetupProvider);
  List<RoscoEntry>? _entries;
  int _index = 0;
  bool _finished = false;
  bool _paused = false;
  _Phase _phase = _Phase.thinking;
  int _elapsedMs = 0;
  Timer? _timer;

  RoscoEntry get _entry => _entries![_index];
  int get _phaseMs => (_phase == _Phase.thinking ? _setup.seconds : _setup.readSeconds) * 1000;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _begin(List<RoscoEntry> bank) {
    setState(() => _entries = generateRosco(bank, Random(), level: _setup.level));
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
        if (left > 0 && left <= 3000 && (before ~/ 1000) != (_elapsedMs ~/ 1000)) HapticFeedback.selectionClick();
        if (_elapsedMs >= _phaseMs) _reveal();
      } else if (_setup.auto && _elapsedMs >= _phaseMs) {
        _next();
      }
    });
  }

  void _reveal() {
    HapticFeedback.mediumImpact();
    setState(() {
      _phase = _Phase.revealed;
      _elapsedMs = 0;
    });
  }

  void _next() {
    if (_index + 1 >= _entries!.length) {
      _timer?.cancel();
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
      _entries = generateRosco(ref.read(roscoBankProvider).requireValue, Random(), level: _setup.level);
      _index = 0;
      _finished = false;
      _phase = _Phase.thinking;
      _elapsedMs = 0;
    });
    _startTimer();
  }

  Future<void> _exit() async {
    if (_finished) {
      context.pop();
      return;
    }
    _paused = true;
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Salir de la partida?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Seguir')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Salir')),
        ],
      ),
    );
    _paused = false;
    if (leave == true && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_entries == null) {
      return ref.watch(roscoBankProvider).when(
            loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
            error: (e, _) => Scaffold(appBar: AppBar(), body: Center(child: Text('No se pudo cargar: $e'))),
            data: (b) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _entries == null) _begin(b);
              });
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
                    IconButton(onPressed: _exit, icon: const Icon(Icons.close_rounded)),
                    const Spacer(),
                    if (!_finished)
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Text('${_index + 1}/${_entries!.length}',
                            style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textMuted)),
                      ),
                  ],
                ),
                Expanded(child: _finished ? _Finished(onAgain: _restart) : _buildRound()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// La definición se encoge según su longitud para caber siempre en su hueco sin mover el rosco.
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
        // Rosco arriba, lo más grande que quepa (deja sitio a la definición, la respuesta y el botón).
        LayoutBuilder(
          builder: (context, box) {
            final room = MediaQuery.sizeOf(context).height * 0.42;
            return _Rosco(
              size: min(min(box.maxWidth, 340.0), room),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: roscoColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(_entry.clue.toUpperCase(),
                      style: const TextStyle(
                          color: roscoColor, fontWeight: FontWeight.w900, letterSpacing: 1.4, fontSize: 22)),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Text(_entry.definition,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: _definitionSize(_entry.definition.length),
                              fontWeight: FontWeight.w700,
                              height: 1.3)),
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
                      child: ScaleTransition(scale: Tween(begin: 0.9, end: 1.0).animate(a), child: c),
                    ),
                    child: revealed
                        ? Container(
                            key: const ValueKey('answer'),
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(horizontal: 22),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.success, width: 2),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(_entry.answer.toUpperCase(),
                                  style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
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
                      value: 1 - progress, color: roscoColor, backgroundColor: AppColors.surfaceHigh),
                )
              : null,
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: revealed
              ? FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: roscoColor, foregroundColor: Colors.black),
                  onPressed: _next,
                  child: Text(_index + 1 >= _entries!.length ? 'Terminar' : 'Siguiente',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                )
              : OutlinedButton(
                  style: OutlinedButton.styleFrom(
                      foregroundColor: roscoColor, side: const BorderSide(color: roscoColor)),
                  onPressed: _reveal,
                  child: const Text('Desvelar ya', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                ),
        ),
      ],
    );
  }
}

/// El rosco: las 27 letras en círculo y, en el centro, la letra actual con la cuenta atrás.
class _Rosco extends StatelessWidget {
  const _Rosco({
    required this.size,
    required this.index,
    required this.letter,
    required this.seconds,
    required this.progress,
  });

  final double size;
  final int index;
  final String letter;

  /// `null` cuando ya se ha desvelado la respuesta.
  final int? seconds;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final bubble = size * 0.088;
    final radius = size / 2 - bubble / 2 - 2;
    final inner = (radius - bubble) * 2;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: inner,
            height: inner,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: 1 - progress.clamp(0.0, 1.0),
                    strokeWidth: 8,
                    strokeCap: StrokeCap.round,
                    color: seconds != null && seconds! <= 3 ? AppColors.danger : roscoColor,
                    backgroundColor: AppColors.surfaceHigh,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(letter, style: TextStyle(fontSize: inner * 0.38, fontWeight: FontWeight.w900, height: 1)),
                    // El hueco del número se conserva al desvelar para que la letra no se mueva.
                    Opacity(
                      opacity: seconds == null ? 0 : 1,
                      child: Text('${seconds ?? 0}',
                          style: TextStyle(
                              fontSize: inner * 0.14,
                              fontWeight: FontWeight.w800,
                              color: (seconds ?? 9) <= 3 ? AppColors.danger : AppColors.textMuted)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          for (var i = 0; i < roscoLetters.length; i++)
            Positioned(
              left: size / 2 + radius * cos(-pi / 2 + 2 * pi * i / roscoLetters.length) - bubble / 2,
              top: size / 2 + radius * sin(-pi / 2 + 2 * pi * i / roscoLetters.length) - bubble / 2,
              child: _Bubble(letter: roscoLetters[i], size: bubble, done: i < index, current: i == index),
            ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.letter, required this.size, required this.done, required this.current});

  final String letter;
  final double size;
  final bool done;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final fill = current
        ? roscoColor
        : done
            ? roscoColor.withValues(alpha: 0.28)
            : AppColors.surface;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fill,
        border: Border.all(color: current ? Colors.white : AppColors.outline, width: current ? 2 : 1),
        boxShadow: current ? [BoxShadow(color: roscoColor.withValues(alpha: 0.6), blurRadius: 10)] : null,
      ),
      child: Text(letter,
          style: TextStyle(
              fontSize: size * 0.5,
              fontWeight: FontWeight.w800,
              color: current ? Colors.black : (done ? AppColors.textMuted : AppColors.text))),
    );
  }
}

class _Finished extends StatelessWidget {
  const _Finished({required this.onAgain});
  final VoidCallback onAgain;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🔤', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 12),
          const Text('¡Rosco completo!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: () => context.go('/'), child: const Text('Menú'))),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: roscoColor, foregroundColor: Colors.black),
                  onPressed: onAgain,
                  child: const Text('Otra vez'),
                ),
              ),
            ],
          ),
        ],
      );
}

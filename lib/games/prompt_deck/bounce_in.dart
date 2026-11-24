import 'package:material_ui/material_ui.dart';

/// Entrada con rebote (escala) de un elemento de ceremonia. Con "quitar
/// animaciones" activado en el sistema, se muestra sin animar.
class BounceIn extends StatelessWidget {
  const BounceIn({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, v, child) =>
          Transform.scale(scale: 0.3 + 0.7 * v, child: child),
      child: child,
    );
  }
}

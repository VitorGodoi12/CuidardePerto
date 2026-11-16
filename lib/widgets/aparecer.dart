import 'package:flutter/material.dart';

class Aparecer extends StatelessWidget {
  const Aparecer({super.key, required this.child, this.ordem = 0});

  final Widget child;

  final int ordem;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return child;
    final atraso = ordem > 4 ? 4 : ordem;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + atraso * 90),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, valor, filho) => Opacity(
        opacity: valor,
        child: Transform.translate(offset: Offset(0, 12 * (1 - valor)), child: filho),
      ),
    );
  }
}

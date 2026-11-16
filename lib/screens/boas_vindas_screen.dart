import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/logo_cuidar.dart';
import 'cadastro_cuidador_screen.dart';
import 'login_screen.dart';

class BoasVindasScreen extends StatelessWidget {
  const BoasVindasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tamanho = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF087F82), Color(0xFF10AAA7), Color(0xFF55D4BE)],
              ),
            ),
          ),
          Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _OndasPainter()))),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 440, minHeight: tamanho.height * .82),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const LogoCuidar(tamanho: 112, cor: Colors.white),
                      const SizedBox(height: 25),
                      const Text(
                        'Cuidar\nde Perto',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 35, height: 1.02, fontWeight: FontWeight.w900, letterSpacing: -.9),
                      ),
                      const SizedBox(height: 13),
                      Text(
                        'Seu cuidado, nossa prioridade',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white.withValues(alpha: .96), fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 24),
                      const Icon(Icons.favorite_rounded, color: Colors.white, size: 22),
                      const SizedBox(height: 54),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primariaEscura,
                            elevation: 4,
                            shadowColor: const Color(0x44004444),
                            shape: const StadiumBorder(),
                          ),
                          child: const Text('Entrar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                        ),
                      ),
                      const SizedBox(height: 13),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: OutlinedButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CadastroCuidadorScreen())),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white, width: 1.3),
                            shape: const StadiumBorder(),
                          ),
                          child: const Text('Cadastrar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                        ),
                      ),
                      const SizedBox(height: 42),
                      Text(
                        'Cuidando de quem você ama ♡',
                        style: TextStyle(color: Colors.white.withValues(alpha: .92), fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OndasPainter extends CustomPainter {
  const _OndasPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final tinta = Paint()..style = PaintingStyle.fill;
    final ondaSuperior = Path()
      ..moveTo(size.width * .58, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * .28)
      ..cubicTo(size.width * .82, size.height * .22, size.width * .78, size.height * .08, size.width * .58, 0)
      ..close();
    tinta.color = Colors.white.withValues(alpha: .08);
    canvas.drawPath(ondaSuperior, tinta);

    final ondaInferior = Path()
      ..moveTo(0, size.height * .73)
      ..cubicTo(size.width * .20, size.height * .62, size.width * .27, size.height * .88, size.width * .51, size.height * .83)
      ..cubicTo(size.width * .72, size.height * .78, size.width * .82, size.height * .91, size.width, size.height * .77)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    tinta.color = Colors.white.withValues(alpha: .10);
    canvas.drawPath(ondaInferior, tinta);

    tinta.color = const Color(0xFF006F73).withValues(alpha: .10);
    canvas.drawCircle(Offset(size.width * .98, size.height * .55), size.width * .19, tinta);
    canvas.drawCircle(Offset(size.width * .02, size.height * .34), size.width * .16, tinta);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

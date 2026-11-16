import 'package:flutter/material.dart';

/// Marca do aplicativo usando o símbolo original e o detalhe de saúde (+).
class LogoCuidar extends StatelessWidget {
  const LogoCuidar({super.key, required this.tamanho, required this.cor});

  final double tamanho;
  final Color cor;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: tamanho,
    height: tamanho,
    child: Stack(clipBehavior: Clip.none, children: [
      Positioned.fill(child: ColorFiltered(
        colorFilter: ColorFilter.mode(cor, BlendMode.srcIn),
        child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
      )),
      Positioned(
        right: tamanho * .02,
        top: tamanho * .02,
        child: Icon(Icons.add_rounded, color: cor, size: tamanho * .31),
      ),
    ]),
  );
}

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'logo_cuidar.dart';

/// Fundo das telas de acesso: branco com folhas suaves em verde-menta,
/// como na referência visual.
class FundoAcesso extends StatelessWidget {
  const FundoAcesso({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(children: [
        Positioned(
          right: -70,
          top: -40,
          child: IgnorePointer(
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(color: AppColors.menta.withValues(alpha: .35), shape: BoxShape.circle),
            ),
          ),
        ),
        Positioned(
          left: -90,
          bottom: -60,
          child: IgnorePointer(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(color: AppColors.menta.withValues(alpha: .25), shape: BoxShape.circle),
            ),
          ),
        ),
        child,
      ]);
}

/// Estrutura comum: seta de voltar, conteúdo centralizado e rolável.
class TelaAcesso extends StatelessWidget {
  const TelaAcesso({super.key, required this.children, this.voltar = true});
  final List<Widget> children;
  final bool voltar;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        body: FundoAcesso(
          child: SafeArea(
            child: Column(children: [
              if (voltar)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(6, 4, 0, 0),
                    child: IconButton(
                      tooltip: 'Voltar',
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => Navigator.maybePop(context),
                    ),
                  ),
                )
              else
                const SizedBox(height: 12),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ),
      );
}

/// Logo + nome em duas linhas, como no topo da tela de login.
class MarcaAcesso extends StatelessWidget {
  const MarcaAcesso({super.key, this.tamanho = 70});
  final double tamanho;

  @override
  Widget build(BuildContext context) => Column(children: [
        LogoCuidar(tamanho: tamanho, cor: AppColors.primaria),
        const SizedBox(height: 6),
        const Text(
          'Cuidar\nde Perto',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.primariaEscura, fontSize: 24, height: 1.02, fontWeight: FontWeight.w900, letterSpacing: -.5),
        ),
      ]);
}

/// Botão principal arredondado com indicador de carregamento.
/// Enquanto `carregando` é verdadeiro o botão fica desabilitado (impede cliques repetidos).
class BotaoCarregando extends StatelessWidget {
  const BotaoCarregando({
    super.key,
    required this.texto,
    required this.onPressed,
    this.carregando = false,
    this.icone,
    this.iconeAoFinal = true,
    this.claro = false,
  });

  final String texto;
  final VoidCallback? onPressed;
  final bool carregando;
  final IconData? icone;
  final bool iconeAoFinal;

  /// Variante branca (para fundos turquesa).
  final bool claro;

  @override
  Widget build(BuildContext context) {
    final corTexto = claro ? AppColors.primariaEscura : Colors.white;
    final conteudo = carregando
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.6, color: corTexto),
          )
        : Row(mainAxisSize: MainAxisSize.min, children: [
            if (icone != null && !iconeAoFinal) ...[Icon(icone, size: 20), const SizedBox(width: 8)],
            Text(texto),
            if (icone != null && iconeAoFinal) ...[const SizedBox(width: 8), Icon(icone, size: 20)],
          ]);
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: carregando ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: claro ? Colors.white : AppColors.primariaEscura,
          foregroundColor: corTexto,
          disabledBackgroundColor: claro ? Colors.white70 : AppColors.primaria.withValues(alpha: .75),
          disabledForegroundColor: corTexto,
          shape: const StadiumBorder(),
          elevation: 2,
          shadowColor: AppColors.primaria.withValues(alpha: .25),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        child: conteudo,
      ),
    );
  }
}

/// Faixa com a palavra "ou" entre duas linhas.
class DivisorOu extends StatelessWidget {
  const DivisorOu({super.key});

  @override
  Widget build(BuildContext context) => const Row(children: [
        Expanded(child: Divider(color: AppColors.borda)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Text('ou', style: TextStyle(color: AppColors.textoSuave, fontSize: 13)),
        ),
        Expanded(child: Divider(color: AppColors.borda)),
      ]);
}

/// Aviso em destaque dentro das telas (erro, sucesso ou informação).
class AvisoInline extends StatelessWidget {
  const AvisoInline({super.key, required this.texto, this.erro = false, this.icone});
  final String texto;
  final bool erro;
  final IconData? icone;

  @override
  Widget build(BuildContext context) {
    final cor = erro ? AppColors.erroEscuro : AppColors.primariaEscura;
    final fundo = erro ? const Color(0xFFFEECEC) : AppColors.verdeSuave;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: fundo, borderRadius: BorderRadius.circular(16)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icone ?? (erro ? Icons.error_outline_rounded : Icons.info_outline_rounded), color: cor, size: 22),
        const SizedBox(width: 10),
        Expanded(child: Text(texto, style: TextStyle(fontSize: 13.5, height: 1.35, color: cor, fontWeight: FontWeight.w600))),
      ]),
    );
  }
}


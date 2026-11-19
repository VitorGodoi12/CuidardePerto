import 'package:flutter/material.dart';

import '../state/sessao.dart';
import '../theme/app_theme.dart';
import '../widgets/logo_cuidar.dart';

/// Experiência de boas-vindas exibida uma única vez por cuidador.
class PrimeiroAcessoScreen extends StatefulWidget {
  const PrimeiroAcessoScreen({super.key});

  @override
  State<PrimeiroAcessoScreen> createState() => _PrimeiroAcessoScreenState();
}

class _PrimeiroAcessoScreenState extends State<PrimeiroAcessoScreen> {
  bool _salvando = false;

  Future<void> _concluir(AcaoInicial acao) async {
    if (_salvando) return;
    final sessao = SessaoScope.leitura(context);
    setState(() => _salvando = true);
    try {
      await sessao.concluirPrimeiroAcesso(acao: acao);
    } catch (_) {
      if (mounted) {
        setState(() => _salvando = false);
        Mensagens.erro(context, 'Não foi possível salvar agora. Verifique a conexão e tente novamente.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final nome = SessaoScope.of(context).perfil?.primeiroNome ?? '';
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF087F82), Color(0xFF10AAA7), Color(0xFF55D4BE)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const Center(child: LogoCuidar(tamanho: 84, cor: Colors.white)),
                  const SizedBox(height: 22),
                  Text(
                    nome.isEmpty ? 'Bem-vindo ao Cuidar de Perto!' : 'Bem-vindo ao Cuidar de Perto, $nome!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 28, height: 1.1, fontWeight: FontWeight.w900, letterSpacing: -.6),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Estamos aqui para ajudar você a cuidar de quem mais importa. Vamos começar?',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withValues(alpha: .95), fontSize: 15.5, height: 1.4, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 28),
                  _Opcao(
                    icone: Icons.person_add_alt_1_rounded,
                    titulo: 'Cadastrar o primeiro idoso',
                    subtitulo: 'Comece a acompanhar quem você cuida',
                    onTap: _salvando ? null : () => _concluir(AcaoInicial.cadastrarIdoso),
                  ),
                  const SizedBox(height: 12),
                  _Opcao(
                    icone: Icons.explore_outlined,
                    titulo: 'Conhecer as funcionalidades',
                    subtitulo: 'Veja o que o aplicativo faz por você',
                    onTap: _salvando ? null : () => _concluir(AcaoInicial.conhecerFuncionalidades),
                  ),
                  const SizedBox(height: 12),
                  _Opcao(
                    icone: Icons.notifications_active_outlined,
                    titulo: 'Configurar lembretes e notificações',
                    subtitulo: 'Escolha quais avisos deseja receber',
                    onTap: _salvando ? null : () => _concluir(AcaoInicial.configurarNotificacoes),
                  ),
                  const SizedBox(height: 22),
                  if (_salvando)
                    const Center(child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)))
                  else
                    TextButton(
                      onPressed: () => _concluir(AcaoInicial.nenhuma),
                      style: TextButton.styleFrom(foregroundColor: Colors.white),
                      child: const Text('Ir para o início', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, decoration: TextDecoration.underline)),
                    ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Opcao extends StatelessWidget {
  const _Opcao({required this.icone, required this.titulo, required this.subtitulo, required this.onTap});
  final IconData icone;
  final String titulo;
  final String subtitulo;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        elevation: 3,
        shadowColor: const Color(0x33004444),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(color: AppColors.verdeSuave, shape: BoxShape.circle),
                child: Icon(icone, color: AppColors.primariaEscura, size: 24),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(titulo, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.texto)),
                  const SizedBox(height: 2),
                  Text(subtitulo, style: const TextStyle(fontSize: 12.5, color: AppColors.textoSuave)),
                ]),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textoSuave, size: 26),
            ]),
          ),
        ),
      );
}

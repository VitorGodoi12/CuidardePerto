import 'package:flutter/material.dart';

import '../state/sessao.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/logo_cuidar.dart';
import 'boas_vindas_screen.dart';
import 'painel_familiar_screen.dart';
import 'painel_screen.dart';
import 'primeiro_acesso_screen.dart';
import 'verificar_email_screen.dart';

/// Decide qual tela mostrar conforme o estado real da sessão.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final sessao = SessaoScope.of(context);
    switch (sessao.status) {
      case StatusSessao.iniciando:
        return const _Carregando();
      case StatusSessao.deslogado:
        return const BoasVindasScreen();
      case StatusSessao.verificandoEmail:
        return const VerificarEmailScreen();
      case StatusSessao.primeiroAcesso:
        return const PrimeiroAcessoScreen();
      case StatusSessao.autenticado:
        // A chave por usuário garante estado novo quando outro cuidador entra.
        if (sessao.perfil?.familiar == true) {
          return PainelFamiliarScreen(key: ValueKey(sessao.perfil!.uid), sessao: sessao);
        }
        return PainelScreen(key: ValueKey(sessao.perfil?.uid));
      case StatusSessao.erro:
        return const _ErroCarregamento();
    }
  }
}

class _Carregando extends StatelessWidget {
  const _Carregando();

  @override
  Widget build(BuildContext context) => const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            LogoCuidar(tamanho: 84, cor: AppColors.primaria),
            SizedBox(height: 24),
            SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 3)),
          ]),
        ),
      );
}

class _ErroCarregamento extends StatefulWidget {
  const _ErroCarregamento();

  @override
  State<_ErroCarregamento> createState() => _ErroCarregamentoState();
}

class _ErroCarregamentoState extends State<_ErroCarregamento> {
  bool _tentando = false;

  @override
  Widget build(BuildContext context) {
    final sessao = SessaoScope.of(context);
    return TelaAcesso(voltar: false, children: [
      const Center(child: Icon(Icons.cloud_off_rounded, size: 64, color: AppColors.primaria)),
      const SizedBox(height: 18),
      const Text('Não foi possível carregar seus dados',
          textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.texto)),
      const SizedBox(height: 10),
      AvisoInline(texto: sessao.mensagemErro ?? 'Tente novamente em instantes.', erro: true),
      const SizedBox(height: 20),
      BotaoCarregando(
        texto: 'Tentar novamente',
        carregando: _tentando,
        icone: Icons.refresh_rounded,
        iconeAoFinal: false,
        onPressed: () async {
          setState(() => _tentando = true);
          await sessao.tentarNovamente();
          if (mounted) setState(() => _tentando = false);
        },
      ),
      const SizedBox(height: 12),
      TextButton(onPressed: sessao.sair, child: const Text('Sair da conta')),
    ]);
  }
}

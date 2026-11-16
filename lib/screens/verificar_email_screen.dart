import 'dart:async';

import 'package:flutter/material.dart';

import '../services/auth_repository.dart';
import '../state/sessao.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_widgets.dart';

/// Exibida enquanto a conta de e-mail/senha ainda não confirmou o endereço.
/// O estado de verificação pertence ao fluxo demonstrativo local.
class VerificarEmailScreen extends StatefulWidget {
  const VerificarEmailScreen({super.key});

  @override
  State<VerificarEmailScreen> createState() => _VerificarEmailScreenState();
}

class _VerificarEmailScreenState extends State<VerificarEmailScreen> with WidgetsBindingObserver {
  static const int _espera = 60;

  bool _verificando = false;
  bool _reenviando = false;
  int _restante = 0;
  Timer? _contagem;
  String? _aviso;
  bool _avisoErro = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _contagem?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    // Ao voltar do aplicativo de e-mail, confere sozinho se o link foi aberto.
    if (estado == AppLifecycleState.resumed && !_verificando) _atualizar(silencioso: true);
  }

  Future<void> _atualizar({bool silencioso = false}) async {
    if (_verificando) return;
    final sessao = SessaoScope.leitura(context);
    setState(() {
      _verificando = true;
      if (!silencioso) _aviso = null;
    });
    try {
      final verificado = await sessao.atualizarVerificacao();
      if (!mounted) return;
      if (!verificado && !silencioso) {
        setState(() {
          _aviso = 'Seu e-mail ainda não foi verificado. Abra o link que enviamos e toque em "Já verifiquei".';
          _avisoErro = true;
        });
      }
    } on AuthFalha catch (f) {
      if (mounted && !silencioso) setState(() {
        _aviso = f.mensagem;
        _avisoErro = true;
      });
    } catch (_) {
      if (mounted && !silencioso) setState(() {
        _aviso = 'Não foi possível verificar agora. Tente novamente.';
        _avisoErro = true;
      });
    } finally {
      if (mounted) setState(() => _verificando = false);
    }
  }

  Future<void> _reenviar() async {
    if (_reenviando || _restante > 0) return;
    final sessao = SessaoScope.leitura(context);
    setState(() {
      _reenviando = true;
      _aviso = null;
    });
    try {
      await sessao.reenviarVerificacao();
      if (!mounted) return;
      setState(() {
        _aviso = 'E-mail de verificação reenviado. Confira também a caixa de spam.';
        _avisoErro = false;
      });
      _contagem?.cancel();
      setState(() => _restante = _espera);
      _contagem = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return t.cancel();
        setState(() => _restante--);
        if (_restante <= 0) t.cancel();
      });
    } on AuthFalha catch (f) {
      if (mounted) setState(() {
        _aviso = f.mensagem;
        _avisoErro = true;
      });
    } catch (_) {
      if (mounted) setState(() {
        _aviso = 'Não foi possível reenviar agora. Tente novamente.';
        _avisoErro = true;
      });
    } finally {
      if (mounted) setState(() => _reenviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessao = SessaoScope.of(context);
    final email = sessao.usuario?.email ?? '';
    return TelaAcesso(voltar: false, children: [
      Center(
        child: Container(
          width: 104,
          height: 104,
          decoration: const BoxDecoration(color: AppColors.verdeSuave, shape: BoxShape.circle),
          child: const Icon(Icons.mark_email_unread_outlined, color: AppColors.primaria, size: 54),
        ),
      ),
      const SizedBox(height: 22),
      const Text('Verifique seu e-mail',
          textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.texto)),
      const SizedBox(height: 10),
      Text.rich(
        TextSpan(
          style: const TextStyle(fontSize: 14.5, height: 1.45, color: AppColors.textoSuave),
          children: [
            const TextSpan(text: 'Enviamos um link de confirmação para '),
            TextSpan(text: email, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.texto)),
            const TextSpan(text: '. Abra o e-mail e toque no link para liberar sua conta.'),
          ],
        ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 22),
      if (_aviso != null) ...[AvisoInline(texto: _aviso!, erro: _avisoErro), const SizedBox(height: 16)],
      BotaoCarregando(
        texto: 'Já verifiquei',
        icone: Icons.check_circle_outline_rounded,
        iconeAoFinal: false,
        carregando: _verificando,
        onPressed: () => _atualizar(),
      ),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: (_reenviando || _restante > 0) ? null : _reenviar,
        icon: _reenviando
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.4))
            : const Icon(Icons.send_rounded, size: 18),
        label: Text(_restante > 0 ? 'Reenviar e-mail em ${_restante}s' : 'Reenviar e-mail de verificação'),
        style: OutlinedButton.styleFrom(shape: const StadiumBorder(), minimumSize: const Size.fromHeight(54)),
      ),
      const SizedBox(height: 16),
      TextButton(
        onPressed: () async {
          await sessao.sair();
        },
        child: const Text('Entrar com outra conta'),
      ),
    ]);
  }
}


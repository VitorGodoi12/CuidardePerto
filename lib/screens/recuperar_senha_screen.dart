import 'dart:async';

import 'package:flutter/material.dart';

import '../core/validadores.dart';
import '../services/auth_repository.dart';
import '../state/sessao.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_widgets.dart';

/// Recuperação demonstrativa: não envia e-mails nesta versão local.
class RecuperarSenhaScreen extends StatefulWidget {
  const RecuperarSenhaScreen({super.key, this.emailInicial = ''});
  final String emailInicial;

  @override
  State<RecuperarSenhaScreen> createState() => _RecuperarSenhaScreenState();
}

class _RecuperarSenhaScreenState extends State<RecuperarSenhaScreen> {
  static const int _espera = 60;

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _email = TextEditingController(text: widget.emailInicial);
  bool _enviando = false;
  bool _enviado = false;
  String _emailEnviado = '';
  int _restante = 0;
  Timer? _contagem;

  @override
  void dispose() {
    _contagem?.cancel();
    _email.dispose();
    super.dispose();
  }

  void _iniciarEspera() {
    _contagem?.cancel();
    setState(() => _restante = _espera);
    _contagem = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _restante--);
      if (_restante <= 0) t.cancel();
    });
  }

  Future<void> _enviar() async {
    if (_enviando) return;
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final sessao = SessaoScope.leitura(context);
    final email = _email.text.trim();
    setState(() => _enviando = true);
    try {
      await sessao.enviarRecuperacaoSenha(email);
      if (!mounted) return;
      setState(() {
        _enviado = true;
        _emailEnviado = email;
      });
      _iniciarEspera();
    } on AuthFalha catch (falha) {
      if (mounted) Mensagens.erro(context, falha.mensagem);
    } catch (_) {
      if (mounted) Mensagens.erro(context, 'Não foi possível enviar o e-mail. Tente novamente.');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_enviado) {
      return TelaAcesso(children: [
        Center(
          child: Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(color: AppColors.verdeSuave, shape: BoxShape.circle),
            child: const Icon(Icons.mark_email_read_outlined, color: AppColors.primaria, size: 50),
          ),
        ),
        const SizedBox(height: 22),
        const Text('Confira seu e-mail',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: AppColors.texto)),
        const SizedBox(height: 10),
        Text(
          'A recuperação de senha é demonstrativa nesta versão. Nenhum e-mail foi enviado para $_emailEnviado.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14.5, height: 1.45, color: AppColors.textoSuave),
        ),
        const SizedBox(height: 26),
        BotaoCarregando(
          texto: _restante > 0 ? 'Reenviar e-mail em ${_restante}s' : 'Reenviar e-mail',
          carregando: _enviando,
          icone: Icons.refresh_rounded,
          iconeAoFinal: false,
          onPressed: _restante > 0 ? null : _enviar,
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => Navigator.maybePop(context),
          style: OutlinedButton.styleFrom(shape: const StadiumBorder(), minimumSize: const Size.fromHeight(54)),
          child: const Text('Voltar ao login'),
        ),
        const SizedBox(height: 14),
        TextButton(
          onPressed: () => setState(() {
            _enviado = false;
            _contagem?.cancel();
            _restante = 0;
          }),
          child: const Text('Usar outro e-mail'),
        ),
      ]);
    }
    return TelaAcesso(children: [
      Center(
        child: Container(
          width: 96,
          height: 96,
          decoration: const BoxDecoration(color: AppColors.verdeSuave, shape: BoxShape.circle),
          child: const Icon(Icons.lock_reset_rounded, color: AppColors.primaria, size: 52),
        ),
      ),
      const SizedBox(height: 22),
      const Text('Recuperar senha',
          textAlign: TextAlign.center, style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: AppColors.texto)),
      const SizedBox(height: 8),
      const Text('A recuperação de senha é apenas demonstrativa nesta versão e não envia e-mails.',
          textAlign: TextAlign.center, style: TextStyle(fontSize: 14.5, height: 1.45, color: AppColors.textoSuave)),
      const SizedBox(height: 24),
      Form(
        key: _formKey,
        child: TextFormField(
          controller: _email,
          enabled: !_enviando,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _enviar(),
          autofillHints: const [AutofillHints.email],
          decoration: campoAcesso(rotulo: 'E-mail', icone: Icons.mail_outline_rounded),
          validator: Validadores.email,
        ),
      ),
      const SizedBox(height: 20),
      BotaoCarregando(texto: 'Enviar link de recuperação', carregando: _enviando, onPressed: _enviar),
    ]);
  }
}

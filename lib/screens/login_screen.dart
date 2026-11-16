import 'package:flutter/material.dart';

import '../core/validadores.dart';
import '../services/auth_repository.dart';
import '../state/sessao.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_widgets.dart';
import 'cadastro_cuidador_screen.dart';
import 'recuperar_senha_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  bool _ocultar = true;
  bool _lembrar = true;
  bool _entrando = false;
  bool _iniciado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iniciado) return;
    _iniciado = true;
    final sessao = SessaoScope.leitura(context);
    _email.text = sessao.emailLembrado;
    _lembrar = sessao.lembrarPadrao;
  }

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (_entrando) return;
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final sessao = SessaoScope.leitura(context);
    final navegador = Navigator.of(context);
    setState(() => _entrando = true);
    try {
      await sessao.entrarComEmail(email: _email.text.trim(), senha: _senha.text, lembrar: _lembrar);
      if (!mounted) return;
      // Volta à raiz: o AuthGate mostra a próxima tela (verificação, boas-vindas ou início).
      navegador.popUntil((r) => r.isFirst);
    } on AuthFalha catch (falha) {
      if (mounted) Mensagens.erro(context, falha.mensagem);
    } catch (_) {
      if (mounted) Mensagens.erro(context, 'Não foi possível entrar. Tente novamente.');
    } finally {
      if (mounted) setState(() => _entrando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bloqueado = _entrando;
    return TelaAcesso(children: [
      const Center(child: MarcaAcesso()),
      const SizedBox(height: 26),
      const Text('Bem-vindo de volta!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900, letterSpacing: -.4, color: AppColors.texto)),
      const SizedBox(height: 6),
      const Text('Faça login para continuar',
          textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: AppColors.textoSuave)),
      const SizedBox(height: 26),
      Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextFormField(
            controller: _email,
            enabled: !bloqueado,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            decoration: campoAcesso(rotulo: 'E-mail', icone: Icons.mail_outline_rounded),
            validator: Validadores.email,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _senha,
            enabled: !bloqueado,
            obscureText: _ocultar,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            onFieldSubmitted: (_) => _entrar(),
            decoration: campoAcesso(
              rotulo: 'Senha',
              icone: Icons.lock_outline_rounded,
              sufixo: IconButton(
                tooltip: _ocultar ? 'Mostrar senha' : 'Ocultar senha',
                onPressed: () => setState(() => _ocultar = !_ocultar),
                icon: Icon(_ocultar ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppColors.textoSuave),
              ),
            ),
            validator: Validadores.senhaLogin,
          ),
        ]),
      ),
      const SizedBox(height: 4),
      Row(children: [
        Checkbox(value: _lembrar, onChanged: bloqueado ? null : (v) => setState(() => _lembrar = v ?? false)),
        const Expanded(child: Text('Lembrar-me', style: TextStyle(fontSize: 13, color: AppColors.texto))),
        TextButton(
          onPressed: bloqueado
              ? null
              : () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => RecuperarSenhaScreen(emailInicial: _email.text.trim())),
                  ),
          child: const Text('Esqueceu a senha?', style: TextStyle(fontSize: 13, decoration: TextDecoration.underline)),
        ),
      ]),
      const SizedBox(height: 8),
      BotaoCarregando(texto: 'Entrar', icone: Icons.arrow_forward_rounded, carregando: _entrando, onPressed: _entrar),
      const SizedBox(height: 18),
      Wrap(alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center, children: [
        const Text('Não tem uma conta? ', style: TextStyle(fontSize: 13, color: AppColors.texto)),
        GestureDetector(
          onTap: bloqueado
              ? null
              : () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const CadastroCuidadorScreen())),
          child: const Text('Cadastre-se',
              style: TextStyle(fontSize: 13, color: AppColors.primariaEscura, fontWeight: FontWeight.w800, decoration: TextDecoration.underline)),
        ),
      ]),
    ]);
  }
}



import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../core/validadores.dart';
import '../services/auth_repository.dart';
import '../state/sessao.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_widgets.dart';
import 'login_screen.dart';
import 'termos_screen.dart';

class CadastroCuidadorScreen extends StatefulWidget {
  const CadastroCuidadorScreen({super.key});

  @override
  State<CadastroCuidadorScreen> createState() => _CadastroCuidadorScreenState();
}

class _CadastroCuidadorScreenState extends State<CadastroCuidadorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _telefone = TextEditingController();
  final _senha = TextEditingController();
  final _confirmacao = TextEditingController();
  bool _ocultarSenha = true;
  bool _ocultarConfirmacao = true;
  bool _aceitou = false;
  bool _mostrarErroTermos = false;
  bool _cadastrando = false;
  late final TapGestureRecognizer _abrirTermos;
  late final TapGestureRecognizer _abrirPrivacidade;

  @override
  void initState() {
    super.initState();
    _abrirTermos = TapGestureRecognizer()
      ..onTap = () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermosScreen(tipo: TipoDocumento.termos)));
    _abrirPrivacidade = TapGestureRecognizer()
      ..onTap = () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermosScreen(tipo: TipoDocumento.privacidade)));
  }

  @override
  void dispose() {
    _abrirTermos.dispose();
    _abrirPrivacidade.dispose();
    _nome.dispose();
    _email.dispose();
    _telefone.dispose();
    _senha.dispose();
    _confirmacao.dispose();
    super.dispose();
  }

  Future<void> _cadastrar() async {
    if (_cadastrando) return;
    FocusScope.of(context).unfocus();
    final camposOk = _formKey.currentState!.validate();
    setState(() => _mostrarErroTermos = !_aceitou);
    if (!camposOk || !_aceitou) return;

    final sessao = SessaoScope.leitura(context);
    final navegador = Navigator.of(context);
    setState(() => _cadastrando = true);
    try {
      await sessao.cadastrar(
        nome: _nome.text,
        email: _email.text,
        senha: _senha.text,
        telefone: _telefone.text,
      );
      if (!mounted) return;
      navegador.popUntil((r) => r.isFirst);
    } on AuthFalha catch (falha) {
      if (mounted) Mensagens.erro(context, falha.mensagem);
    } catch (_) {
      if (mounted) Mensagens.erro(context, 'Não foi possível criar a conta. Tente novamente.');
    } finally {
      if (mounted) setState(() => _cadastrando = false);
    }
  }

  Widget _olho(bool oculto, VoidCallback alternar) => IconButton(
        tooltip: oculto ? 'Mostrar senha' : 'Ocultar senha',
        onPressed: alternar,
        icon: Icon(oculto ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppColors.textoSuave),
      );

  @override
  Widget build(BuildContext context) {
    final bloqueado = _cadastrando;
    return TelaAcesso(children: [
      const Center(child: MarcaAcesso(tamanho: 58)),
      const SizedBox(height: 20),
      const Text('Seja parte do cuidado',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900, letterSpacing: -.4, color: AppColors.texto)),
      const SizedBox(height: 6),
      const Text('Crie sua conta de cuidador para começar',
          textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: AppColors.textoSuave)),
      const SizedBox(height: 22),
      Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextFormField(
            controller: _nome,
            enabled: !bloqueado,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
            decoration: campoAcesso(rotulo: 'Nome completo', icone: Icons.person_outline_rounded),
            validator: Validadores.nomeCompleto,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _email,
            enabled: !bloqueado,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            decoration: campoAcesso(rotulo: 'E-mail', icone: Icons.mail_outline_rounded),
            validator: Validadores.email,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _telefone,
            enabled: !bloqueado,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            inputFormatters: [TelefoneFormatter()],
            autofillHints: const [AutofillHints.telephoneNumber],
            decoration: campoAcesso(rotulo: 'Telefone (opcional)', icone: Icons.phone_outlined),
            validator: Validadores.telefoneOpcional,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _senha,
            enabled: !bloqueado,
            obscureText: _ocultarSenha,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
            decoration: campoAcesso(
              rotulo: 'Senha (mínimo 8 caracteres)',
              icone: Icons.lock_outline_rounded,
              sufixo: _olho(_ocultarSenha, () => setState(() => _ocultarSenha = !_ocultarSenha)),
            ),
            validator: Validadores.senhaNova,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _confirmacao,
            enabled: !bloqueado,
            obscureText: _ocultarConfirmacao,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _cadastrar(),
            decoration: campoAcesso(
              rotulo: 'Confirmar senha',
              icone: Icons.lock_reset_rounded,
              sufixo: _olho(_ocultarConfirmacao, () => setState(() => _ocultarConfirmacao = !_ocultarConfirmacao)),
            ),
            validator: (v) => Validadores.confirmacao(v, _senha.text),
          ),
        ]),
      ),
      const SizedBox(height: 8),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Checkbox(
          value: _aceitou,
          onChanged: bloqueado ? null : (v) => setState(() {
                _aceitou = v ?? false;
                if (_aceitou) _mostrarErroTermos = false;
              }),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 11),
            child: Text.rich(
              TextSpan(
                style: const TextStyle(fontSize: 13, height: 1.35, color: AppColors.texto),
                children: [
                  const TextSpan(text: 'Li e aceito os '),
                  TextSpan(
                    text: 'Termos de Uso',
                    recognizer: _abrirTermos,
                    style: const TextStyle(color: AppColors.primariaEscura, fontWeight: FontWeight.w800, decoration: TextDecoration.underline),
                  ),
                  const TextSpan(text: ' e a '),
                  TextSpan(
                    text: 'Política de Privacidade',
                    recognizer: _abrirPrivacidade,
                    style: const TextStyle(color: AppColors.primariaEscura, fontWeight: FontWeight.w800, decoration: TextDecoration.underline),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
          ),
        ),
      ]),
      if (_mostrarErroTermos)
        const Padding(
          padding: EdgeInsets.only(left: 14, bottom: 4),
          child: Text('Aceite os Termos de Uso e a Política de Privacidade para continuar.',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.erroEscuro)),
        ),
      const SizedBox(height: 10),
      BotaoCarregando(texto: 'Criar conta', carregando: _cadastrando, onPressed: _cadastrar),
      const SizedBox(height: 18),
      Wrap(alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center, children: [
        const Text('Já tem uma conta? ', style: TextStyle(fontSize: 13, color: AppColors.texto)),
        GestureDetector(
          onTap: bloqueado ? null : () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
          child: const Text('Entrar',
              style: TextStyle(fontSize: 13, color: AppColors.primariaEscura, fontWeight: FontWeight.w800, decoration: TextDecoration.underline)),
        ),
      ]),
    ]);
  }
}



import 'package:flutter/material.dart';

import '../core/validadores.dart';
import '../data/dados_cuidador.dart';
import '../services/auth_repository.dart';
import '../state/sessao.dart';
import '../theme/app_theme.dart';
import 'notificacoes_screen.dart';

/// "Meu Perfil": dados demonstrativos do cuidador.
class PerfilCuidadorScreen extends StatefulWidget {
  const PerfilCuidadorScreen({super.key, required this.aoSair});
  final Future<void> Function() aoSair;

  @override
  State<PerfilCuidadorScreen> createState() => _PerfilCuidadorScreenState();
}

class _PerfilCuidadorScreenState extends State<PerfilCuidadorScreen> {
  bool _salvandoNotificacao = false;

  Future<void> _editar() async {
    final sessao = SessaoScope.leitura(context);
    final perfil = sessao.perfil;
    if (perfil == null) return;
    final form = GlobalKey<FormState>();
    final nome = TextEditingController(text: perfil.nomeCompleto);
    final telefone = TextEditingController(text: perfil.telefone);
    final salvar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar perfil'),
        content: Form(
          key: form,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(
                controller: nome,
                textCapitalization: TextCapitalization.words,
                decoration: campoAcesso(rotulo: 'Nome completo', icone: Icons.person_outline_rounded),
                validator: Validadores.nomeCompleto,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: telefone,
                keyboardType: TextInputType.phone,
                inputFormatters: [TelefoneFormatter()],
                decoration: campoAcesso(rotulo: 'Telefone (opcional)', icone: Icons.phone_outlined),
                validator: Validadores.telefoneOpcional,
              ),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (form.currentState!.validate()) Navigator.pop(ctx, true);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    final novoNome = nome.text;
    final novoTelefone = telefone.text;
    if (salvar != true || !mounted) return;
    try {
      await sessao.atualizarPerfil(nomeCompleto: novoNome, telefone: novoTelefone);
      if (mounted) Mensagens.sucesso(context, 'Perfil atualizado.');
    } catch (_) {
      if (mounted) Mensagens.erro(context, 'Não foi possível salvar o perfil. Tente novamente.');
    }
  }

  Future<void> _alterarNotificacoes(bool ativas) async {
    final sessao = SessaoScope.leitura(context);
    final atuais = sessao.perfil?.notificacoes;
    if (atuais == null || _salvandoNotificacao) return;
    setState(() => _salvandoNotificacao = true);
    try {
      await sessao.atualizarNotificacoes(atuais.copiarCom(ativas: ativas));
    } catch (_) {
      if (mounted) Mensagens.erro(context, 'Não foi possível salvar sua preferência. Tente novamente.');
    } finally {
      if (mounted) setState(() => _salvandoNotificacao = false);
    }
  }

  Future<void> _alterarSenha() async {
    final sessao = SessaoScope.leitura(context);
    final usuario = sessao.usuario;
    if (usuario == null) return;
    if (!usuario.usaSenha) return;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Alterar senha'),
        content: Text('Enviaremos um link para ${usuario.email} para você criar uma nova senha com segurança.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Enviar link')),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;
    try {
      await sessao.enviarAlteracaoSenha();
      if (mounted) Mensagens.sucesso(context, 'Enviamos o link para ${usuario.email}.');
    } on AuthFalha catch (f) {
      if (mounted) Mensagens.erro(context, f.mensagem);
    } catch (_) {
      if (mounted) Mensagens.erro(context, 'Não foi possível enviar o e-mail. Tente novamente.');
    }
  }

  void _informacao(String titulo, String conteudo) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo),
        content: Text(conteudo),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fechar'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessao = SessaoScope.of(context);
    final perfil = sessao.perfil;
    if (perfil == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final criado = perfil.criadoEm;
    final desde = '${criado.day.toString().padLeft(2, '0')}/${criado.month.toString().padLeft(2, '0')}/${criado.year}';
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Meu Perfil'),
        actions: [
          IconButton(tooltip: 'Editar perfil', icon: const Icon(Icons.edit_outlined), onPressed: _editar),
        ],
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(22, 10, 22, 28), children: [
        Center(
          child: Stack(children: [
            Container(
              width: 112,
              height: 112,
              decoration: const BoxDecoration(color: Color(0xFFBDEDE5), shape: BoxShape.circle),
              child: ClipOval(
                child: (perfil.fotoUrl != null && perfil.fotoUrl!.isNotEmpty)
                    ? Image.network(perfil.fotoUrl!, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.person_rounded, size: 70, color: AppColors.primaria))
                    : const Icon(Icons.person_rounded, size: 70, color: AppColors.primaria),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 2,
              child: Material(
                color: AppColors.primaria,
                shape: const CircleBorder(side: BorderSide(color: Colors.white, width: 2)),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _editar,
                  child: const Padding(padding: EdgeInsets.all(7), child: Icon(Icons.edit_rounded, size: 16, color: Colors.white)),
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 22),
        _CampoPerfil(titulo: 'Nome', valor: perfil.nomeCompleto),
        _CampoPerfil(titulo: 'E-mail', valor: perfil.email),
        if (perfil.telefone.isNotEmpty) _CampoPerfil(titulo: 'Telefone', valor: perfil.telefone),
        _CampoPerfil(titulo: 'Pessoas acompanhadas', valor: '${DadosCuidador.idosos.length}'),
        const SizedBox(height: 6),
        Row(children: [
          const Expanded(child: Text('Notificações', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.texto))),
          Switch(
            value: perfil.notificacoes.ativas,
            onChanged: _salvandoNotificacao ? null : _alterarNotificacoes,
          ),
        ]),
        const Divider(height: 18),
        _LinhaAcao(icone: Icons.notifications_active_outlined, titulo: 'Preferências de notificação',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificacoesScreen()))),
        _LinhaAcao(icone: Icons.lock_outline_rounded, titulo: 'Alterar Senha', onTap: _alterarSenha),
        _LinhaAcao(
          icone: Icons.info_outline_rounded,
          titulo: 'Sobre o App',
          onTap: () => _informacao('Cuidar de Perto',
              'Aplicativo para aproximar familiares e cuidadores do acompanhamento diário de pessoas idosas: medicamentos, agenda, contatos e alertas, sempre salvos na sua conta.'),
        ),
        _LinhaAcao(
          icone: Icons.help_outline_rounded,
          titulo: 'Ajuda e Suporte',
          onTap: () => _informacao('Ajuda e Suporte',
              'Explore os atalhos da tela inicial, abra uma pessoa para ver seus dados e use o botão + para cadastrar rapidamente. Em situações reais de emergência, acione o SAMU (192).'),
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: widget.aoSair,
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Sair da conta'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.riscoCritico,
            shape: const StadiumBorder(),
            side: const BorderSide(color: Color(0xFFF1B8B8)),
            backgroundColor: const Color(0xFFFFF5F5),
          ),
        ),
        const SizedBox(height: 14),
        Text('Cuidador desde $desde', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppColors.textoSuave)),
      ]),
    );
  }
}

class _CampoPerfil extends StatelessWidget {
  const _CampoPerfil({required this.titulo, required this.valor});
  final String titulo;
  final String valor;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.only(bottom: 10),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borda))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(titulo, style: const TextStyle(fontSize: 12.5, color: AppColors.textoSuave)),
          const SizedBox(height: 2),
          Text(valor, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.texto)),
        ]),
      );
}

class _LinhaAcao extends StatelessWidget {
  const _LinhaAcao({required this.icone, required this.titulo, required this.onTap});
  final IconData icone;
  final String titulo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Row(children: [
            Icon(icone, color: AppColors.primariaEscura, size: 22),
            const SizedBox(width: 14),
            Expanded(child: Text(titulo, style: const TextStyle(fontSize: 14.5, color: AppColors.texto))),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textoSuave),
          ]),
        ),
      );
}

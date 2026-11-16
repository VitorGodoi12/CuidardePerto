import 'package:flutter/material.dart';

import '../data/dados_cuidador.dart';
import '../models/alerta.dart';
import '../models/idoso.dart';
import '../state/sessao.dart';
import '../theme/app_theme.dart';
import '../widgets/aparecer.dart';
import '../widgets/idoso_card.dart';
import '../widgets/logo_cuidar.dart';
import '../widgets/seletor_pessoa.dart';
import 'alertas_gerais_screen.dart';
import 'central_cuidado_screen.dart';
import 'contatos_screen.dart';
import 'detalhe_idoso_screen.dart';
import 'lembretes_screen.dart';
import 'medicamentos_screen.dart';
import 'notificacoes_screen.dart';
import 'perfil_cuidador_screen.dart';
import 'termos_screen.dart';

class PainelScreen extends StatefulWidget {
  const PainelScreen({super.key});

  @override
  State<PainelScreen> createState() => _PainelScreenState();
}

class _PainelScreenState extends State<PainelScreen> {
  int _aba = 0;
  List<Idoso> get _idosos => DadosCuidador.idosos;
  int get _alertasAbertos => _idosos.fold(0, (soma, idoso) => soma + idoso.alertasAbertos);
  bool get _haCritico => _idosos.any((idoso) => idoso.temAlertaCriticoAberto);

  @override
  void initState() {
    super.initState();
    DadosCuidador.erroSincronizacao.addListener(_avisarFalhaSincronizacao);
    WidgetsBinding.instance.addPostFrameCallback((_) => _executarAcaoInicial());
  }

  @override
  void dispose() {
    DadosCuidador.erroSincronizacao.removeListener(_avisarFalhaSincronizacao);
    super.dispose();
  }

  void _avisarFalhaSincronizacao() {
    final erro = DadosCuidador.erroSincronizacao.value;
    if (erro != null && mounted) Mensagens.erro(context, erro);
  }

  Future<void> _atualizar() async {
    try {
      await SessaoScope.leitura(context).recarregarDados();
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) Mensagens.erro(context, 'Não foi possível atualizar agora. Verifique a conexão.');
    }
  }

  Future<void> _executarAcaoInicial() async {
    if (!mounted) return;
    final acao = SessaoScope.leitura(context).consumirAcaoInicial();
    switch (acao) {
      case AcaoInicial.cadastrarIdoso:
        await _adicionarIdoso();
        break;
      case AcaoInicial.conhecerFuncionalidades:
        await _mostrarFuncionalidades();
        break;
      case AcaoInicial.configurarNotificacoes:
        await Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificacoesScreen()));
        break;
      case AcaoInicial.nenhuma:
        break;
    }
  }

  Future<void> _mostrarFuncionalidades() {
    const itens = <(IconData, String, String)>[
      (Icons.groups_rounded, 'Idosos', 'Cadastre e acompanhe quem você cuida.'),
      (Icons.medication_rounded, 'Medicamentos', 'Controle as doses e os horários de cada pessoa.'),
      (Icons.calendar_month_rounded, 'Agenda', 'Consultas, exames, rotina, diário e recados.'),
      (Icons.notifications_active_rounded, 'Lembretes', 'Veja as doses pendentes do dia.'),
      (Icons.contact_phone_rounded, 'Contatos', 'Família, vizinhos e serviços de emergência.'),
      (Icons.history_rounded, 'Alertas e histórico', 'Acompanhe ocorrências e o risco calculado.'),
    ];
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (ctx) => SafeArea(
        child: ListView(shrinkWrap: true, padding: const EdgeInsets.fromLTRB(20, 4, 20, 20), children: [
          const Text('O que você encontra aqui', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.texto)),
          const SizedBox(height: 12),
          for (final (icone, titulo, texto) in itens)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(color: AppColors.verdeSuave, shape: BoxShape.circle),
                child: Icon(icone, color: AppColors.primariaEscura),
              ),
              title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(texto),
            ),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: () => Navigator.pop(ctx), style: ElevatedButton.styleFrom(shape: const StadiumBorder()), child: const Text('Entendi')),
        ]),
      ),
    );
  }

  Future<void> _abrirDetalhe(Idoso idoso) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => DetalheIdosoScreen(idoso: idoso)));
    if (mounted) setState(() {});
  }

  Future<Idoso?> _escolherIdoso({String titulo = 'Escolha uma pessoa'}) async {
    if (_idosos.isEmpty) {
      Mensagens.info(context, 'Cadastre uma pessoa acompanhada primeiro.');
      return null;
    }
    if (_idosos.length == 1) return _idosos.first;
    return showModalBottomSheet<Idoso>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (ctx) => SafeArea(
        child: ListView(shrinkWrap: true, padding: const EdgeInsets.fromLTRB(18, 4, 18, 18), children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(titulo, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.texto)),
          ),
          for (final idoso in _idosos)
            ListTile(
              leading: AvatarIdoso(caminho: idoso.avatar, tamanho: 48),
              title: Text(idoso.nome, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('${idoso.idade} anos'),
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.primaria),
              onTap: () => Navigator.pop(ctx, idoso),
            ),
        ]),
      ),
    );
  }

  Future<void> _abrirMedicamentos([Idoso? selecionado]) async {
    final idoso = selecionado ?? await _escolherIdoso(titulo: 'Medicamentos de quem?');
    if (idoso == null || !mounted) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => MedicamentosScreen(idoso: idoso)));
    if (mounted) setState(() {});
  }

  Future<void> _abrirContatos() async {
    final idoso = await _escolherIdoso(titulo: 'Contatos de quem?');
    if (idoso == null || !mounted) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => ContatosScreen(idoso: idoso)));
    if (mounted) setState(() {});
  }

  Future<void> _abrirAlertas() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const AlertasGeraisScreen()));
    if (mounted) setState(() {});
  }

  Future<void> _abrirLembretes() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const LembretesScreen()));
    if (mounted) setState(() {});
  }

  Future<void> _abrirNotificacoes() => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificacoesScreen()));

  Future<void> _abrirPerfil() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => PerfilCuidadorScreen(aoSair: _sair)));
    if (mounted) setState(() {});
  }

  Future<void> _adicionarIdoso() async {
    final form = GlobalKey<FormState>();
    final nome = TextEditingController();
    final idade = TextEditingController();
    final endereco = TextEditingController();
    final condicoes = TextEditingController();
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Adicionar pessoa acompanhada'),
        content: Form(
          key: form,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(
                controller: nome,
                textCapitalization: TextCapitalization.words,
                decoration: AppTheme.campo(rotulo: 'Nome completo'),
                validator: (v) => (v == null || v.trim().length < 2) ? 'Informe o nome' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: idade,
                keyboardType: TextInputType.number,
                decoration: AppTheme.campo(rotulo: 'Idade'),
                validator: (v) {
                  final valor = int.tryParse(v ?? '');
                  return valor == null || valor < 1 || valor > 120 ? 'Informe uma idade válida' : null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(controller: endereco, decoration: AppTheme.campo(rotulo: 'Endereço')),
              const SizedBox(height: 12),
              TextFormField(controller: condicoes, decoration: AppTheme.campo(rotulo: 'Condições de saúde', dica: 'Ex.: hipertensão, diabetes')),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (form.currentState!.validate()) Navigator.pop(ctx, true);
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
    final nomeFinal = nome.text.trim();
    final idadeFinal = int.tryParse(idade.text) ?? 0;
    final enderecoFinal = endereco.text.trim();
    final condicoesFinal = condicoes.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (confirmado == true && mounted) {
      setState(() => DadosCuidador.adicionar(Idoso(
            id: DadosCuidador.proximoId(),
            nome: nomeFinal,
            idade: idadeFinal,
            condicoes: condicoesFinal,
            endereco: enderecoFinal.isEmpty ? 'Endereço não informado' : enderecoFinal,
            horasSemMovimento: 0,
            dispositivoOnline: false,
            avatar: 'assets/images/avatar.png',
          )));
      Mensagens.sucesso(context, '$nomeFinal foi adicionado(a) à sua lista.');
    }
  }

  Future<void> _sair() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deseja sair?'),
        content: const Text('Você encerrará a sessão neste aparelho. Seus dados continuam salvos na sua conta.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sair')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final sessao = SessaoScope.leitura(context);
    // Fecha telas empilhadas (perfil etc.) e deixa o AuthGate voltar ao início do app.
    Navigator.of(context).popUntil((r) => r.isFirst);
    await sessao.sair();
  }

  Future<void> _abrirAcoesRapidas() async {
    final acao = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 22),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Acesso rápido', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.texto)),
            ),
            const SizedBox(height: 12),
            _AcaoRapidaLinha(icone: Icons.person_add_alt_1_rounded, texto: 'Adicionar idoso', onTap: () => Navigator.pop(ctx, 'idoso')),
            _AcaoRapidaLinha(icone: Icons.medication_rounded, texto: 'Cadastrar medicamento', onTap: () => Navigator.pop(ctx, 'medicamento')),
            _AcaoRapidaLinha(icone: Icons.calendar_month_rounded, texto: 'Abrir agenda de cuidados', onTap: () => Navigator.pop(ctx, 'agenda')),
            _AcaoRapidaLinha(icone: Icons.notifications_active_rounded, texto: 'Ver lembretes', onTap: () => Navigator.pop(ctx, 'lembretes')),
          ]),
        ),
      ),
    );
    if (!mounted || acao == null) return;
    switch (acao) {
      case 'idoso':
        await _adicionarIdoso();
        break;
      case 'medicamento':
        await _abrirMedicamentos();
        break;
      case 'agenda':
        setState(() => _aba = 2);
        break;
      case 'lembretes':
        await _abrirLembretes();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final perfil = SessaoScope.of(context).perfil;
    final paginas = <Widget>[
      _InicioPage(
        nome: perfil?.primeiroNome ?? '',
        idosos: _idosos,
        alertas: _alertasAbertos,
        critico: _haCritico,
        onIdoso: _abrirDetalhe,
        onVerIdosos: () => setState(() => _aba = 1),
        onMedicamentos: _abrirMedicamentos,
        onAgenda: () => setState(() => _aba = 2),
        onPerfil: _abrirPerfil,
        onAlertas: _abrirAlertas,
        onLembretes: _abrirLembretes,
        onMais: () => setState(() => _aba = 3),
        onAtualizar: _atualizar,
        onAdicionar: _adicionarIdoso,
      ),
      _IdososPage(onAtualizar: _atualizar, idosos: _idosos, onIdoso: _abrirDetalhe, onAdicionar: _adicionarIdoso, onVoltar: () => setState(() => _aba = 0)),
      _SeletorAcompanhamento(idosos: _idosos, onVoltar: () => setState(() => _aba = 0), onAdicionar: _adicionarIdoso),
      _MaisPage(
        onPerfil: _abrirPerfil,
        onNotificacoes: _abrirNotificacoes,
        onMedicamentos: () => _abrirMedicamentos(),
        onLembretes: _abrirLembretes,
        onAlertas: _abrirAlertas,
        onContatos: _abrirContatos,
        onSair: _sair,
        onVoltar: () => setState(() => _aba = 0),
      ),
    ];

    return PopScope(
      canPop: _aba == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _aba = 0);
      },
      child: Scaffold(
      body: IndexedStack(index: _aba, children: paginas),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white,
            border: const Border(top: BorderSide(color: AppColors.borda)),
            boxShadow: [BoxShadow(color: const Color(0xFF174B48).withValues(alpha: .08), blurRadius: 16, offset: const Offset(0, -4))],
          ),
          child: Row(children: [
            _NavegacaoItem(icone: Icons.home_rounded, rotulo: 'Início', selecionado: _aba == 0, onTap: () => setState(() => _aba = 0)),
            _NavegacaoItem(icone: Icons.people_alt_rounded, rotulo: 'Idosos', selecionado: _aba == 1, onTap: () => setState(() => _aba = 1)),
            Expanded(
              child: Center(
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: FloatingActionButton(
                    heroTag: 'acao_rapida_principal',
                    tooltip: 'Acesso rápido',
                    onPressed: _abrirAcoesRapidas,
                    elevation: 3,
                    backgroundColor: AppColors.primariaEscura,
                    foregroundColor: Colors.white,
                    shape: const CircleBorder(),
                    child: const Icon(Icons.add_rounded, size: 29),
                  ),
                ),
              ),
            ),
            _NavegacaoItem(icone: Icons.calendar_month_rounded, rotulo: 'Agenda', selecionado: _aba == 2, onTap: () => setState(() => _aba = 2)),
            _NavegacaoItem(icone: Icons.more_horiz_rounded, rotulo: 'Mais', selecionado: _aba == 3, onTap: () => setState(() => _aba = 3)),
          ]),
        ),
      ),
    ));
  }
}

class _InicioPage extends StatelessWidget {
  const _InicioPage({
    required this.nome,
    required this.idosos,
    required this.alertas,
    required this.critico,
    required this.onIdoso,
    required this.onVerIdosos,
    required this.onMedicamentos,
    required this.onAgenda,
    required this.onPerfil,
    required this.onAlertas,
    required this.onLembretes,
    required this.onMais,
    required this.onAtualizar,
    required this.onAdicionar,
  });

  final Future<void> Function() onAtualizar;
  final VoidCallback onAdicionar;
  final String nome;
  final List<Idoso> idosos;
  final int alertas;
  final bool critico;
  final ValueChanged<Idoso> onIdoso;
  final VoidCallback onVerIdosos;
  final Future<void> Function() onMedicamentos;
  final VoidCallback onAgenda;
  final VoidCallback onPerfil;
  final VoidCallback onAlertas;
  final VoidCallback onLembretes;
  final VoidCallback onMais;

  int get _compromissosHoje {
    final hoje = DateTime.now();
    var total = 0;
    for (final idoso in idosos) {
      for (final c in idoso.central.consultas) {
        final d = c.dia;
        if (d != null && d.year == hoje.year && d.month == hoje.month && d.day == hoje.day) total++;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final dosesPendentes = idosos.fold<int>(0, (soma, idoso) => soma + idoso.medicamentos.where((m) => !m.tomado).length);
    final compromissos = _compromissosHoje;
    final temAviso = dosesPendentes > 0 || alertas > 0;
    return Scaffold(
      backgroundColor: AppColors.primariaEscura,
      body: Column(children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF006F73), Color(0xFF0FA3A0)]),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 14, 22),
              child: Row(children: [
                const LogoCuidar(tamanho: 42, cor: Colors.white),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('Cuidar\nde Perto',
                      style: TextStyle(color: Colors.white, fontSize: 17, height: 1.0, fontWeight: FontWeight.w900, letterSpacing: -.3)),
                ),
                _BotaoCabecalho(icone: Icons.notifications_none_rounded, tooltip: 'Lembretes', aviso: temAviso, onTap: onLembretes),
                const SizedBox(width: 8),
                _BotaoCabecalho(icone: Icons.settings_outlined, tooltip: 'Mais opções', onTap: onMais),
              ]),
            ),
          ),
        ),
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.fundo,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              child: RefreshIndicator(
                onRefresh: onAtualizar,
                color: AppColors.primaria,
                child: ListView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.fromLTRB(17, 18, 17, 24), children: [
                Aparecer(child: Container(
                  padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFDDF8F1), Color(0xFFB8EFE4)]),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFC9EEE5)),
                  ),
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Olá, $nome!', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -.4, color: AppColors.texto)),
                        const SizedBox(height: 5),
                        const Text('Cuidando melhor, sempre.', style: TextStyle(fontSize: 14, color: AppColors.texto)),
                      ]),
                    ),
                    Container(
                      width: 62,
                      height: 62,
                      decoration: const BoxDecoration(color: AppColors.primariaEscura, shape: BoxShape.circle),
                      child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 32),
                    ),
                  ]),
                )),
                const SizedBox(height: 20),
                const Text('Acesso rápido', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.texto)),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 11,
                  crossAxisSpacing: 11,
                  childAspectRatio: 1.56,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _AtalhoRapidoCard(icone: Icons.groups_rounded, titulo: 'Idosos', onTap: onVerIdosos),
                    _AtalhoRapidoCard(icone: Icons.medication_rounded, titulo: 'Medicamentos', onTap: onMedicamentos),
                    _AtalhoRapidoCard(icone: Icons.calendar_month_rounded, titulo: 'Agenda', onTap: onAgenda),
                    _AtalhoRapidoCard(icone: Icons.person_rounded, titulo: 'Meu Perfil', onTap: onPerfil),
                  ],
                ),
                const SizedBox(height: 20),
                Row(children: [
                  const Expanded(child: Text('Resumo do dia', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.texto))),
                  TextButton(onPressed: onAgenda, child: const Text('Ver detalhes  ›')),
                ]),
                Cartao(
                  padding: const EdgeInsets.all(16),
                  corFundo: const Color(0xFFE2F8F0),
                  corBorda: const Color(0xFFCDEFE5),
                  onTap: onAgenda,
                  child: Row(children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(color: AppColors.primaria.withValues(alpha: .14), borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.calendar_month_rounded, color: AppColors.primariaEscura, size: 26),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('$compromissos ${compromissos == 1 ? 'compromisso hoje' : 'compromissos hoje'}',
                            style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: AppColors.texto)),
                        Text('$dosesPendentes ${dosesPendentes == 1 ? 'medicamento pendente' : 'medicamentos pendentes'}',
                            style: const TextStyle(fontSize: 13, color: AppColors.textoSuave)),
                      ]),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.primariaEscura, size: 25),
                  ]),
                ),
                const SizedBox(height: 12),
                _CartaoAlerta(abertos: alertas, critico: critico, onTap: onAlertas),
                const SizedBox(height: 23),
                Row(children: [
                  const Expanded(child: Text('Pessoas acompanhadas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.texto))),
                  TextButton(onPressed: onVerIdosos, child: const Text('Ver todos')),
                ]),
                const SizedBox(height: 4),
                if (idosos.isEmpty)
                  Cartao(
                    child: Column(children: [
                      const Icon(Icons.people_alt_outlined, size: 44, color: AppColors.primaria),
                      const SizedBox(height: 8),
                      const Text('Comece cadastrando quem você cuida.', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: onAdicionar,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Adicionar idoso'),
                        style: FilledButton.styleFrom(backgroundColor: AppColors.primariaEscura, shape: const StadiumBorder()),
                      ),
                    ]),
                  )
                else
                  for (final idoso in idosos.take(2))
                    Padding(padding: const EdgeInsets.only(bottom: 10), child: Aparecer(child: IdosoCard(idoso: idoso, onTap: () => onIdoso(idoso)))),
              ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _BotaoCabecalho extends StatelessWidget {
  const _BotaoCabecalho({required this.icone, required this.tooltip, required this.onTap, this.aviso = false});
  final IconData icone;
  final String tooltip;
  final VoidCallback onTap;
  final bool aviso;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.white.withValues(alpha: .16),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Stack(alignment: Alignment.center, children: [
                Icon(icone, color: Colors.white, size: 24),
                if (aviso)
                  Positioned(
                    right: 11,
                    top: 10,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(color: const Color(0xFFFF5A4D), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.2)),
                    ),
                  ),
              ]),
            ),
          ),
        ),
      );
}

class _AtalhoRapidoCard extends StatelessWidget {
  const _AtalhoRapidoCard({required this.icone, required this.titulo, required this.onTap});
  final IconData icone;
  final String titulo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        elevation: 1,
        shadowColor: const Color(0x16005D5B),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(color: Color(0xFFE5F7F4), shape: BoxShape.circle),
              child: Icon(icone, color: AppColors.primariaEscura, size: 27),
            ),
            const SizedBox(height: 7),
            Text(titulo, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.texto)),
          ]),
        ),
      );
}

class _CartaoAlerta extends StatelessWidget {
  const _CartaoAlerta({required this.abertos, required this.critico, required this.onTap});
  final int abertos;
  final bool critico;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cor = critico ? AppColors.riscoCritico : (abertos > 0 ? AppColors.laranja : AppColors.riscoBaixo);
    final fundo = critico ? const Color(0xFFFEECEC) : (abertos > 0 ? const Color(0xFFFFF4E9) : const Color(0xFFE7F7EC));
    return Material(
      color: fundo,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
              child: Icon(abertos == 0 ? Icons.check_rounded : Icons.priority_high_rounded, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(abertos == 0 ? 'Tudo tranquilo' : '$abertos ${abertos == 1 ? 'alerta aberto' : 'alertas abertos'}',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: critico ? AppColors.riscoCritico : AppColors.texto)),
                const SizedBox(height: 3),
                Text(abertos == 0 ? 'Tudo dentro da normalidade.' : (critico ? 'Verifique a situação agora.' : 'Toque para acompanhar.'),
                    style: TextStyle(fontSize: 13, color: critico ? AppColors.riscoCritico : AppColors.textoSuave)),
              ]),
            ),
            const Icon(Icons.chevron_right_rounded, size: 27, color: AppColors.textoSuave),
          ]),
        ),
      ),
    );
  }
}

class _IdososPage extends StatelessWidget {
  const _IdososPage({required this.onAtualizar, required this.idosos, required this.onIdoso, required this.onAdicionar, required this.onVoltar});
  final Future<void> Function() onAtualizar;
  final List<Idoso> idosos;
  final ValueChanged<Idoso> onIdoso;
  final VoidCallback onAdicionar;
  final VoidCallback onVoltar;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.fundo,
        appBar: AppBar(
          title: const Text('Meus Idosos'),
          leading: IconButton(tooltip: 'Voltar ao início', icon: const Icon(Icons.arrow_back_rounded), onPressed: onVoltar),
        ),
        body: RefreshIndicator(
          onRefresh: onAtualizar,
          color: AppColors.primaria,
          child: ListView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.fromLTRB(18, 12, 18, 26), children: [
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: onAdicionar,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Adicionar idoso'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primariaEscura,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (idosos.isEmpty)
            Cartao(
              child: Column(children: [
                const Icon(Icons.people_alt_outlined, size: 48, color: AppColors.primaria),
                const SizedBox(height: 8),
                const Text('Nenhuma pessoa cadastrada', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                const Text('Adicione quem você acompanha para começar.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textoSuave)),
              ]),
            )
          else
            for (final idoso in idosos)
              Padding(padding: const EdgeInsets.only(bottom: 14), child: IdosoCard(idoso: idoso, onTap: () => onIdoso(idoso))),
        ]),
        ),
      );
}

class _MaisPage extends StatelessWidget {
  const _MaisPage({
    required this.onPerfil,
    required this.onNotificacoes,
    required this.onMedicamentos,
    required this.onLembretes,
    required this.onAlertas,
    required this.onContatos,
    required this.onSair,
    required this.onVoltar,
  });
  final VoidCallback onPerfil;
  final VoidCallback onNotificacoes;
  final VoidCallback onMedicamentos;
  final VoidCallback onLembretes;
  final VoidCallback onAlertas;
  final VoidCallback onContatos;
  final VoidCallback onSair;
  final VoidCallback onVoltar;

  void _informacao(BuildContext context, String titulo, String conteudo) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo),
        content: Text(conteudo),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fechar'))],
      ),
    );
  }

  void _tema(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 22),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Tema', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.texto)),
            const SizedBox(height: 10),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.light_mode_rounded, color: AppColors.primaria),
              title: Text('Claro', style: TextStyle(fontWeight: FontWeight.w700)),
              trailing: Icon(Icons.check_circle_rounded, color: AppColors.primaria),
            ),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              enabled: false,
              leading: Icon(Icons.dark_mode_rounded),
              title: Text('Escuro'),
              subtitle: Text('Disponível em uma próxima versão'),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: const Text('Mais'),
          leading: IconButton(tooltip: 'Voltar ao início', icon: const Icon(Icons.arrow_back_rounded), onPressed: onVoltar),
        ),
        body: ListView(padding: const EdgeInsets.fromLTRB(18, 8, 18, 24), children: [
          _MaisItem(icone: Icons.person_outline_rounded, titulo: 'Meu Perfil', subtitulo: 'Seus dados e preferências', onTap: onPerfil),
          _MaisItem(
            icone: Icons.info_outline_rounded,
            titulo: 'Sobre o Cuidar de Perto',
            subtitulo: 'Conheça nosso app',
            onTap: () => _informacao(context, 'Cuidar de Perto',
                'Aplicativo para aproximar familiares e cuidadores do acompanhamento diário de pessoas idosas. Seus dados ficam salvos na sua conta e só você os acessa.'),
          ),
          _MaisItem(icone: Icons.notifications_active_outlined, titulo: 'Notificações', subtitulo: 'Gerencie suas notificações', onTap: onNotificacoes),
          _MaisItem(icone: Icons.dark_mode_outlined, titulo: 'Tema', subtitulo: 'Modo claro ou escuro', onTap: () => _tema(context)),
          _MaisItem(
            icone: Icons.lock_outline_rounded,
            titulo: 'Privacidade',
            subtitulo: 'Seus dados protegidos',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermosScreen(tipo: TipoDocumento.privacidade))),
          ),
          _MaisItem(
            icone: Icons.chat_bubble_outline_rounded,
            titulo: 'Fale Conosco',
            subtitulo: 'Precisa de ajuda?',
            onTap: () => _informacao(context, 'Fale Conosco',
                'Explore os atalhos da tela inicial, abra uma pessoa para ver seus dados e use o botão + para cadastrar rapidamente. Em situações reais de emergência, acione o SAMU (192).'),
          ),
          _MaisItem(icone: Icons.alarm_rounded, titulo: 'Lembretes de medicamentos', subtitulo: 'Doses pendentes', onTap: onLembretes),
          _MaisItem(icone: Icons.history_rounded, titulo: 'Alertas e histórico', subtitulo: 'Acompanhe eventos e ocorrências', onTap: onAlertas),
          _MaisItem(icone: Icons.medication_outlined, titulo: 'Medicamentos', subtitulo: 'Consulte e cadastre medicamentos', onTap: onMedicamentos),
          _MaisItem(icone: Icons.contact_phone_outlined, titulo: 'Contatos de emergência', subtitulo: 'Família, vizinhos e serviços', onTap: onContatos),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onSair,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.riscoCritico,
              minimumSize: const Size.fromHeight(54),
              shape: const StadiumBorder(),
              side: const BorderSide(color: Color(0xFFF1B8B8)),
              backgroundColor: const Color(0xFFFFE9E9),
            ),
            child: const Text('Sair da conta', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ),
        ]),
      );
}

class _MaisItem extends StatelessWidget {
  const _MaisItem({required this.icone, required this.titulo, required this.subtitulo, required this.onTap});
  final IconData icone;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borda))),
          child: Row(children: [
            Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(color: AppColors.verdeSuave, shape: BoxShape.circle),
              child: Icon(icone, color: AppColors.primariaEscura, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(titulo, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.texto)),
                const SizedBox(height: 2),
                Text(subtitulo, style: const TextStyle(fontSize: 12.5, color: AppColors.textoSuave)),
              ]),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textoSuave, size: 24),
          ]),
        ),
      );
}

class _NavegacaoItem extends StatelessWidget {
  const _NavegacaoItem({required this.icone, required this.rotulo, required this.selecionado, required this.onTap});
  final IconData icone;
  final String rotulo;
  final bool selecionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Semantics(
          button: true,
          selected: selecionado,
          label: rotulo,
          excludeSemantics: true,
          child: InkWell(
            onTap: onTap,
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: selecionado ? AppColors.verdeSuave : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icone, size: 24, color: selecionado ? AppColors.primariaEscura : const Color(0xFF9EAFB2)),
              ),
              const SizedBox(height: 2),
              Text(rotulo,
                  style: TextStyle(
                    fontSize: 10.5,
                    height: 1,
                    fontWeight: selecionado ? FontWeight.w800 : FontWeight.w500,
                    color: selecionado ? AppColors.primariaEscura : AppColors.textoSuave,
                  )),
            ]),
          ),
        ),
      );
}

class _AcaoRapidaLinha extends StatelessWidget {
  const _AcaoRapidaLinha({required this.icone, required this.texto, required this.onTap});
  final IconData icone;
  final String texto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(color: AppColors.verdeSuave, shape: BoxShape.circle),
          child: Icon(icone, color: AppColors.primariaEscura),
        ),
        title: Text(texto, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textoSuave),
        onTap: onTap,
      );
}

/// Aba Agenda: escolhe a pessoa e mostra a Central de cuidado dela.
class _SeletorAcompanhamento extends StatefulWidget {
  const _SeletorAcompanhamento({required this.idosos, required this.onVoltar, required this.onAdicionar});
  final List<Idoso> idosos;
  final VoidCallback onVoltar;
  final VoidCallback onAdicionar;

  @override
  State<_SeletorAcompanhamento> createState() => _SeletorAcompanhamentoState();
}

class _SeletorAcompanhamentoState extends State<_SeletorAcompanhamento> {
  int? _selecionado;

  @override
  Widget build(BuildContext context) {
    if (widget.idosos.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.fundo,
        appBar: AppBar(
          title: const Text('Agenda'),
          leading: IconButton(tooltip: 'Voltar ao início', icon: const Icon(Icons.arrow_back_rounded), onPressed: widget.onVoltar),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.people_alt_outlined, size: 55, color: AppColors.primaria),
              const SizedBox(height: 12),
              const Text('Adicione uma pessoa para usar a agenda.', textAlign: TextAlign.center),
              const SizedBox(height: 14),
              ElevatedButton.icon(onPressed: widget.onAdicionar, icon: const Icon(Icons.add), label: const Text('Adicionar idoso')),
            ]),
          ),
        ),
      );
    }
    final atual = widget.idosos.firstWhere((i) => i.id == _selecionado, orElse: () => widget.idosos.first);
    return CentralCuidadoScreen(
      key: ValueKey(atual.id),
      idoso: atual,
      aoVoltar: widget.onVoltar,
      seletor: SeletorPessoa(
        atual: atual,
        pessoas: widget.idosos,
        aoEscolher: (p) => setState(() => _selecionado = p.id),
      ),
    );
  }
}

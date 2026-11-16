import 'package:flutter/material.dart';

import '../data/dados_cuidador.dart';
import '../models/alerta.dart';
import '../models/idoso.dart';
import '../theme/app_theme.dart';
import '../widgets/alerta_card.dart';
import '../widgets/idoso_card.dart';
import '../widgets/risco_badge.dart';
import 'alerta_critico_screen.dart';
import 'contatos_screen.dart';
import 'historico_screen.dart';
import 'medicamentos_screen.dart';

class DetalheIdosoScreen extends StatefulWidget {
  const DetalheIdosoScreen({super.key, required this.idoso});

  final Idoso idoso;

  @override
  State<DetalheIdosoScreen> createState() => _DetalheIdosoScreenState();
}

class _DetalheIdosoScreenState extends State<DetalheIdosoScreen> {
  Idoso get idoso => widget.idoso;

  Future<void> _abrirMedicamentos() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => MedicamentosScreen(idoso: idoso)));
    if (mounted) setState(() {});
  }

  Future<void> _abrirHistorico() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => HistoricoScreen(idoso: idoso)));
    if (mounted) setState(() {});
  }

  Future<void> _abrirContatos() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => ContatosScreen(idoso: idoso)));
    if (mounted) setState(() {});
  }

  Future<void> _editar() async {
    final form = GlobalKey<FormState>();
    final nome = TextEditingController(text: idoso.nome);
    final idade = TextEditingController(text: '${idoso.idade}');
    final telefone = TextEditingController(text: idoso.telefone);
    final condicoes = TextEditingController(text: idoso.condicoes.join(', '));
    final alergias = TextEditingController(text: idoso.alergias);
    final observacoes = TextEditingController(text: idoso.observacoes);
    final endereco = TextEditingController(text: idoso.endereco);
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
                decoration: AppTheme.campo(rotulo: 'Nome'),
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
              TextFormField(controller: telefone, keyboardType: TextInputType.phone, decoration: AppTheme.campo(rotulo: 'Telefone')),
              const SizedBox(height: 12),
              TextFormField(controller: condicoes, decoration: AppTheme.campo(rotulo: 'Doenças', dica: 'Separe por vírgula')),
              const SizedBox(height: 12),
              TextFormField(controller: alergias, decoration: AppTheme.campo(rotulo: 'Alergias')),
              const SizedBox(height: 12),
              TextFormField(controller: observacoes, maxLines: 2, decoration: AppTheme.campo(rotulo: 'Observações')),
              const SizedBox(height: 12),
              TextFormField(controller: endereco, decoration: AppTheme.campo(rotulo: 'Endereço')),
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
    final valores = (
      nome.text.trim(),
      int.tryParse(idade.text) ?? idoso.idade,
      telefone.text.trim(),
      condicoes.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      alergias.text.trim(),
      observacoes.text.trim(),
      endereco.text.trim(),
    );
    if (salvar != true || !mounted) return;
    setState(() {
      idoso.nome = valores.$1;
      idoso.idade = valores.$2;
      idoso.telefone = valores.$3;
      idoso.condicoes = valores.$4;
      idoso.alergias = valores.$5;
      idoso.observacoes = valores.$6;
      if (valores.$7.isNotEmpty) idoso.endereco = valores.$7;
    });
    DadosCuidador.salvar(idoso);
    Mensagens.sucesso(context, 'Perfil atualizado.');
  }

  Future<void> _simularEvento() async {
    var alerta = idoso.alertaCriticoAberto;
    if (alerta == null) {
      final tipo = await showDialog<TipoAlerta>(
        context: context,
        builder: (contextoDialogo) => AlertDialog(
          title: const Text('Simular evento'),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Escolha o evento para ${idoso.nome}. É apenas uma simulação de sensor: nenhum alerta real é enviado.'),
            const SizedBox(height: 16),
            ElevatedButton.icon(onPressed: () => Navigator.pop(contextoDialogo, TipoAlerta.queda), icon: const Icon(Icons.personal_injury), label: const Text('Queda')),
            const SizedBox(height: 8),
            ElevatedButton.icon(onPressed: () => Navigator.pop(contextoDialogo, TipoAlerta.panico), icon: const Icon(Icons.notifications_active), label: const Text('Botão de pânico')),
          ]),
          actions: [TextButton(onPressed: () => Navigator.pop(contextoDialogo), child: const Text('Cancelar'))],
        ),
      );
      if (tipo == null || !mounted) return;
      alerta = idoso.registrarEvento(tipo);
      DadosCuidador.salvar(idoso);
      setState(() {});
    }

    final alertaAberto = alerta;
    final resolvido = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => AlertaCriticoScreen(alerta: alertaAberto)));
    if (!mounted) return;
    setState(() {});
    if (resolvido == true) {
      Mensagens.sucesso(context, 'Alerta resolvido. O risco de ${idoso.nome} foi recalculado.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(backgroundColor: Colors.white),
        body: Column(children: [
          Center(
            child: Stack(children: [
              AvatarIdoso(caminho: idoso.avatar, tamanho: 104),
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
          const SizedBox(height: 10),
          Text(idoso.nome, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.texto)),
          Text('${idoso.idade} anos', style: const TextStyle(fontSize: 14, color: AppColors.textoSuave)),
          const SizedBox(height: 8),
          RiscoBadge(nivel: idoso.risco),
          const SizedBox(height: 8),
          const TabBar(
            labelColor: AppColors.primariaEscura,
            unselectedLabelColor: AppColors.texto,
            indicatorColor: AppColors.primaria,
            labelStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            tabs: [Tab(text: 'Informações'), Tab(text: 'Histórico')],
          ),
          Expanded(child: TabBarView(children: [_informacoes(), _historico()])),
        ]),
      ),
    );
  }

  Widget _informacoes() {
    final atrasadas = idoso.dosesAtrasadas;
    String texto(String v, String vazio) => v.trim().isEmpty ? vazio : v;
    return ListView(padding: const EdgeInsets.fromLTRB(20, 14, 20, 24), children: [
      _LinhaInfo(icone: Icons.phone_rounded, rotulo: 'Telefone', valor: texto(idoso.telefone, 'Não informado')),
      _LinhaInfo(icone: Icons.favorite_border_rounded, rotulo: 'Doenças', valor: idoso.condicoes.isEmpty ? 'Não informado' : idoso.condicoes.join(', ')),
      _LinhaInfo(icone: Icons.spa_outlined, rotulo: 'Alergias', valor: texto(idoso.alergias, 'Não informado')),
      _LinhaInfo(icone: Icons.visibility_outlined, rotulo: 'Observações', valor: texto(idoso.observacoes, 'Nenhuma')),
      _LinhaInfo(icone: Icons.home_outlined, rotulo: 'Endereço', valor: idoso.endereco),
      _LinhaInfo(icone: Icons.directions_walk_rounded, rotulo: 'Último movimento', valor: idoso.ultimoMovimento),
      _LinhaInfo(
        icone: idoso.dispositivoOnline ? Icons.sensors_rounded : Icons.sensors_off_rounded,
        rotulo: 'Dispositivo',
        valor: idoso.dispositivoOnline ? 'Online - sensores funcionando' : 'Sem conexão',
      ),
      const SizedBox(height: 8),
      Cartao(
        onTap: _abrirMedicamentos,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.medication_rounded, color: AppColors.primaria),
            const SizedBox(width: 8),
            const Expanded(child: Text('Remédios de hoje', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
            Text(idoso.resumoMedicamentos, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primariaEscura)),
          ]),
          const SizedBox(height: 10),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(end: idoso.progressoDoses),
            duration: const Duration(milliseconds: 400),
            builder: (context, valor, filho) => LinearProgressIndicator(value: valor, minHeight: 10, borderRadius: BorderRadius.circular(8)),
          ),
          if (atrasadas > 0) ...[
            const SizedBox(height: 8),
            Text(atrasadas == 1 ? '1 remédio atrasado' : '$atrasadas remédios atrasados',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.laranjaTexto)),
          ],
        ]),
      ),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: _Atalho(icone: Icons.medication_rounded, titulo: 'Medicamentos', onTap: _abrirMedicamentos)),
        const SizedBox(width: 10),
        Expanded(child: _Atalho(icone: Icons.contact_phone_rounded, titulo: '${idoso.contatos.length} contatos', onTap: _abrirContatos)),
        const SizedBox(width: 10),
        Expanded(child: _Atalho(icone: Icons.warning_amber_rounded, titulo: 'Simular evento', destaque: true, onTap: _simularEvento)),
      ]),
      const SizedBox(height: 18),
      SizedBox(
        height: 54,
        child: ElevatedButton(
          onPressed: _editar,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD2F2EA),
            foregroundColor: AppColors.primariaEscura,
            elevation: 0,
            shape: const StadiumBorder(),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          child: const Text('Editar Perfil'),
        ),
      ),
    ]);
  }

  Widget _historico() {
    final lista = List<Alerta>.of(idoso.alertas)..sort((a, b) => b.dataHora.compareTo(a.dataHora));
    return ListView(padding: const EdgeInsets.fromLTRB(20, 14, 20, 24), children: [
      if (lista.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 28),
          child: Column(children: [
            Icon(Icons.history_rounded, size: 48, color: AppColors.textoSuave),
            SizedBox(height: 8),
            Text('Nenhum evento registrado', style: TextStyle(fontWeight: FontWeight.w700)),
          ]),
        )
      else
        for (var i = 0; i < lista.length; i++)
          AlertaCard(alerta: lista[i], primeiro: i == 0, ultimo: i == lista.length - 1),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: _abrirHistorico,
        icon: const Icon(Icons.history_rounded),
        label: const Text('Abrir histórico completo'),
        style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
      ),
    ]);
  }
}

class _LinhaInfo extends StatelessWidget {
  const _LinhaInfo({required this.icone, required this.rotulo, required this.valor});
  final IconData icone;
  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(color: AppColors.verdeSuave, shape: BoxShape.circle),
            child: Icon(icone, color: AppColors.primariaEscura, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(rotulo, style: const TextStyle(fontSize: 12.5, color: AppColors.textoSuave)),
              Text(valor, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600, color: AppColors.texto)),
            ]),
          ),
        ]),
      );
}

class _Atalho extends StatelessWidget {
  const _Atalho({required this.icone, required this.titulo, required this.onTap, this.destaque = false});
  final IconData icone;
  final String titulo;
  final VoidCallback onTap;
  final bool destaque;

  @override
  Widget build(BuildContext context) {
    final cor = destaque ? AppColors.laranjaTexto : AppColors.primariaEscura;
    return Semantics(
      button: true,
      onTap: onTap,
      label: titulo,
      excludeSemantics: true,
      child: Cartao(
        corFundo: destaque ? AppColors.laranjaSuave : AppColors.verdeSuave,
        corBorda: destaque ? AppColors.laranja : AppColors.borda,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
        onTap: onTap,
        child: Column(children: [
          Icon(icone, size: 28, color: cor),
          const SizedBox(height: 6),
          Text(titulo, textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: cor)),
        ]),
      ),
    );
  }
}

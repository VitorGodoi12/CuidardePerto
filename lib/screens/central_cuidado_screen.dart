import 'package:flutter/material.dart';

import '../data/dados_cuidador.dart';
import '../models/central_cuidado.dart';
import '../models/idoso.dart';
import '../models/medicamento.dart';
import '../theme/app_theme.dart';
import 'lembretes_screen.dart';

/// Agenda e central de cuidado de uma pessoa acompanhada.
/// Todos os registros ficam no documento da pessoa, na conta do cuidador.
class CentralCuidadoScreen extends StatefulWidget {
  const CentralCuidadoScreen({super.key, required this.idoso, this.seletor, this.aoVoltar});
  final Idoso idoso;

  /// Cartão para trocar a pessoa (exibido no topo, como na referência).
  final Widget? seletor;
  final VoidCallback? aoVoltar;

  @override
  State<CentralCuidadoScreen> createState() => _CentralCuidadoScreenState();
}

class _CentralCuidadoScreenState extends State<CentralCuidadoScreen> {
  static bool _altoContraste = false;
  static bool _textoGrande = false;

  late DateTime _diaSelecionado = _soData(DateTime.now());

  CentralCuidado get central => widget.idoso.central;
  List<Consulta> get consultas => central.consultas;
  List<Registro> get diario => central.diario;
  List<Registro> get recados => central.recados;
  List<MembroEquipe> get equipe => central.equipe;
  Set<String> get rotina => central.rotina;
  int get agua => central.agua;
  String get humor => central.humor;
  bool get checkin => central.checkin;

  static DateTime _soData(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Registra no histórico e grava na conta do cuidador.
  void _mudou(String evento) {
    central.historico.insert(0, '${TimeOfDay.now().format(context)} • $evento');
    if (central.historico.length > 40) central.historico.removeLast();
    DadosCuidador.salvar(widget.idoso);
  }

  Future<String?> _textoDialogo(String titulo, String dica) async {
    final controller = TextEditingController();
    final valor = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 2,
          decoration: InputDecoration(hintText: dica, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Salvar')),
        ],
      ),
    );
    return valor;
  }

  Future<void> _adicionarCompromisso() async {
    final nova = await showModalBottomSheet<Consulta>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (ctx) => _FormularioCompromisso(diaInicial: _diaSelecionado),
    );
    if (nova == null || !mounted) return;
    setState(() {
      consultas.add(nova);
      final d = nova.dia;
      if (d != null) _diaSelecionado = _soData(d);
      _mudou('Compromisso adicionado: ${nova.nome}');
    });
  }

  Future<void> _adicionarDiario() async {
    final texto = await _textoDialogo('Registro do dia', 'Conte como foi o dia, observações ou cuidados realizados...');
    if (!mounted || texto == null || texto.isEmpty) return;
    setState(() {
      diario.insert(0, Registro(texto, TimeOfDay.now().format(context)));
      _mudou('Novo registro no diário');
    });
  }

  Future<void> _adicionarRecado() async {
    final texto = await _textoDialogo('Novo recado para a família', 'Escreva uma mensagem para a equipe de cuidado...');
    if (!mounted || texto == null || texto.isEmpty) return;
    setState(() {
      recados.insert(0, Registro(texto, TimeOfDay.now().format(context)));
      _mudou('Novo recado compartilhado');
    });
  }

  Future<void> _adicionarCuidador() async {
    final nome = await _textoDialogo('Adicionar pessoa à equipe', 'Nome da pessoa');
    if (!mounted || nome == null || nome.isEmpty) return;
    final papel = await _textoDialogo('Vínculo ou responsabilidade', 'Ex.: Filho • Cuidador');
    if (!mounted) return;
    setState(() {
      equipe.add(MembroEquipe(nome, (papel == null || papel.isEmpty) ? 'Apoio' : papel));
      _mudou('Pessoa adicionada à equipe: $nome');
    });
  }

  bool _mesmaData(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  String _nomeMes(int mes) {
    const nomes = ['janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho', 'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro'];
    return nomes[mes - 1];
  }

  bool _temCompromisso(DateTime dia) {
    if (consultas.any((c) => c.dia != null && _mesmaData(c.dia!, dia))) return true;
    return _mesmaData(dia, DateTime.now()) && widget.idoso.medicamentos.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final escala = _textoGrande ? 1.12 : 1.0;
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(primary: AppColors.primaria, surface: _altoContraste ? Colors.white : AppColors.fundo),
      ),
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(escala)),
        child: Scaffold(
          backgroundColor: _altoContraste ? Colors.white : AppColors.fundo,
          appBar: AppBar(
            title: const Text('Agenda'),
            leading: widget.aoVoltar == null
                ? null
                : IconButton(tooltip: 'Voltar ao início', icon: const Icon(Icons.arrow_back_rounded), onPressed: widget.aoVoltar),
            actions: [IconButton(tooltip: 'Lembretes', onPressed: _abrirNotificacoes, icon: const Icon(Icons.notifications_active_outlined))],
          ),
          body: ListView(padding: const EdgeInsets.fromLTRB(18, 12, 18, 28), children: [
            if (widget.seletor != null) ...[widget.seletor!, const SizedBox(height: 14)],
            _calendarioSemana(),
            const SizedBox(height: 14),
            _compromissosDoDia(),
            const SizedBox(height: 4),
            _secao('Rotina diária', 'Acompanhamento simples dos cuidados de hoje', Icons.today_outlined,
                trailing: Text('${rotina.length}/5', style: const TextStyle(color: AppColors.primaria, fontWeight: FontWeight.w800)),
                child: Column(children: [
                  for (final item in ['Café da manhã', 'Almoço', 'Jantar', 'Hidratação', 'Atividade / caminhada'])
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      value: rotina.contains(item),
                      title: Text(item),
                      onChanged: (v) => setState(() {
                        if (v == true) {
                          rotina.add(item);
                        } else {
                          rotina.remove(item);
                        }
                        _mudou('$item ${v == true ? 'concluído' : 'desmarcado'}');
                      }),
                    ),
                  const Divider(),
                  Row(children: [
                    const Icon(Icons.water_drop_outlined, color: AppColors.primaria),
                    const SizedBox(width: 8),
                    const Expanded(child: Text('Copos de água registrados', style: TextStyle(fontWeight: FontWeight.w600))),
                    IconButton(
                      tooltip: 'Menos um copo',
                      onPressed: () => setState(() {
                        if (central.agua > 0) {
                          central.agua--;
                          DadosCuidador.salvar(widget.idoso);
                        }
                      }),
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text('$agua', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                    IconButton(
                      tooltip: 'Mais um copo',
                      onPressed: () => setState(() {
                        central.agua++;
                        _mudou('Hidratação atualizada');
                      }),
                      icon: const Icon(Icons.add_circle, color: AppColors.primaria),
                    ),
                  ]),
                ])),
            _secao('Check-in diário', 'Confirme como está o acompanhamento', Icons.favorite_outline,
                child: Row(children: [
                  Expanded(child: Text(checkin ? 'Check-in realizado hoje' : 'Ainda não realizado hoje', style: const TextStyle(fontWeight: FontWeight.w600))),
                  FilledButton(
                    onPressed: () => setState(() {
                      final antes = central.checkin;
                      central.checkin = !antes;
                      _mudou(antes ? 'Check-in desfeito' : 'Check-in diário realizado');
                    }),
                    child: Text(checkin ? 'Desfazer' : 'Está tudo bem'),
                  ),
                ])),
            _secao('Como está se sentindo?', 'Registro de humor • não é avaliação médica', Icons.mood_outlined,
                child: Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final item in ['Muito bem', 'Bem', 'Mais ou menos', 'Triste', 'Desconfortável'])
                    ChoiceChip(
                      label: Text(item),
                      selected: humor == item,
                      onSelected: (_) => setState(() {
                        central.humor = item;
                        _mudou('Humor registrado: $item');
                      }),
                    ),
                ])),
            _secao('Agenda de consultas', 'Consultas, exames e compromissos', Icons.calendar_month_outlined,
                trailing: IconButton(tooltip: 'Adicionar compromisso', onPressed: _adicionarCompromisso, icon: const Icon(Icons.add_circle, color: AppColors.primaria)),
                child: consultas.isEmpty
                    ? const Text('Nenhum compromisso cadastrado.', style: TextStyle(color: AppColors.textoSuave))
                    : Column(children: [for (final c in consultas) _linhaAgenda(c)])),
            _secao('Diário de cuidados', 'Anotações compartilhadas sobre o dia', Icons.menu_book_outlined,
                trailing: IconButton(tooltip: 'Novo registro', onPressed: _adicionarDiario, icon: const Icon(Icons.add_circle, color: AppColors.primaria)),
                child: diario.isEmpty
                    ? const Text('Nenhum registro adicionado ainda.', style: TextStyle(color: AppColors.textoSuave))
                    : Column(children: [
                        for (final r in diario)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const CircleAvatar(backgroundColor: AppColors.verdeSuave, child: Icon(Icons.edit_note, color: AppColors.primaria)),
                            title: Text(r.texto),
                            subtitle: Text('Hoje • ${r.hora}'),
                          ),
                      ])),
            _secao('Mural de recados', 'Mensagens para familiares e cuidadores', Icons.forum_outlined,
                trailing: IconButton(tooltip: 'Novo recado', onPressed: _adicionarRecado, icon: const Icon(Icons.add_circle, color: AppColors.primaria)),
                child: recados.isEmpty
                    ? const Text('Nenhum recado ainda.', style: TextStyle(color: AppColors.textoSuave))
                    : Column(children: [
                        for (final r in recados)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const CircleAvatar(backgroundColor: AppColors.verdeSuave, child: Icon(Icons.sticky_note_2_outlined, color: AppColors.primaria)),
                            title: Text(r.texto),
                            subtitle: Text(r.hora),
                          ),
                      ])),
            _secao('Equipe de cuidado', 'Familiares e pessoas de apoio', Icons.groups_2_outlined,
                trailing: IconButton(tooltip: 'Adicionar pessoa', onPressed: _adicionarCuidador, icon: const Icon(Icons.person_add_alt_1, color: AppColors.primaria)),
                child: equipe.isEmpty
                    ? const Text('Nenhuma pessoa na equipe ainda.', style: TextStyle(color: AppColors.textoSuave))
                    : Column(children: [
                        for (final p in equipe)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const CircleAvatar(backgroundColor: AppColors.verdeSuave, child: Icon(Icons.person_outline, color: AppColors.primaria)),
                            title: Text(p.nome, style: const TextStyle(fontWeight: FontWeight.w700)),
                            subtitle: Text(p.papel),
                            trailing: IconButton(
                              tooltip: 'Remover da equipe',
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () => setState(() {
                                equipe.remove(p);
                                _mudou('${p.nome} removido da equipe');
                              }),
                            ),
                          ),
                      ])),
            _secao('Plano de emergência', 'Informações rápidas para uma situação crítica', Icons.health_and_safety_outlined,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('1. Verifique a situação e mantenha a calma.\n2. Entre em contato com o responsável principal.\n3. Em uma emergência real, acione o serviço público adequado (SAMU 192).', style: TextStyle(height: 1.5)),
                  const SizedBox(height: 10),
                  Text('Contato principal: ${widget.idoso.contatoPrincipal?.nome ?? 'Não cadastrado'}', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primariaEscura)),
                  const SizedBox(height: 4),
                  Text('Endereço: ${widget.idoso.endereco}', style: const TextStyle(color: AppColors.textoSuave)),
                ])),
            _secao('Linha do tempo e alterações', 'Atividades recentes registradas', Icons.timeline,
                trailing: IconButton(tooltip: 'Ver histórico completo', onPressed: _abrirHistorico, icon: const Icon(Icons.history, color: AppColors.primaria)),
                child: central.historico.isEmpty
                    ? const Text('As próximas alterações aparecerão aqui.', style: TextStyle(color: AppColors.textoSuave))
                    : Column(children: [
                        for (final h in central.historico.take(4))
                          ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: const Icon(Icons.circle, size: 9, color: AppColors.primaria), title: Text(h)),
                      ])),
            _secao('Relatório de acompanhamento', 'Resumo do estado atual', Icons.insights_outlined,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _indicador('Rotina concluída', '${rotina.length} de 5 tarefas', rotina.length / 5),
                  _indicador('Medicamentos tomados', widget.idoso.resumoMedicamentos, widget.idoso.progressoDoses),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(onPressed: _mostrarRelatorio, icon: const Icon(Icons.summarize_outlined), label: const Text('Ver relatório completo')),
                ])),
            _secao('Acessibilidade', 'Adapte a leitura às suas necessidades', Icons.accessibility_new,
                child: Column(children: [
                  SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Texto maior'), value: _textoGrande, onChanged: (v) => setState(() => _textoGrande = v)),
                  SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Alto contraste'), value: _altoContraste, onChanged: (v) => setState(() => _altoContraste = v)),
                ])),
            const SizedBox(height: 12),
            const Text('Os registros desta central ficam salvos na sua conta. Não substituem orientação médica nem monitoramento profissional.',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.textoSuave, height: 1.4)),
          ]),
        ),
      ),
    );
  }

  /// Faixa semanal (D S T Q Q S S) com navegação por semana.
  Widget _calendarioSemana() {
    final inicioSemana = _diaSelecionado.subtract(Duration(days: _diaSelecionado.weekday % 7));
    final dias = List.generate(7, (i) => inicioSemana.add(Duration(days: i)));
    final titulo = '${_nomeMes(_diaSelecionado.month)[0].toUpperCase()}${_nomeMes(_diaSelecionado.month).substring(1)} ${_diaSelecionado.year}';
    return Cartao(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      child: Column(children: [
        Row(children: [
          IconButton(
            tooltip: 'Semana anterior',
            visualDensity: VisualDensity.compact,
            onPressed: () => setState(() => _diaSelecionado = _diaSelecionado.subtract(const Duration(days: 7))),
            icon: const Icon(Icons.chevron_left_rounded, color: AppColors.texto),
          ),
          Expanded(child: Text(titulo, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.texto))),
          IconButton(
            tooltip: 'Próxima semana',
            visualDensity: VisualDensity.compact,
            onPressed: () => setState(() => _diaSelecionado = _diaSelecionado.add(const Duration(days: 7))),
            icon: const Icon(Icons.chevron_right_rounded, color: AppColors.texto),
          ),
        ]),
        const SizedBox(height: 4),
        Row(children: ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'].map((d) => Expanded(child: Center(child: Text(d, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textoSuave))))).toList()),
        const SizedBox(height: 6),
        Row(children: [
          for (final dia in dias)
            Expanded(
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => setState(() => _diaSelecionado = dia),
                child: Column(children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _mesmaData(dia, _diaSelecionado) ? AppColors.primariaEscura : Colors.transparent,
                      shape: BoxShape.circle,
                      border: _mesmaData(dia, DateTime.now()) && !_mesmaData(dia, _diaSelecionado) ? Border.all(color: AppColors.primaria) : null,
                    ),
                    child: Text('${dia.day}',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: _mesmaData(dia, _diaSelecionado) ? Colors.white : AppColors.texto,
                        )),
                  ),
                  const SizedBox(height: 3),
                  Container(width: 5, height: 5, decoration: BoxDecoration(color: _temCompromisso(dia) ? AppColors.turquesa : Colors.transparent, shape: BoxShape.circle)),
                ]),
              ),
            ),
        ]),
      ]),
    );
  }

  /// Compromissos do dia: consultas/exames e doses de medicamento (no dia de hoje).
  Widget _compromissosDoDia() {
    final itens = <_ItemDia>[];
    for (final c in consultas) {
      if (c.dia != null && _mesmaData(c.dia!, _diaSelecionado)) {
        itens.add(_ItemDia(hora: c.hora, titulo: c.nome, subtitulo: c.local, icone: Icons.event_available_rounded, consulta: c));
      }
    }
    if (_mesmaData(_diaSelecionado, DateTime.now())) {
      for (final m in widget.idoso.medicamentos) {
        itens.add(_ItemDia(hora: m.horario, titulo: 'Medicamento', subtitulo: m.nome, icone: Icons.medication_rounded, medicamento: m));
      }
    }
    itens.sort((a, b) => (a.hora.isEmpty ? '99:99' : a.hora).compareTo(b.hora.isEmpty ? '99:99' : b.hora));
    final data = _diaSelecionado;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text('Compromissos do dia', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.texto))),
        Text('${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 13, color: AppColors.textoSuave)),
      ]),
      const SizedBox(height: 8),
      if (itens.isEmpty)
        const Cartao(child: Text('Nenhum compromisso para este dia.', style: TextStyle(color: AppColors.textoSuave)))
      else
        for (final item in itens)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Cartao(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(color: Color(0xFFE5F7F4), shape: BoxShape.circle),
                  child: Icon(item.icone, color: AppColors.primariaEscura),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(item.hora.isEmpty ? 'Dia todo' : item.hora, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.texto)),
                    Text(item.titulo, style: const TextStyle(fontSize: 13.5, color: AppColors.texto)),
                    if (item.subtitulo.isNotEmpty) Text(item.subtitulo, style: const TextStyle(fontSize: 12.5, color: AppColors.textoSuave)),
                  ]),
                ),
                if (item.medicamento != null)
                  InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => setState(() {
                      item.medicamento!.tomado = !item.medicamento!.tomado;
                      _mudou('${item.medicamento!.nome} ${item.medicamento!.tomado ? 'marcado como tomado' : 'desmarcado'}');
                    }),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: item.medicamento!.tomado ? AppColors.primariaEscura : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primariaEscura, width: 1.5),
                      ),
                      child: Icon(Icons.check_rounded, size: 18, color: item.medicamento!.tomado ? Colors.white : AppColors.borda),
                    ),
                  )
                else
                  IconButton(
                    tooltip: 'Remover compromisso',
                    icon: const Icon(Icons.delete_outline, color: AppColors.textoSuave),
                    onPressed: () => setState(() {
                      consultas.remove(item.consulta);
                      _mudou('Compromisso removido: ${item.titulo}');
                    }),
                  ),
              ]),
            ),
          ),
      const SizedBox(height: 6),
      SizedBox(
        height: 54,
        child: ElevatedButton.icon(
          onPressed: _adicionarCompromisso,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Adicionar compromisso'),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primariaEscura, shape: const StadiumBorder(), textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        ),
      ),
    ]);
  }

  Widget _secao(String titulo, String subtitulo, IconData icone, {required Widget child, Widget? trailing}) => Padding(
        padding: const EdgeInsets.only(top: 13),
        child: Cartao(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: AppColors.verdeSuave, borderRadius: BorderRadius.circular(13)),
                child: Icon(icone, color: AppColors.primaria),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(titulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  Text(subtitulo, style: const TextStyle(fontSize: 12, color: AppColors.textoSuave)),
                ]),
              ),
              if (trailing != null) trailing,
            ]),
            const SizedBox(height: 13),
            child,
          ]),
        ),
      );

  Widget _linhaAgenda(Consulta c) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const CircleAvatar(backgroundColor: AppColors.verdeSuave, child: Icon(Icons.event, color: AppColors.primaria)),
        title: Text(c.nome, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('${c.data}${c.hora.isEmpty ? '' : ' • ${c.hora}'}${c.local.isEmpty ? '' : '\n${c.local}'}'),
        isThreeLine: c.local.isNotEmpty,
        trailing: IconButton(
          tooltip: 'Remover compromisso',
          icon: const Icon(Icons.delete_outline),
          onPressed: () => setState(() {
            consultas.remove(c);
            _mudou('Compromisso removido: ${c.nome}');
          }),
        ),
      );

  Widget _indicador(String nome, String valor, double progresso) => Padding(
        padding: const EdgeInsets.only(bottom: 13),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(nome, style: const TextStyle(fontWeight: FontWeight.w600))),
            Text(valor, style: const TextStyle(color: AppColors.primaria, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 7),
          ClipRRect(borderRadius: BorderRadius.circular(20), child: LinearProgressIndicator(value: progresso.clamp(0.0, 1.0).toDouble(), minHeight: 8)),
        ]),
      );

  void _abrirNotificacoes() => Navigator.push(context, MaterialPageRoute(builder: (_) => const LembretesScreen()));

  void _abrirHistorico() => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (ctx) => SafeArea(
          child: SizedBox(
            height: MediaQuery.of(ctx).size.height * .65,
            child: ListView(padding: const EdgeInsets.all(20), children: [
              const Text('Histórico de alterações', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              if (central.historico.isEmpty) const Text('Nenhuma alteração registrada ainda.'),
              for (final item in central.historico) ListTile(leading: const Icon(Icons.history, color: AppColors.primaria), title: Text(item)),
            ]),
          ),
        ),
      );

  void _mostrarRelatorio() => showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Resumo de acompanhamento'),
          content: Text(
              'Pessoa acompanhada: ${widget.idoso.nome}\n\nRotina: ${rotina.length}/5 tarefas concluídas\nHidratação: $agua copos registrados\nHumor: ${humor.isEmpty ? 'não registrado' : humor}\nCheck-in: ${checkin ? 'realizado' : 'pendente'}\nMedicamentos: ${widget.idoso.resumoMedicamentos}\nAlertas abertos: ${widget.idoso.alertasAbertos}\nCompromissos cadastrados: ${consultas.length}\nRegistros no diário: ${diario.length}\nRecados da família: ${recados.length}\n\nEste resumo não representa avaliação clínica.'),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fechar'))],
        ),
      );
}

class _ItemDia {
  _ItemDia({required this.hora, required this.titulo, required this.subtitulo, required this.icone, this.consulta, this.medicamento});
  final String hora;
  final String titulo;
  final String subtitulo;
  final IconData icone;
  final Consulta? consulta;
  final Medicamento? medicamento;
}

/// Formulário de novo compromisso com seletores de data e hora.
class _FormularioCompromisso extends StatefulWidget {
  const _FormularioCompromisso({required this.diaInicial});
  final DateTime diaInicial;

  @override
  State<_FormularioCompromisso> createState() => _FormularioCompromissoState();
}

class _FormularioCompromissoState extends State<_FormularioCompromisso> {
  final _form = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _local = TextEditingController();
  late DateTime _data = widget.diaInicial;
  TimeOfDay? _hora;

  @override
  void dispose() {
    _nome.dispose();
    _local.dispose();
    super.dispose();
  }

  Future<void> _escolherData() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime(DateTime.now().year + 5),
    );
    if (d != null) setState(() => _data = d);
  }

  Future<void> _escolherHora() async {
    final h = await showTimePicker(context: context, initialTime: _hora ?? const TimeOfDay(hour: 9, minute: 0));
    if (h != null) setState(() => _hora = h);
  }

  void _salvar() {
    if (!_form.currentState!.validate()) return;
    final hora = _hora == null ? '' : '${_hora!.hour.toString().padLeft(2, '0')}:${_hora!.minute.toString().padLeft(2, '0')}';
    Navigator.pop(context, Consulta(_nome.text.trim(), Consulta.formatarData(_data), hora, _local.text.trim()));
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Text('Novo compromisso', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.texto)),
              const SizedBox(height: 14),
              TextFormField(
                controller: _nome,
                textCapitalization: TextCapitalization.sentences,
                decoration: AppTheme.campo(rotulo: 'Título', dica: 'Ex.: Consulta médica', icone: Icons.event_note_rounded),
                validator: (v) => (v == null || v.trim().length < 2) ? 'Informe o título' : null,
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _escolherData,
                    icon: const Icon(Icons.calendar_today_rounded, size: 18),
                    label: Text(Consulta.formatarData(_data)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _escolherHora,
                    icon: const Icon(Icons.schedule_rounded, size: 18),
                    label: Text(_hora == null ? 'Horário' : _hora!.format(context)),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              TextFormField(controller: _local, decoration: AppTheme.campo(rotulo: 'Profissional ou local (opcional)', icone: Icons.place_outlined)),
              const SizedBox(height: 18),
              ElevatedButton(onPressed: _salvar, style: ElevatedButton.styleFrom(shape: const StadiumBorder()), child: const Text('Salvar compromisso')),
            ]),
          ),
        ),
      );
}

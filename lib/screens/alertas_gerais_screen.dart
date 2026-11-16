import 'package:flutter/material.dart';

import '../data/dados_cuidador.dart';
import '../models/alerta.dart';
import '../theme/app_theme.dart';
import '../widgets/alerta_card.dart';

class AlertasGeraisScreen extends StatefulWidget {
  const AlertasGeraisScreen({super.key});

  @override
  State<AlertasGeraisScreen> createState() => _AlertasGeraisScreenState();
}

class _AlertasGeraisScreenState extends State<AlertasGeraisScreen> {
  String _filtro = 'Todos';

  List<Alerta> get _alertas {
    final todos = DadosCuidador.idosos.expand((idoso) => idoso.alertas).toList()
      ..sort((a, b) => b.dataHora.compareTo(a.dataHora));
    return todos.where((alerta) {
      switch (_filtro) {
        case 'Abertos':
          return !alerta.resolvido;
        case 'Críticos':
          return alerta.tipo.critico;
        case 'Resolvidos':
          return alerta.resolvido;
        default:
          return true;
      }
    }).toList();
  }

  Future<void> _resolver(Alerta alerta) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resolver alerta?'),
        content: Text('Confirme que a situação de ${alerta.idoso.nome} já foi verificada e resolvida.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Resolver')),
        ],
      ),
    );
    if (confirmou == true && mounted) {
      setState(() => alerta.resolvido = true);
      DadosCuidador.salvar(alerta.idoso);
      Mensagens.sucesso(context, 'Alerta marcado como resolvido.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final lista = _alertas;
    final abertos = DadosCuidador.idosos.fold<int>(0, (soma, idoso) => soma + idoso.alertasAbertos);
    return Scaffold(
      appBar: AppBar(title: const Text('Alertas e histórico')),
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: abertos > 0 ? const Color(0xFFFFF5ED) : AppColors.verdeSuave,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: abertos > 0 ? const Color(0xFFF5D7BF) : AppColors.borda),
            ),
            child: Row(children: [
              Icon(abertos > 0 ? Icons.notifications_active_rounded : Icons.check_circle_rounded,
                color: abertos > 0 ? AppColors.laranjaTexto : AppColors.sucessoEscuro, size: 30),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('$abertos alertas em aberto', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.texto)),
                const SizedBox(height: 3),
                const Text('Acompanhe os registros de todas as pessoas.', style: TextStyle(fontSize: 13, color: AppColors.textoSuave)),
              ])),
            ]),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          child: Row(children: [
            for (final filtro in ['Todos', 'Abertos', 'Críticos', 'Resolvidos'])
              Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(
                label: Text(filtro), selected: _filtro == filtro,
                selectedColor: AppColors.primaria, backgroundColor: Colors.white,
                side: BorderSide(color: _filtro == filtro ? AppColors.primaria : AppColors.borda),
                labelStyle: TextStyle(color: _filtro == filtro ? Colors.white : AppColors.primariaEscura, fontWeight: FontWeight.w700),
                onSelected: (_) => setState(() => _filtro = filtro),
              )),
          ]),
        ),
        Expanded(
          child: lista.isEmpty
              ? const Center(child: Text('Nenhum alerta encontrado neste filtro.'))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
                  itemCount: lista.length,
                  itemBuilder: (context, index) {
                    final alerta = lista[index];
                    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      if (index == 0 || lista[index - 1].idoso.id != alerta.idoso.id)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(2, 5, 2, 9),
                          child: Text(alerta.idoso.nome, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primariaEscura)),
                        ),
                      AlertaCard(
                        alerta: alerta,
                        primeiro: index == 0,
                        ultimo: index == lista.length - 1,
                        onResolver: alerta.resolvido ? null : () => _resolver(alerta),
                      ),
                    ]);
                  },
                ),
        ),
      ]),
    );
  }
}

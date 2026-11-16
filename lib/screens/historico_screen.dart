import 'package:flutter/material.dart';

import '../data/dados_cuidador.dart';

import '../models/alerta.dart';
import '../models/idoso.dart';
import '../theme/app_theme.dart';
import '../widgets/alerta_card.dart';
import '../widgets/aparecer.dart';

class HistoricoScreen extends StatefulWidget {
  const HistoricoScreen({super.key, required this.idoso});

  final Idoso idoso;

  @override
  State<HistoricoScreen> createState() => _HistoricoScreenState();
}

class _HistoricoScreenState extends State<HistoricoScreen> {
  Idoso get idoso => widget.idoso;

  NivelRisco? _filtro;

  static const List<NivelRisco?> _opcoes = [
    null,
    NivelRisco.critico,
    NivelRisco.alto,
    NivelRisco.medio,
  ];

  List<Alerta> get _filtrados {
    final lista = idoso.alertas.where((a) => _filtro == null || a.nivel == _filtro).toList();
    lista.sort((a, b) => b.dataHora.compareTo(a.dataHora));
    return lista;
  }

  Future<void> _resolver(Alerta alerta) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (contextoDialogo) => AlertDialog(
        title: const Text('Resolver alerta?'),
        content: Text(
          '${alerta.tipo.titulo} - ${alerta.quando}.\n\n'
          'Confirme apenas se a situação de ${idoso.nome} já foi resolvida.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contextoDialogo, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(contextoDialogo, true),
            child: const Text('Resolver'),
          ),
        ],
      ),
    );
    if (confirmou == true && mounted) {
      setState(() => alerta.resolvido = true);
    DadosCuidador.salvar(alerta.idoso);
      Mensagens.sucesso(context, 'Alerta marcado como resolvido');
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    final lista = _filtrados;

    return Scaffold(
      appBar: AppBar(title: const Text('Histórico de alertas')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Espaco.m, Espaco.m, Espaco.m, 0),
            child: Text(
              '${idoso.nome}: ${idoso.alertasAbertos} aberto(s), '
              '${idoso.alertas.length - idoso.alertasAbertos} resolvido(s)',
              style: tema.titleMedium,
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Espaco.m, vertical: 12),
            child: Row(
              children: [
                for (final nivel in _opcoes)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(nivel == null ? 'Todos' : nivel.nome),
                      selected: _filtro == nivel,
                      showCheckmark: true,
                      checkmarkColor: Colors.white,
                      selectedColor: AppColors.primaria,
                      backgroundColor: Colors.white,
                      side: BorderSide(color: _filtro == nivel ? AppColors.primaria : const Color(0xFFDCE7E4)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      labelStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _filtro == nivel ? Colors.white : AppColors.primariaEscura,
                      ),
                      onSelected: (_) => setState(() => _filtro = nivel),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: lista.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(Espaco.g),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.inbox_outlined, size: 56, color: AppColors.textoSuave),
                          const SizedBox(height: 8),
                          Text('Nenhum alerta neste filtro', style: tema.titleMedium),
                          const SizedBox(height: 4),
                          const Text('Escolha outro nível ou toque em "Todos".'),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(Espaco.m, 0, Espaco.m, Espaco.m),
                    itemCount: lista.length,
                    itemBuilder: (context, indice) {
                      final alerta = lista[indice];
                      final item = AlertaCard(
                        alerta: alerta,
                        primeiro: indice == 0,
                        ultimo: indice == lista.length - 1,
                        onResolver: alerta.resolvido ? null : () => _resolver(alerta),
                      );
                      return Aparecer(ordem: indice, child: item);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

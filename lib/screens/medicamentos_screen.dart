import 'package:flutter/material.dart';

import '../data/dados_cuidador.dart';
import '../models/idoso.dart';
import '../models/medicamento.dart';
import '../theme/app_theme.dart';
import '../widgets/aparecer.dart';
import '../widgets/seletor_pessoa.dart';
import 'cadastro_medicamento_screen.dart';

class MedicamentosScreen extends StatefulWidget {
  const MedicamentosScreen({super.key, required this.idoso});

  final Idoso idoso;

  @override
  State<MedicamentosScreen> createState() => _MedicamentosScreenState();
}

class _MedicamentosScreenState extends State<MedicamentosScreen> {
  late Idoso idoso = widget.idoso;

  List<Medicamento> get _ordenados {
    final lista = List<Medicamento>.of(idoso.medicamentos);
    lista.sort((a, b) => a.minutos.compareTo(b.minutos));
    return lista;
  }

  void _alternarTomado(Medicamento medicamento) {
    setState(() => medicamento.tomado = !medicamento.tomado);
    DadosCuidador.salvar(idoso);
  }

  Future<void> _novoMedicamento() async {
    final novo = await Navigator.push<Medicamento>(
      context,
      MaterialPageRoute(builder: (_) => CadastroMedicamentoScreen(idoso: idoso)),
    );
    if (novo != null && mounted) {
      setState(() => idoso.medicamentos.add(novo));
      DadosCuidador.salvar(idoso);
    }
  }

  Future<void> _remover(Medicamento m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover medicamento?'),
        content: Text('${m.nome} ${m.dose} será removido da lista de ${idoso.nome}.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remover')),
        ],
      ),
    );
    if (ok == true && mounted) {
      setState(() => idoso.medicamentos.remove(m));
      DadosCuidador.salvar(idoso);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lista = _ordenados;
    final atrasadas = idoso.dosesAtrasadas;
    final pessoas = DadosCuidador.idosos.isEmpty ? [idoso] : DadosCuidador.idosos;

    return Scaffold(
      backgroundColor: AppColors.fundo,
      appBar: AppBar(title: const Text('Medicamentos')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
        children: [
          SeletorPessoa(atual: idoso, pessoas: pessoas, aoEscolher: (p) => setState(() => idoso = p)),
          const SizedBox(height: 18),
          Row(children: [
            const Expanded(child: Text('Medicamentos ativos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.texto))),
            if (idoso.medicamentos.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                decoration: BoxDecoration(color: AppColors.verdeSuave, borderRadius: BorderRadius.circular(20)),
                child: Text('${idoso.dosesTomadas} de ${idoso.medicamentos.length}',
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.sucessoEscuro)),
              ),
          ]),
          if (idoso.medicamentos.isNotEmpty) ...[
            const SizedBox(height: 10),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(end: idoso.progressoDoses),
              duration: const Duration(milliseconds: 400),
              builder: (context, valor, filho) => ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(value: valor, minHeight: 9, backgroundColor: const Color(0xFFDDEBE7)),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              atrasadas == 0 ? 'Nenhum remédio atrasado.' : (atrasadas == 1 ? '1 dose atrasada' : '$atrasadas doses atrasadas'),
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: atrasadas == 0 ? AppColors.textoSuave : AppColors.laranjaTexto),
            ),
          ],
          const SizedBox(height: 12),
          if (lista.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Column(children: [
                Icon(Icons.medication_outlined, size: 56, color: AppColors.textoSuave),
                SizedBox(height: 8),
                Text('Nenhum medicamento cadastrado', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.texto)),
                SizedBox(height: 4),
                Text('Use o botão abaixo para cadastrar o primeiro.'),
              ]),
            ),
          for (var i = 0; i < lista.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Aparecer(
                ordem: i,
                child: _MedicamentoItem(medicamento: lista[i], onAlternar: () => _alternarTomado(lista[i]), onRemover: () => _remover(lista[i])),
              ),
            ),
          const SizedBox(height: 8),
          SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _novoMedicamento,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Adicionar Medicamento'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primariaEscura,
                shape: const StadiumBorder(),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicamentoItem extends StatelessWidget {
  const _MedicamentoItem({required this.medicamento, required this.onAlternar, required this.onRemover});

  final Medicamento medicamento;
  final VoidCallback onAlternar;
  final VoidCallback onRemover;

  @override
  Widget build(BuildContext context) {
    final m = medicamento;
    final atrasado = m.atrasado;
    final Color fundoChip;
    final Color corChip;
    if (m.tomado) {
      fundoChip = const Color(0xFFDCFCE7);
      corChip = const Color(0xFF166534);
    } else if (atrasado) {
      fundoChip = AppColors.laranjaSuave;
      corChip = AppColors.laranjaTexto;
    } else {
      fundoChip = AppColors.verdeSuave;
      corChip = AppColors.primariaEscura;
    }
    final estado = m.tomado ? 'tomado' : (atrasado ? 'atrasado' : 'pendente');

    return Semantics(
      container: true,
      checked: m.tomado,
      onTap: onAlternar,
      label: '${m.nome}, ${m.dose}, às ${m.horario}, $estado',
      excludeSemantics: true,
      child: Material(
        color: Colors.white,
        elevation: 1,
        shadowColor: const Color(0x160B5C59),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onAlternar,
          onLongPress: onRemover,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(color: m.tomado ? AppColors.riscoBaixo : const Color(0xFFE5F7F4), shape: BoxShape.circle),
                child: Icon(m.tomado ? Icons.check_rounded : Icons.medication_rounded, color: m.tomado ? Colors.white : AppColors.primariaEscura, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(m.nome,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.texto,
                        decoration: m.tomado ? TextDecoration.lineThrough : null,
                      )),
                  Text(m.dose, style: const TextStyle(fontSize: 13, color: AppColors.textoSuave)),
                  if (m.observacao.isNotEmpty) Text(m.observacao, style: const TextStyle(fontSize: 12, color: AppColors.textoSuave)),
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: fundoChip, borderRadius: BorderRadius.circular(18)),
                child: Text(m.horario, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: corChip)),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textoSuave),
            ]),
          ),
        ),
      ),
    );
  }
}

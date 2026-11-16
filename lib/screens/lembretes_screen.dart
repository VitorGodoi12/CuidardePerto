import 'package:flutter/material.dart';

import '../data/dados_cuidador.dart';
import '../models/idoso.dart';
import '../models/medicamento.dart';
import '../theme/app_theme.dart';
import '../widgets/idoso_card.dart';

class _DosePendente {
  const _DosePendente(this.idoso, this.medicamento);
  final Idoso idoso;
  final Medicamento medicamento;
}

class LembretesScreen extends StatefulWidget {
  const LembretesScreen({super.key});

  @override
  State<LembretesScreen> createState() => _LembretesScreenState();
}

class _LembretesScreenState extends State<LembretesScreen> {
  List<_DosePendente> get _pendentes {
    final itens = <_DosePendente>[];
    for (final idoso in DadosCuidador.idosos) {
      for (final medicamento in idoso.medicamentos.where((m) => !m.tomado)) {
        itens.add(_DosePendente(idoso, medicamento));
      }
    }
    itens.sort((a, b) => a.medicamento.minutos.compareTo(b.medicamento.minutos));
    return itens;
  }

  Future<void> _abrir(_DosePendente dose) async {
    final marcou = await Navigator.push<bool>(context, MaterialPageRoute(
      builder: (_) => LembreteDetalheScreen(idoso: dose.idoso, medicamento: dose.medicamento),
    ));
    if (marcou == true && mounted) {
      setState(() => dose.medicamento.tomado = true);
      DadosCuidador.salvar(dose.idoso);
      Mensagens.sucesso(context, 'Dose marcada como tomada.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendentes = _pendentes;
    return Scaffold(
      appBar: AppBar(title: const Text('Lembretes')),
      body: pendentes.isEmpty
          ? const Center(child: Padding(padding: EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.notifications_off_outlined, color: AppColors.primaria, size: 58),
              SizedBox(height: 14),
              Text('Tudo em dia!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.texto)),
              SizedBox(height: 6),
              Text('Não há doses pendentes no momento.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textoSuave)),
            ])))
          : ListView(padding: const EdgeInsets.fromLTRB(18, 16, 18, 24), children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.primariaEscura, AppColors.primaria, AppColors.turquesa]),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(children: [
                  const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 36),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${pendentes.length} lembrete${pendentes.length == 1 ? '' : 's'}', style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    const Text('Toque em um item para ver os detalhes.', style: TextStyle(color: Color(0xFFE1F8F2), fontSize: 13)),
                  ])),
                ]),
              ),
              const SizedBox(height: 18),
              for (final dose in pendentes)
                Padding(
                  padding: const EdgeInsets.only(bottom: 11),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(19),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(19),
                      onTap: () => _abrir(dose),
                      child: Padding(padding: const EdgeInsets.all(15), child: Row(children: [
                        AvatarIdoso(caminho: dose.idoso.avatar, tamanho: 50),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(dose.idoso.nome, style: const TextStyle(fontSize: 14, color: AppColors.textoSuave)),
                          Text(dose.medicamento.nome, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.texto)),
                          Text('Às ${dose.medicamento.horario} • ${dose.medicamento.dose}', style: const TextStyle(fontSize: 13, color: AppColors.textoSuave)),
                        ])),
                        const Icon(Icons.chevron_right_rounded, color: AppColors.primaria, size: 26),
                      ])),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              const Text('Os lembretes aparecem dentro do aplicativo, conforme os medicamentos cadastrados.', textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.textoSuave)),
            ]),
    );
  }
}

class LembreteDetalheScreen extends StatelessWidget {
  const LembreteDetalheScreen({super.key, required this.idoso, required this.medicamento});
  final Idoso idoso;
  final Medicamento medicamento;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF087F82), Color(0xFF10AAA7), Color(0xFF55D4BE)]),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(26),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(tooltip: 'Voltar', onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded, color: Colors.white)),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: .12), shape: BoxShape.circle),
                    child: const Icon(Icons.notifications_active_rounded, color: Color(0xFFFFC83D), size: 104),
                  ),
                  const SizedBox(height: 28),
                  const Text('Lembrete!', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -.5)),
                  const SizedBox(height: 14),
                  Text('${idoso.nome} precisa tomar ${medicamento.nome} às ${medicamento.horario}.',
                      textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 18, height: 1.4, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(medicamento.dose, style: const TextStyle(color: Color(0xFFE0FFF8), fontSize: 15)),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primariaEscura, shape: const StadiumBorder()),
                      child: const Text('Entendi!', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white, width: 1.3), shape: const StadiumBorder()),
                      child: const Text('Marcar como tomado', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

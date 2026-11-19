import 'package:flutter/material.dart';

import '../models/alerta.dart';
import '../models/central_cuidado.dart';
import '../models/idoso.dart';
import '../services/memory_repositories.dart';
import '../state/sessao.dart';
import '../widgets/risco_badge.dart';

class PainelFamiliarScreen extends StatefulWidget {
  const PainelFamiliarScreen({super.key, required this.sessao});

  final Sessao sessao;

  @override
  State<PainelFamiliarScreen> createState() => _PainelFamiliarScreenState();
}

class _PainelFamiliarScreenState extends State<PainelFamiliarScreen> {
  final _idosos = DadosEmMemoria.criarIdososDemo();

  @override
  Widget build(BuildContext context) {
    final perfil = widget.sessao.perfil!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Área do familiar'),
        actions: [
          IconButton(
            tooltip: 'Sair da conta',
            icon: const Icon(Icons.logout),
            onPressed: widget.sessao.sair,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Olá, ${perfil.primeiroNome}!', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text('Toque em uma pessoa para consultar seu acompanhamento.'),
          const SizedBox(height: 12),
          const Card(
            child: ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('Dados fictícios de demonstração'),
              subtitle: Text('Acesso de consulta. O vínculo com cuidadores ainda não está disponível.'),
            ),
          ),
          const SizedBox(height: 12),
          for (final idoso in _idosos) _ResumoAcompanhamento(idoso: idoso),
        ],
      ),
    );
  }
}

class _ResumoAcompanhamento extends StatelessWidget {
  const _ResumoAcompanhamento({required this.idoso});

  final Idoso idoso;

  @override
  Widget build(BuildContext context) {
    final hoje = Consulta.formatarData(DateTime.now());
    return Card(
      child: ExpansionTile(
        title: Text(idoso.nome),
        subtitle: Text('${idoso.idade} anos · ${idoso.resumoMedicamentos}'),
        leading: CircleAvatar(backgroundImage: AssetImage(idoso.avatar)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RiscoBadge(nivel: idoso.risco),
          const SizedBox(height: 8),
          Text('Último movimento: ${idoso.ultimoMovimento}'),
          Text(idoso.central.checkin ? 'Check-in registrado' : 'Check-in pendente'),
          const Divider(),
          Text('Medicamentos', style: Theme.of(context).textTheme.titleSmall),
          for (final medicamento in idoso.medicamentos)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(medicamento.nome),
              subtitle: Text('${medicamento.horario} · ${medicamento.tomado ? 'Tomado' : medicamento.atrasado ? 'Atrasado' : 'Pendente'}'),
            ),
          const Divider(),
          Text('Agenda de hoje', style: Theme.of(context).textTheme.titleSmall),
          for (final consulta in idoso.central.consultas.where((consulta) => consulta.data == hoje))
            Text('${consulta.hora} · ${consulta.nome} (${consulta.local})'),
          const SizedBox(height: 12),
          Text('Histórico de alertas', style: Theme.of(context).textTheme.titleSmall),
          for (final alerta in idoso.alertas)
            Text('${alerta.quando} · ${alerta.tipo.titulo} · ${alerta.resolvido ? 'Resolvido' : 'Em aberto'}'),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../models/perfil_cuidador.dart';
import '../state/sessao.dart';
import '../theme/app_theme.dart';

/// Preferências de notificação do cuidador (salvas no perfil, na conta dele).
class NotificacoesScreen extends StatefulWidget {
  const NotificacoesScreen({super.key});

  @override
  State<NotificacoesScreen> createState() => _NotificacoesScreenState();
}

class _NotificacoesScreenState extends State<NotificacoesScreen> {
  bool _salvando = false;

  Future<void> _alterar(PreferenciasNotificacao novas) async {
    if (_salvando) return;
    final sessao = SessaoScope.leitura(context);
    setState(() => _salvando = true);
    try {
      await sessao.atualizarNotificacoes(novas);
    } catch (_) {
      if (mounted) Mensagens.erro(context, 'Não foi possível salvar suas preferências. Tente novamente.');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefs = SessaoScope.of(context).perfil?.notificacoes ?? const PreferenciasNotificacao();
    return Scaffold(
      backgroundColor: AppColors.fundo,
      appBar: AppBar(title: const Text('Notificações')),
      body: ListView(padding: const EdgeInsets.fromLTRB(18, 16, 18, 24), children: [
        const Text('Escolha quais avisos você quer receber.', style: TextStyle(fontSize: 14, color: AppColors.textoSuave)),
        const SizedBox(height: 14),
        Cartao(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Column(children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: prefs.ativas,
              title: const Text('Notificações', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              subtitle: const Text('Ativa ou desativa todos os avisos', style: TextStyle(fontSize: 12.5, color: AppColors.textoSuave)),
              onChanged: _salvando ? null : (v) => _alterar(prefs.copiarCom(ativas: v)),
            ),
            const Divider(height: 1),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: prefs.lembretesMedicamentos,
              title: const Text('Lembretes de medicamentos', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
              subtitle: const Text('Aviso no horário de cada dose', style: TextStyle(fontSize: 12.5, color: AppColors.textoSuave)),
              onChanged: (_salvando || !prefs.ativas) ? null : (v) => _alterar(prefs.copiarCom(lembretesMedicamentos: v)),
            ),
            const Divider(height: 1),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: prefs.alertasCriticos,
              title: const Text('Alertas críticos', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
              subtitle: const Text('Quedas, pânico e longos períodos sem movimento', style: TextStyle(fontSize: 12.5, color: AppColors.textoSuave)),
              onChanged: (_salvando || !prefs.ativas) ? null : (v) => _alterar(prefs.copiarCom(alertasCriticos: v)),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        const AvisoNota(
          'As preferências ficam salvas na sua conta. Nesta versão os avisos aparecem dentro do aplicativo; '
          'notificações no sistema (push) em segundo plano ainda não estão disponíveis.',
        ),
      ]),
    );
  }
}

class AvisoNota extends StatelessWidget {
  const AvisoNota(this.texto, {super.key});
  final String texto;

  @override
  Widget build(BuildContext context) => Text(texto,
      textAlign: TextAlign.center, style: const TextStyle(fontSize: 12.5, color: AppColors.textoSuave, height: 1.4));
}

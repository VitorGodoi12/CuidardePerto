import 'package:flutter/material.dart';

import '../models/alerta.dart';
import '../theme/app_theme.dart';
import 'risco_badge.dart';

IconData iconeDoAlerta(TipoAlerta tipo) {
  switch (tipo) {
    case TipoAlerta.queda:
      return Icons.personal_injury;
    case TipoAlerta.panico:
      return Icons.notifications_active;
    case TipoAlerta.semMovimento:
      return Icons.directions_walk;
    case TipoAlerta.remedio:
      return Icons.medication;
  }
}

class AlertaCard extends StatelessWidget {
  const AlertaCard({
    super.key,
    required this.alerta,
    required this.primeiro,
    required this.ultimo,
    this.onResolver,
  });

  final Alerta alerta;
  final bool primeiro;
  final bool ultimo;

  final VoidCallback? onResolver;

  @override
  Widget build(BuildContext context) {
    final nivel = alerta.nivel;
    const linha = Color(0xFFB8CBC7);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 48,
            child: Column(
              children: [
                Container(width: 2, height: 12, color: primeiro ? Colors.transparent : linha),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: nivel.fundo,
                    border: Border.all(color: nivel.cor, width: 2),
                  ),
                  child: Icon(iconeDoAlerta(alerta.tipo), size: 22, color: nivel.corTexto),
                ),
                Expanded(child: Container(width: 2, color: ultimo ? Colors.transparent : linha)),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Cartao(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(alerta.tipo.titulo, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.schedule, size: 18, color: AppColors.textoSuave),
                        const SizedBox(width: 6),
                        Text(alerta.quando, style: const TextStyle(fontSize: 15, color: AppColors.textoSuave)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(alerta.descricao, style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        RiscoBadge(nivel: nivel),
                        alerta.resolvido
                            ? const SeloStatus(
                                texto: 'Resolvido',
                                icone: Icons.check_circle,
                                corTexto: Color(0xFF166534),
                                fundo: Color(0xFFDCFCE7),
                                corBorda: AppColors.riscoBaixo,
                              )
                            : const SeloStatus(
                                texto: 'Aberto',
                                icone: Icons.notifications_active,
                                corTexto: AppColors.laranjaTexto,
                                fundo: AppColors.laranjaSuave,
                                corBorda: AppColors.laranja,
                              ),
                      ],
                    ),
                    if (onResolver != null) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: onResolver,
                        icon: const Icon(Icons.check),
                        label: const Text('Resolver alerta'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

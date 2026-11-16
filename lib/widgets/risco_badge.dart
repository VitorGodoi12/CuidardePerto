import 'package:flutter/material.dart';

import '../models/alerta.dart';
import '../theme/app_theme.dart';

extension NivelRiscoVisual on NivelRisco {
  Color get cor {
    switch (this) {
      case NivelRisco.baixo:
        return AppColors.riscoBaixo;
      case NivelRisco.medio:
        return AppColors.riscoMedio;
      case NivelRisco.alto:
        return AppColors.riscoAlto;
      case NivelRisco.critico:
        return AppColors.riscoCritico;
    }
  }

  Color get corTexto {
    switch (this) {
      case NivelRisco.baixo:
        return const Color(0xFF166534);
      case NivelRisco.medio:
        return const Color(0xFF854D0E);
      case NivelRisco.alto:
        return const Color(0xFF9A3412);
      case NivelRisco.critico:
        return const Color(0xFF991B1B);
    }
  }

  Color get fundo {
    switch (this) {
      case NivelRisco.baixo:
        return const Color(0xFFDCFCE7);
      case NivelRisco.medio:
        return const Color(0xFFFEF9C3);
      case NivelRisco.alto:
        return const Color(0xFFFFEDD5);
      case NivelRisco.critico:
        return const Color(0xFFFEE2E2);
    }
  }

  IconData get icone {
    switch (this) {
      case NivelRisco.baixo:
        return Icons.check_circle;
      case NivelRisco.medio:
        return Icons.info;
      case NivelRisco.alto:
        return Icons.warning_amber_rounded;
      case NivelRisco.critico:
        return Icons.error;
    }
  }
}

class RiscoBadge extends StatelessWidget {
  const RiscoBadge({super.key, required this.nivel});

  final NivelRisco nivel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: nivel.rotulo,
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: nivel.fundo,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: nivel.cor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(nivel.icone, size: 18, color: nivel.corTexto),
            const SizedBox(width: 6),
            Text(
              nivel.rotulo,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: nivel.corTexto),
            ),
          ],
        ),
      ),
    );
  }
}

class SeloStatus extends StatelessWidget {
  const SeloStatus({
    super.key,
    required this.texto,
    required this.icone,
    required this.corTexto,
    required this.fundo,
    required this.corBorda,
  });

  final String texto;
  final IconData icone;
  final Color corTexto;
  final Color fundo;
  final Color corBorda;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: corBorda),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 16, color: corTexto),
          const SizedBox(width: 4),
          Text(texto, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: corTexto)),
        ],
      ),
    );
  }
}

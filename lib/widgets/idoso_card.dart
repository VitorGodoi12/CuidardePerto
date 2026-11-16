import 'package:flutter/material.dart';

import '../models/alerta.dart';
import '../models/idoso.dart';
import '../theme/app_theme.dart';
import 'risco_badge.dart';

/// Avatar circular da pessoa acompanhada.
class AvatarIdoso extends StatelessWidget {
  const AvatarIdoso({super.key, required this.caminho, this.tamanho = 56});

  final String caminho;
  final double tamanho;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamanho,
      height: tamanho,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.verdeSuave,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [BoxShadow(color: Color(0x22006F73), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: ClipOval(
        child: Image.asset(
          caminho,
          width: tamanho,
          height: tamanho,
          fit: BoxFit.cover,
          excludeFromSemantics: true,
          errorBuilder: (context, erro, pilha) => Icon(Icons.elderly, size: tamanho * 0.6, color: AppColors.primaria),
        ),
      ),
    );
  }
}

/// Selo "● Cuidados ativos" (ou o nível de risco quando há atenção necessária).
class SeloCuidado extends StatelessWidget {
  const SeloCuidado({super.key, required this.idoso});
  final Idoso idoso;

  @override
  Widget build(BuildContext context) {
    if (idoso.risco != NivelRisco.baixo) return RiscoBadge(nivel: idoso.risco);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: AppColors.verdeSuave, borderRadius: BorderRadius.circular(20)),
      child: const Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.circle, size: 8, color: AppColors.riscoBaixo),
        SizedBox(width: 5),
        Text('Cuidados ativos', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.sucessoEscuro)),
      ]),
    );
  }
}

/// Cartão da lista "Meus Idosos".
class IdosoCard extends StatelessWidget {
  const IdosoCard({super.key, required this.idoso, required this.onTap});

  final Idoso idoso;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      onTap: onTap,
      label: '${idoso.nome}, ${idoso.idade} anos. ${idoso.risco.rotulo}. Último movimento ${idoso.ultimoMovimento}. ${idoso.resumoMedicamentos}.',
      excludeSemantics: true,
      child: Material(
        color: Colors.white,
        elevation: 1.5,
        shadowColor: const Color(0x1A0B5C59),
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              AvatarIdoso(caminho: idoso.avatar, tamanho: 70),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(idoso.nome, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.texto)),
                  const SizedBox(height: 1),
                  Text('${idoso.idade} anos', style: const TextStyle(fontSize: 14, color: AppColors.textoSuave)),
                  const SizedBox(height: 7),
                  SeloCuidado(idoso: idoso),
                ]),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.texto, size: 30),
            ]),
          ),
        ),
      ),
    );
  }
}

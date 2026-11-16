import 'package:flutter/material.dart';

import '../models/idoso.dart';
import '../theme/app_theme.dart';
import 'idoso_card.dart';

/// Cartão "Seu José · 78 anos ⌄" que permite trocar a pessoa acompanhada.
class SeletorPessoa extends StatelessWidget {
  const SeletorPessoa({super.key, required this.atual, required this.pessoas, required this.aoEscolher});

  final Idoso atual;
  final List<Idoso> pessoas;
  final ValueChanged<Idoso> aoEscolher;

  Future<void> _abrir(BuildContext context) async {
    final escolhido = await showModalBottomSheet<Idoso>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (ctx) => SafeArea(
        child: ListView(shrinkWrap: true, padding: const EdgeInsets.fromLTRB(18, 4, 18, 18), children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text('Escolha uma pessoa', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.texto)),
          ),
          for (final p in pessoas)
            ListTile(
              leading: AvatarIdoso(caminho: p.avatar, tamanho: 46),
              title: Text(p.nome, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('${p.idade} anos'),
              trailing: p.id == atual.id ? const Icon(Icons.check_circle_rounded, color: AppColors.primaria) : null,
              onTap: () => Navigator.pop(ctx, p),
            ),
        ]),
      ),
    );
    if (escolhido != null) aoEscolher(escolhido);
  }

  @override
  Widget build(BuildContext context) {
    final podeTrocar = pessoas.length > 1;
    return Semantics(
      button: podeTrocar,
      label: 'Pessoa acompanhada: ${atual.nome}, ${atual.idade} anos${podeTrocar ? '. Toque para trocar' : ''}',
      excludeSemantics: true,
      child: Material(
        color: Colors.white,
        elevation: 1,
        shadowColor: const Color(0x160B5C59),
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: podeTrocar ? () => _abrir(context) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(children: [
              AvatarIdoso(caminho: atual.avatar, tamanho: 52),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(atual.nome, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.texto)),
                  Text('${atual.idade} anos', style: const TextStyle(fontSize: 13, color: AppColors.textoSuave)),
                ]),
              ),
              if (podeTrocar) const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.texto, size: 28),
            ]),
          ),
        ),
      ),
    );
  }
}

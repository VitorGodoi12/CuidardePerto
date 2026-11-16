import 'package:flutter/material.dart';

import '../data/dados_cuidador.dart';

import '../models/contato.dart';
import '../models/idoso.dart';
import '../theme/app_theme.dart';

class ContatosScreen extends StatefulWidget {
  const ContatosScreen({super.key, required this.idoso});

  final Idoso idoso;

  @override
  State<ContatosScreen> createState() => _ContatosScreenState();
}

class _ContatosScreenState extends State<ContatosScreen> {
  Idoso get idoso => widget.idoso;

  void _definirPrincipal(Contato escolhido) {
    setState(() {
      for (final contato in idoso.contatos) {
        contato.principal = identical(contato, escolhido);
      }
    });
    DadosCuidador.salvar(idoso);
    Mensagens.info(context, '${escolhido.nome} agora é o contato principal');
  }

  Future<void> _ligar(String nome, String telefone) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (contextoDialogo) => AlertDialog(
        title: Text('Ligar para $nome? (simulação)'),
        content: Text('$telefone\n\nNenhuma ligação real será feita: é apenas uma demonstração.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contextoDialogo, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(contextoDialogo, true),
            icon: const Icon(Icons.phone),
            label: const Text('Ligar'),
          ),
        ],
      ),
    );
    if (confirmou == true && mounted) {
      Mensagens.info(context, 'Ligação simulada para $nome');
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    final principal = idoso.contatoPrincipal;
    final outros = idoso.contatos.where((c) => !identical(c, principal)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Contatos'), centerTitle: false, titleSpacing: 20, actions: [Padding(padding: const EdgeInsets.only(right: 16), child: CircleAvatar(radius: 18, backgroundColor: AppColors.verdeSuave, child: Icon(Icons.support_agent_rounded, color: AppColors.primaria))) ]),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        children: [
          Text('Contatos de ${idoso.nome}', style: tema.titleMedium),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 19),
            decoration: BoxDecoration(color: AppColors.primaria, borderRadius: BorderRadius.circular(22)),
            child: const Row(children: [
              Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Expanded(child: Text('Em caso de emergência, veja quem pode ajudar.',
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700))),
            ]),
          ),
          const SizedBox(height: Espaco.m),
          if (principal != null) ...[
            _CartaoPrincipal(contato: principal, onLigar: () => _ligar(principal.nome, principal.telefone)),
            const SizedBox(height: Espaco.m),
          ],
          if (outros.isNotEmpty) ...[
            Text('Outros contatos', style: tema.titleMedium),
            const SizedBox(height: Espaco.p),
            for (final contato in outros)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _CartaoContato(
                  contato: contato,
                  onLigar: () => _ligar(contato.nome, contato.telefone),
                  onDefinirPrincipal: () => _definirPrincipal(contato),
                ),
              ),
          ],
          const SizedBox(height: Espaco.p),
          Text('Serviço de emergência', style: tema.titleMedium),
          const SizedBox(height: Espaco.p),
          _CartaoSamu(onLigar: () => _ligar('o SAMU (192)', '192')),
        ],
      ),
    );
  }
}

class _AvatarContato extends StatelessWidget {
  const _AvatarContato({required this.contato, required this.tamanho});

  final Contato contato;
  final double tamanho;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamanho,
      height: tamanho,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.verdeSuave,
        border: Border.all(color: AppColors.primaria.withValues(alpha: .12), width: 3),
      ),
      child: ClipOval(
        child: contato.nome.toLowerCase() == 'ana'
            ? Image.asset('assets/images/avatar_ana_mockup.png', fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(child: Text(contato.iniciais,
                  style: TextStyle(fontSize: tamanho * 0.36, fontWeight: FontWeight.w800, color: AppColors.primariaEscura))))
            : Center(child: Text(contato.iniciais,
                style: TextStyle(fontSize: tamanho * 0.36, fontWeight: FontWeight.w800, color: AppColors.primariaEscura))),
      ),
    );
  }
}

class _CartaoPrincipal extends StatelessWidget {
  const _CartaoPrincipal({required this.contato, required this.onLigar});

  final Contato contato;
  final VoidCallback onLigar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    return Cartao(
      corFundo: AppColors.verdeSuave,
      corBorda: AppColors.borda,
      larguraBorda: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.star, color: AppColors.laranjaTexto),
              SizedBox(width: 6),
              Text(
                'Contato principal',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.laranjaTexto),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _AvatarContato(contato: contato, tamanho: 64),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(contato.nome, style: tema.headlineSmall),
                    Text(contato.parentesco, style: tema.bodyLarge),
                    const SizedBox(height: 4),
                    Text(
                      contato.telefone,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primariaEscura),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onLigar,
            icon: const Icon(Icons.phone),
            label: Text('Ligar para ${contato.nome} (simulação)'),
          ),
        ],
      ),
    );
  }
}

class _CartaoContato extends StatelessWidget {
  const _CartaoContato({
    required this.contato,
    required this.onLigar,
    required this.onDefinirPrincipal,
  });

  final Contato contato;
  final VoidCallback onLigar;
  final VoidCallback onDefinirPrincipal;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    return Cartao(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _AvatarContato(contato: contato, tamanho: 52),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(contato.nome, style: tema.titleMedium),
                    Text(contato.parentesco, style: tema.bodyMedium),
                    Text(contato.telefone, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Definir ${contato.nome} como contato principal',
                iconSize: 30,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                icon: const Icon(Icons.star_border, color: AppColors.laranjaTexto),
                onPressed: onDefinirPrincipal,
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onLigar,
            icon: const Icon(Icons.phone),
            label: Text('Ligar para ${contato.nome}'),
          ),
        ],
      ),
    );
  }
}

class _CartaoSamu extends StatelessWidget {
  const _CartaoSamu({required this.onLigar});

  final VoidCallback onLigar;

  @override
  Widget build(BuildContext context) {
    return Cartao(
      corFundo: const Color(0xFFFEE2E2),
      corBorda: AppColors.riscoCritico,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.local_hospital, size: 44, color: Color(0xFF991B1B)),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SAMU 192',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF991B1B)),
                    ),
                    Text(
                      'Serviço de Atendimento Móvel de Urgência',
                      style: TextStyle(fontSize: 15, color: AppColors.texto),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onLigar,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.erroEscuro),
            icon: const Icon(Icons.phone),
            label: const Text('Ligar para o SAMU (simulação)'),
          ),
        ],
      ),
    );
  }
}

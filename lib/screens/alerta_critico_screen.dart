import 'package:flutter/material.dart';

import '../data/dados_cuidador.dart';

import '../models/alerta.dart';
import '../models/idoso.dart';
import '../theme/app_theme.dart';
import '../widgets/idoso_card.dart';
import '../widgets/risco_badge.dart';
import 'contatos_screen.dart';

class AlertaCriticoScreen extends StatefulWidget {
  const AlertaCriticoScreen({super.key, required this.alerta});

  final Alerta alerta;

  @override
  State<AlertaCriticoScreen> createState() => _AlertaCriticoScreenState();
}

class _AlertaCriticoScreenState extends State<AlertaCriticoScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _pulso;

  Alerta get alerta => widget.alerta;
  Idoso get idoso => widget.alerta.idoso;

  @override
  void initState() {
    super.initState();
    _pulso = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulso.dispose();
    super.dispose();
  }

  String get _titulo =>
      alerta.tipo == TipoAlerta.panico ? 'BOTÃO DE PÂNICO ACIONADO' : 'QUEDA DETECTADA';

  void _ligar() {
    final contato = idoso.contatoPrincipal;
    final nome = contato?.nome ?? 'o contato principal';
    Mensagens.info(context, 'Ligação simulada para $nome. Nenhuma chamada real foi feita.');
  }

  Future<void> _verContatos() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ContatosScreen(idoso: idoso)),
    );
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _resolver() async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (contextoDialogo) => AlertDialog(
        title: const Text('Marcar como resolvido?'),
        content: Text('Confirme apenas se ${idoso.nome} já está em segurança.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contextoDialogo, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(contextoDialogo, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmou != true || !mounted) return;
    setState(() => alerta.resolvido = true);
    DadosCuidador.salvar(alerta.idoso);

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    final reduzirMovimento = MediaQuery.of(context).disableAnimations;
    const iconeAlerta = Icon(Icons.warning_amber_rounded, size: 76, color: Colors.white);
    final nomeContato = idoso.contatoPrincipal?.nome ?? 'contato';

    return Scaffold(
      body: SafeArea(
        top: true,
        child: ListView(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.riscoCritico,
            padding: const EdgeInsets.fromLTRB(Espaco.m, Espaco.p, Espaco.m, Espaco.g),
            child: Column(
              children: [
                reduzirMovimento
                    ? iconeAlerta
                    : ScaleTransition(
                        scale: Tween<double>(begin: 1, end: 1.12).animate(
                          CurvedAnimation(parent: _pulso, curve: Curves.easeInOut),
                        ),
                        child: iconeAlerta,
                      ),
                const SizedBox(height: Espaco.p),
                Semantics(
                  header: true,
                  child: Text(
                    _titulo,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Situação de emergência. Aja agora.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 17, color: Colors.white),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Espaco.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Cartao(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          AvatarIdoso(caminho: idoso.avatar, tamanho: 68),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(idoso.nome, style: tema.headlineSmall),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.schedule, size: 20, color: AppColors.textoSuave),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(alerta.quando, style: tema.bodyLarge),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.place, color: AppColors.primaria),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text('${idoso.endereco} (endereço demonstrativo)', style: tema.bodyLarge),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline, color: AppColors.primaria),
                          const SizedBox(width: 8),
                          Expanded(child: Text(alerta.descricao, style: tema.bodyLarge)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.directions_walk, color: AppColors.primaria),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text('Último movimento: ${idoso.ultimoMovimento}', style: tema.bodyLarge),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      RiscoBadge(nivel: alerta.nivel),
                    ],
                  ),
                ),
                const SizedBox(height: Espaco.m),
                Cartao(
                  corFundo: AppColors.verdeSuave,
                  corBorda: AppColors.primaria,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('O que fazer', style: tema.titleMedium),
                      const SizedBox(height: 8),
                      Text(
                        'Ligue para ${idoso.nome}. Sem resposta, ligue para o SAMU (192).',
                        style: tema.bodyLarge,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Espaco.g),
                ElevatedButton.icon(
                  onPressed: _ligar,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.erroEscuro),
                  icon: const Icon(Icons.phone),
                  label: Text('Ligar para $nomeContato (simulação)'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _verContatos,
                  icon: const Icon(Icons.contact_phone),
                  label: const Text('Ver contatos'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _resolver,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Marcar como resolvido'),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}

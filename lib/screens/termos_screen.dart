import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum TipoDocumento { termos, privacidade }

/// Termos de Uso e Política de Privacidade exibidos no cadastro.
/// Texto-base: deve ser revisado por um responsável jurídico antes da publicação.
class TermosScreen extends StatelessWidget {
  const TermosScreen({super.key, required this.tipo});
  final TipoDocumento tipo;

  static const _termos = <(String, String)>[
    ('1. Sobre o aplicativo', 'O Cuidar de Perto ajuda familiares e cuidadores a organizar o acompanhamento de pessoas idosas: cadastro de medicamentos, agenda, contatos e registros de cuidado.'),
    ('2. Sua conta', 'A conta é demonstrativa e existe somente durante a execução atual do aplicativo. Não use uma senha real.'),
    ('3. Uso adequado', 'O aplicativo não substitui orientação médica, monitoramento profissional ou serviços de emergência. Em situações graves, acione o SAMU (192) ou outro serviço público adequado.'),
    ('4. Responsabilidades', 'Mantenha os dados das pessoas acompanhadas atualizados e use o aplicativo somente com autorização delas ou de seus responsáveis legais.'),
    ('5. Alterações', 'Estes termos podem ser atualizados. Mudanças relevantes serão comunicadas no aplicativo.'),
  ];

  static const _privacidade = <(String, String)>[
    ('1. Dados informados', 'Nome, e-mail, telefone (opcional) e informações demonstrativas que você cadastra sobre as pessoas acompanhadas.'),
    ('2. Como usamos', 'Os dados são usados somente para demonstrar as telas e funcionalidades no aparelho durante a execução atual.'),
    ('3. Armazenamento', 'Os dados ficam apenas na memória do aplicativo e são apagados ao encerrá-lo. Não há servidor, sincronização nem autenticação real. Não informe dados pessoais reais.'),
    ('4. Compartilhamento', 'Esta versão não envia os dados para terceiros.'),
    ('5. Seus direitos', 'Você pode solicitar acesso, correção ou exclusão dos seus dados, conforme a Lei Geral de Proteção de Dados (LGPD).'),
  ];

  @override
  Widget build(BuildContext context) {
    final ehTermos = tipo == TipoDocumento.termos;
    final secoes = ehTermos ? _termos : _privacidade;
    return Scaffold(
      backgroundColor: AppColors.fundo,
      appBar: AppBar(title: Text(ehTermos ? 'Termos de Uso' : 'Política de Privacidade')),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 28), children: [
        for (final (titulo, texto) in secoes) ...[
          Text(titulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.texto)),
          const SizedBox(height: 6),
          Text(texto, style: const TextStyle(fontSize: 14.5, height: 1.5, color: AppColors.texto)),
          const SizedBox(height: 18),
        ],
        const Text('Última atualização: novembro de 2026.', style: TextStyle(fontSize: 12, color: AppColors.textoSuave)),
      ]),
    );
  }
}

class Contato {
  Contato({
    required this.nome,
    required this.parentesco,
    required this.telefone,
    this.principal = false,
  });

  final String nome;
  final String parentesco;
  final String telefone;

  bool principal;

  String get iniciais {
    final partes = nome.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (partes.isEmpty) return '?';
    if (partes.length == 1) return partes.first[0].toUpperCase();
    return (partes.first[0] + partes[1][0]).toUpperCase();
  }

  Map<String, dynamic> toMap() => {
        'nome': nome,
        'parentesco': parentesco,
        'telefone': telefone,
        'principal': principal,
      };

  factory Contato.fromMap(Map<String, dynamic> m) => Contato(
        nome: (m['nome'] ?? '') as String,
        parentesco: (m['parentesco'] ?? '') as String,
        telefone: (m['telefone'] ?? '') as String,
        principal: (m['principal'] ?? false) as bool,
      );
}

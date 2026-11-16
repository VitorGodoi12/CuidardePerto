import 'idoso.dart';

enum NivelRisco { baixo, medio, alto, critico }

extension NivelRiscoTexto on NivelRisco {

  String get nome {
    switch (this) {
      case NivelRisco.baixo:
        return 'Baixo';
      case NivelRisco.medio:
        return 'Médio';
      case NivelRisco.alto:
        return 'Alto';
      case NivelRisco.critico:
        return 'Crítico';
    }
  }

  String get rotulo => 'Risco ${nome.toLowerCase()}';
}

enum TipoAlerta { queda, panico, semMovimento, remedio }

extension TipoAlertaTexto on TipoAlerta {
  String get titulo {
    switch (this) {
      case TipoAlerta.queda:
        return 'Queda detectada';
      case TipoAlerta.panico:
        return 'Botão de pânico';
      case TipoAlerta.semMovimento:
        return 'Sem movimento';
      case TipoAlerta.remedio:
        return 'Remédio atrasado';
    }
  }

  bool get critico => this == TipoAlerta.queda || this == TipoAlerta.panico;
}

class Alerta {
  Alerta({
    required this.id,
    required this.idoso,
    required this.tipo,
    required this.nivel,
    required this.descricao,
    required this.dataHora,
    this.resolvido = false,
  });

  final int id;
  final Idoso idoso;
  final TipoAlerta tipo;
  final NivelRisco nivel;
  final String descricao;
  final DateTime dataHora;
  bool resolvido;

  Map<String, dynamic> toMap() => {
        'id': id,
        'tipo': tipo.name,
        'nivel': nivel.name,
        'descricao': descricao,
        'dataHora': dataHora.millisecondsSinceEpoch,
        'resolvido': resolvido,
      };

  factory Alerta.fromMap(Map<String, dynamic> m, Idoso idoso) => Alerta(
        id: (m['id'] as num).toInt(),
        idoso: idoso,
        tipo: TipoAlerta.values.firstWhere((t) => t.name == m['tipo'], orElse: () => TipoAlerta.semMovimento),
        nivel: NivelRisco.values.firstWhere((n) => n.name == m['nivel'], orElse: () => NivelRisco.medio),
        descricao: (m['descricao'] ?? '') as String,
        dataHora: DateTime.fromMillisecondsSinceEpoch((m['dataHora'] as num).toInt()),
        resolvido: (m['resolvido'] ?? false) as bool,
      );

  String get quando {
    final agora = DateTime.now();
    final hoje = DateTime.utc(agora.year, agora.month, agora.day);
    final dia = DateTime.utc(dataHora.year, dataHora.month, dataHora.day);
    final diferenca = hoje.difference(dia).inDays;
    String doisDigitos(int n) => n.toString().padLeft(2, '0');
    final hora = '${doisDigitos(dataHora.hour)}:${doisDigitos(dataHora.minute)}';
    if (diferenca == 0) return 'Hoje $hora';
    if (diferenca == 1) return 'Ontem $hora';
    if (diferenca == 2) return 'Anteontem $hora';
    return '${doisDigitos(dataHora.day)}/${doisDigitos(dataHora.month)} $hora';
  }
}

import '../data/dados_cuidador.dart';

class Medicamento {
  Medicamento({
    required this.nome,
    required this.dose,
    required this.horario,
    this.tomado = false,
    this.observacao = '',
  });

  final String nome;
  final String dose;

  /// Horário no formato HH:mm.
  final String horario;
  bool tomado;
  final String observacao;

  int get minutos {
    final partes = horario.split(':');
    return int.parse(partes[0]) * 60 + int.parse(partes[1]);
  }

  /// Dose não tomada cujo horário já passou (relógio real do aparelho).
  bool get atrasado => !tomado && minutos < DadosCuidador.minutosAgora;

  Map<String, dynamic> toMap() => {
        'nome': nome,
        'dose': dose,
        'horario': horario,
        'tomado': tomado,
        'observacao': observacao,
      };

  factory Medicamento.fromMap(Map<String, dynamic> m) => Medicamento(
        nome: (m['nome'] ?? '') as String,
        dose: (m['dose'] ?? '') as String,
        horario: (m['horario'] ?? '00:00') as String,
        tomado: (m['tomado'] ?? false) as bool,
        observacao: (m['observacao'] ?? '') as String,
      );
}

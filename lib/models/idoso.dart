import 'alerta.dart';
import 'central_cuidado.dart';
import 'contato.dart';
import 'medicamento.dart';

class Idoso {
  Idoso({
    required this.id,
    required this.nome,
    required this.idade,
    required this.condicoes,
    required this.endereco,
    required this.horasSemMovimento,
    required this.dispositivoOnline,
    required this.avatar,
    this.telefone = '',
    this.alergias = '',
    this.observacoes = '',
    List<Medicamento>? medicamentos,
    List<Alerta>? alertas,
    List<Contato>? contatos,
    CentralCuidado? central,
  })  : medicamentos = medicamentos ?? <Medicamento>[],
        alertas = alertas ?? <Alerta>[],
        contatos = contatos ?? <Contato>[],
        central = central ?? CentralCuidado();

  final int id;
  String nome;
  int idade;
  List<String> condicoes;
  String endereco;
  String telefone;
  String alergias;
  String observacoes;
  double horasSemMovimento;
  bool dispositivoOnline;

  final String avatar;
  final List<Medicamento> medicamentos;
  final List<Alerta> alertas;
  final List<Contato> contatos;
  final CentralCuidado central;

  int get dosesTomadas => medicamentos.where((m) => m.tomado).length;

  int get dosesAtrasadas => medicamentos.where((m) => m.atrasado).length;

  String get resumoMedicamentos => '$dosesTomadas de ${medicamentos.length} tomados';

  double get progressoDoses => medicamentos.isEmpty ? 0 : dosesTomadas / medicamentos.length;

  int get alertasAbertos => alertas.where((a) => !a.resolvido).length;

  Alerta? get alertaCriticoAberto {
    for (final alerta in alertas) {
      if (alerta.tipo.critico && !alerta.resolvido) return alerta;
    }
    return null;
  }

  bool get temAlertaCriticoAberto => alertaCriticoAberto != null;

  Alerta registrarEvento(TipoAlerta tipo) {
    final alerta = Alerta(
      id: DateTime.now().millisecondsSinceEpoch,
      idoso: this,
      tipo: tipo,
      nivel: NivelRisco.critico,
      descricao: tipo == TipoAlerta.queda
          ? 'Possível queda detectada pelo sensor. Evento simulado para demonstração.'
          : 'O botão de pânico foi pressionado. Evento simulado para demonstração.',
      dataHora: DateTime.now(),
    );
    alertas.insert(0, alerta);
    return alerta;
  }

  String get ultimoMovimento {
    final minutos = (horasSemMovimento * 60).round();
    if (minutos < 60) return 'há $minutos min';
    return 'há ${horasSemMovimento.floor()} h';
  }

  Contato? get contatoPrincipal {
    for (final contato in contatos) {
      if (contato.principal) return contato;
    }
    return contatos.isEmpty ? null : contatos.first;
  }

  NivelRisco get risco {
    if (temAlertaCriticoAberto) return NivelRisco.critico;
    if (horasSemMovimento >= 6 || dosesAtrasadas >= 2) return NivelRisco.alto;
    if (horasSemMovimento >= 3 || dosesAtrasadas == 1) return NivelRisco.medio;
    return NivelRisco.baixo;
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'nome': nome,
        'idade': idade,
        'condicoes': condicoes,
        'endereco': endereco,
        'telefone': telefone,
        'alergias': alergias,
        'observacoes': observacoes,
        'horasSemMovimento': horasSemMovimento,
        'dispositivoOnline': dispositivoOnline,
        'avatar': avatar,
        'medicamentos': medicamentos.map((m) => m.toMap()).toList(),
        'contatos': contatos.map((c) => c.toMap()).toList(),
        'alertas': alertas.map((a) => a.toMap()).toList(),
        'central': central.toMap(),
      };

  factory Idoso.fromMap(Map<String, dynamic> m) {
    List<Map<String, dynamic>> lista(dynamic v) =>
        (v as List<dynamic>? ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();

    final idoso = Idoso(
      id: (m['id'] as num).toInt(),
      nome: (m['nome'] ?? '') as String,
      idade: (m['idade'] as num? ?? 0).toInt(),
      condicoes: (m['condicoes'] as List<dynamic>? ?? const []).cast<String>().toList(),
      endereco: (m['endereco'] ?? '') as String,
      telefone: (m['telefone'] ?? '') as String,
      alergias: (m['alergias'] ?? '') as String,
      observacoes: (m['observacoes'] ?? '') as String,
      horasSemMovimento: (m['horasSemMovimento'] as num? ?? 0).toDouble(),
      dispositivoOnline: (m['dispositivoOnline'] ?? false) as bool,
      avatar: (m['avatar'] ?? 'assets/images/avatar.png') as String,
      medicamentos: lista(m['medicamentos']).map(Medicamento.fromMap).toList(),
      contatos: lista(m['contatos']).map(Contato.fromMap).toList(),
      central: CentralCuidado.fromMap(m['central'] == null ? null : Map<String, dynamic>.from(m['central'] as Map)),
    );
    idoso.alertas.addAll(lista(m['alertas']).map((a) => Alerta.fromMap(a, idoso)));
    return idoso;
  }
}

/// Registros da Agenda / Central de cuidado de uma pessoa acompanhada.
/// Fica dentro do documento do idoso, portanto pertence ao cuidador dono da conta.
class Consulta {
  Consulta(this.nome, this.data, this.hora, this.local);

  final String nome;

  /// Data no formato dd/MM/aaaa.
  final String data;

  /// Hora no formato HH:mm (pode ser vazia).
  final String hora;
  final String local;

  Map<String, dynamic> toMap() => {'nome': nome, 'data': data, 'hora': hora, 'local': local};

  factory Consulta.fromMap(Map<String, dynamic> m) => Consulta(
        (m['nome'] ?? '') as String,
        (m['data'] ?? '') as String,
        (m['hora'] ?? '') as String,
        (m['local'] ?? '') as String,
      );

  /// Converte a data textual em [DateTime]; devolve null se estiver inválida.
  DateTime? get dia {
    final partes = data.trim().split(RegExp(r'\s+')).first.split('/');
    if (partes.length != 3) return null;
    final d = int.tryParse(partes[0]);
    final m = int.tryParse(partes[1]);
    final a = int.tryParse(partes[2]);
    if (d == null || m == null || a == null) return null;
    return DateTime(a, m, d);
  }

  static String formatarData(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class Registro {
  Registro(this.texto, this.hora);
  final String texto;
  final String hora;

  Map<String, dynamic> toMap() => {'texto': texto, 'hora': hora};
  factory Registro.fromMap(Map<String, dynamic> m) =>
      Registro((m['texto'] ?? '') as String, (m['hora'] ?? '') as String);
}

class MembroEquipe {
  MembroEquipe(this.nome, this.papel);
  final String nome;
  final String papel;

  Map<String, dynamic> toMap() => {'nome': nome, 'papel': papel};
  factory MembroEquipe.fromMap(Map<String, dynamic> m) =>
      MembroEquipe((m['nome'] ?? '') as String, (m['papel'] ?? '') as String);
}

class CentralCuidado {
  CentralCuidado();

  final List<Consulta> consultas = [];
  final List<Registro> diario = [];
  final List<Registro> recados = [];
  final List<MembroEquipe> equipe = [];
  final Set<String> rotina = {};
  final List<String> historico = [];
  int agua = 0;
  String humor = '';
  bool checkin = false;

  Map<String, dynamic> toMap() => {
        'consultas': consultas.map((e) => e.toMap()).toList(),
        'diario': diario.map((e) => e.toMap()).toList(),
        'recados': recados.map((e) => e.toMap()).toList(),
        'equipe': equipe.map((e) => e.toMap()).toList(),
        'rotina': rotina.toList(),
        'historico': historico,
        'agua': agua,
        'humor': humor,
        'checkin': checkin,
      };

  static List<Map<String, dynamic>> _lista(dynamic v) =>
      (v as List<dynamic>? ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();

  factory CentralCuidado.fromMap(Map<String, dynamic>? m) {
    final c = CentralCuidado();
    if (m == null) return c;
    c.consultas.addAll(_lista(m['consultas']).map(Consulta.fromMap));
    c.diario.addAll(_lista(m['diario']).map(Registro.fromMap));
    c.recados.addAll(_lista(m['recados']).map(Registro.fromMap));
    c.equipe.addAll(_lista(m['equipe']).map(MembroEquipe.fromMap));
    c.rotina.addAll((m['rotina'] as List<dynamic>? ?? const []).cast<String>());
    c.historico.addAll((m['historico'] as List<dynamic>? ?? const []).cast<String>());
    c.agua = (m['agua'] as num? ?? 0).toInt();
    c.humor = (m['humor'] ?? '') as String;
    c.checkin = (m['checkin'] ?? false) as bool;
    return c;
  }
}

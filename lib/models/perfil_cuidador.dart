/// Preferências de notificação do cuidador.
class PreferenciasNotificacao {
  const PreferenciasNotificacao({
    this.ativas = true,
    this.lembretesMedicamentos = true,
    this.alertasCriticos = true,
  });

  final bool ativas;
  final bool lembretesMedicamentos;
  final bool alertasCriticos;

  PreferenciasNotificacao copiarCom({bool? ativas, bool? lembretesMedicamentos, bool? alertasCriticos}) =>
      PreferenciasNotificacao(
        ativas: ativas ?? this.ativas,
        lembretesMedicamentos: lembretesMedicamentos ?? this.lembretesMedicamentos,
        alertasCriticos: alertasCriticos ?? this.alertasCriticos,
      );

  Map<String, dynamic> toMap() => {
        'ativas': ativas,
        'lembretesMedicamentos': lembretesMedicamentos,
        'alertasCriticos': alertasCriticos,
      };

  factory PreferenciasNotificacao.fromMap(Map<String, dynamic>? m) => PreferenciasNotificacao(
        ativas: (m?['ativas'] ?? true) as bool,
        lembretesMedicamentos: (m?['lembretesMedicamentos'] ?? true) as bool,
        alertasCriticos: (m?['alertasCriticos'] ?? true) as bool,
      );
}

/// Perfil individual do cuidador.
class PerfilCuidador {
  PerfilCuidador({
    required this.uid,
    required this.nomeCompleto,
    required this.email,
    required this.criadoEm,
    this.telefone = '',
    this.fotoUrl,
    this.tipoUsuario = tipoCuidador,
    this.notificacoes = const PreferenciasNotificacao(),
    this.primeiroAcesso = true,
    this.provedores = const [],
  });

  static const String tipoCuidador = 'cuidador';
  static const String tipoFamiliar = 'familiar';

  final String uid;
  final String nomeCompleto;
  final String email;
  final DateTime criadoEm;
  final String telefone;
  final String? fotoUrl;

  /// Definido no cadastro e mantido ao atualizar o perfil.
  final String tipoUsuario;
  bool get familiar => tipoUsuario == tipoFamiliar;
  final PreferenciasNotificacao notificacoes;

  /// true enquanto o cuidador ainda não concluiu a experiência de boas-vindas.
  final bool primeiroAcesso;
  final List<String> provedores;

  String get primeiroNome {
    final partes = nomeCompleto.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    return partes.isEmpty ? 'cuidador' : partes.first;
  }

  PerfilCuidador copiarCom({
    String? nomeCompleto,
    String? telefone,
    String? fotoUrl,
    PreferenciasNotificacao? notificacoes,
    bool? primeiroAcesso,
  }) =>
      PerfilCuidador(
        uid: uid,
        nomeCompleto: nomeCompleto ?? this.nomeCompleto,
        email: email,
        criadoEm: criadoEm,
        telefone: telefone ?? this.telefone,
        fotoUrl: fotoUrl ?? this.fotoUrl,
        tipoUsuario: tipoUsuario,
        notificacoes: notificacoes ?? this.notificacoes,
        primeiroAcesso: primeiroAcesso ?? this.primeiroAcesso,
        provedores: provedores,
      );

  /// Campos do perfil local.
  Map<String, dynamic> toMap() => {
        'uid': uid,
        'nomeCompleto': nomeCompleto,
        'email': email,
        'telefone': telefone,
        'fotoUrl': fotoUrl,
        'tipoUsuario': tipoUsuario,
        'notificacoes': notificacoes.toMap(),
        'primeiroAcesso': primeiroAcesso,
        'provedores': provedores,
      };

  factory PerfilCuidador.fromMap(String uid, Map<String, dynamic> m, DateTime criadoEm) => PerfilCuidador(
        uid: uid,
        nomeCompleto: (m['nomeCompleto'] ?? '') as String,
        email: (m['email'] ?? '') as String,
        criadoEm: criadoEm,
        telefone: (m['telefone'] ?? '') as String,
        fotoUrl: m['fotoUrl'] as String?,
        tipoUsuario: m['tipoUsuario'] == tipoFamiliar ? tipoFamiliar : tipoCuidador,
        notificacoes: PreferenciasNotificacao.fromMap(
            m['notificacoes'] == null ? null : Map<String, dynamic>.from(m['notificacoes'] as Map)),
        primeiroAcesso: (m['primeiroAcesso'] ?? true) as bool,
        provedores: (m['provedores'] as List<dynamic>? ?? const []).cast<String>(),
      );
}


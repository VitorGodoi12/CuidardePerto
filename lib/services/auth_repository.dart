/// Contrato de autenticação local do protótipo.

/// Credenciais públicas de demonstração, sem vínculo com uma pessoa real.
class CredenciaisDemo {
  CredenciaisDemo._();

  static const uid = 'cuidador-demo';
  static const email = 'demo@cuidardeperto.com';
  static const senha = 'CuidaDemo2026!';
  static const nome = 'Cuidador Demonstração';
}

class UsuarioAuth {
  const UsuarioAuth({
    required this.uid,
    required this.email,
    this.nome,
    this.fotoUrl,
    this.emailVerificado = false,
    this.provedores = const [],
  });

  final String uid;
  final String email;
  final String? nome;
  final String? fotoUrl;
  final bool emailVerificado;

  /// Tipo de acesso local da conta.
  final List<String> provedores;

  bool get usaSenha => provedores.contains('password');

  /// Só contas com e-mail e senha precisam confirmar o endereço.
  bool get exigeVerificacao => usaSenha && !emailVerificado;
}

enum CodigoFalha {
  emailEmUso,
  emailInvalido,
  senhaFraca,
  credenciaisInvalidas,
  usuarioDesativado,
  muitasTentativas,
  semConexao,
  desconhecido,
}

/// Erro de autenticação já traduzido para o usuário, sem detalhes sensíveis.
class AuthFalha implements Exception {
  const AuthFalha(this.codigo, this.mensagem);
  final CodigoFalha codigo;
  final String mensagem;

  @override
  String toString() => 'AuthFalha($codigo): $mensagem';
}

abstract class AuthRepository {
  /// Emite o usuário atual (ou null) ao iniciar e a cada login/logout.
  Stream<UsuarioAuth?> get mudancas;

  UsuarioAuth? get atual;

  Future<UsuarioAuth> cadastrarComEmail({required String nome, required String email, required String senha});

  Future<UsuarioAuth> entrarComEmail({required String email, required String senha, required bool lembrar});

  Future<void> enviarRecuperacaoSenha(String email);

  Future<void> reenviarVerificacao();

  /// Recarrega o usuário atual.
  Future<UsuarioAuth?> recarregar();

  Future<void> definirPersistencia({required bool lembrar});

  Future<void> sair();
}

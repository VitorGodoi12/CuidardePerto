import 'dart:async';

import 'package:cuidar_de_perto/models/idoso.dart';
import 'package:cuidar_de_perto/models/perfil_cuidador.dart';
import 'package:cuidar_de_perto/services/auth_repository.dart';
import 'package:cuidar_de_perto/services/dados_repository.dart';
import 'package:cuidar_de_perto/services/perfil_repository.dart';

/// Implementações em memória usadas nos testes automatizados.
class AuthEmMemoria implements AuthRepository {
  final Map<String, _Conta> _contas = {};
  final StreamController<UsuarioAuth?> _controle = StreamController<UsuarioAuth?>.broadcast();
  UsuarioAuth? _atual;
  int _seq = 0;

  final List<String> recuperacoesEnviadas = [];
  int verificacoesEnviadas = 0;

  @override
  Stream<UsuarioAuth?> get mudancas async* {
    yield _atual;
    yield* _controle.stream;
  }

  @override
  UsuarioAuth? get atual => _atual;

  void _definir(UsuarioAuth? u) {
    _atual = u;
    _controle.add(u);
  }

  UsuarioAuth _paraUsuario(_Conta c) => UsuarioAuth(
        uid: c.uid,
        email: c.email,
        nome: c.nome,
        emailVerificado: c.verificado,
        provedores: c.provedores,
      );

  void verificarEmailNoServidor(String email) => _contas[email]!.verificado = true;

  @override
  Future<UsuarioAuth> cadastrarComEmail({required String nome, required String email, required String senha}) async {
    final chave = email.trim().toLowerCase();
    if (_contas.containsKey(chave)) {
      throw const AuthFalha(CodigoFalha.emailEmUso, 'Este e-mail já está cadastrado. Entre com sua senha ou use "Esqueceu a senha?".');
    }
    final c = _Conta('uid${++_seq}', chave, senha, nome.trim(), ['password']);
    _contas[chave] = c;
    verificacoesEnviadas++;
    final u = _paraUsuario(c);
    _definir(u);
    return u;
  }

  @override
  Future<UsuarioAuth> entrarComEmail({required String email, required String senha, required bool lembrar}) async {
    final c = _contas[email.trim().toLowerCase()];
    if (c == null || c.senha != senha) {
      throw const AuthFalha(CodigoFalha.credenciaisInvalidas, 'E-mail ou senha incorretos.');
    }
    final u = _paraUsuario(c);
    _definir(u);
    return u;
  }

  @override
  Future<void> enviarRecuperacaoSenha(String email) async => recuperacoesEnviadas.add(email.trim());

  @override
  Future<void> reenviarVerificacao() async => verificacoesEnviadas++;

  @override
  Future<UsuarioAuth?> recarregar() async {
    final a = _atual;
    if (a == null) return null;
    final u = _paraUsuario(_contas[a.email]!);
    _atual = u;
    return u;
  }

  @override
  Future<void> definirPersistencia({required bool lembrar}) async {}

  @override
  Future<void> sair() async => _definir(null);
}

class _Conta {
  _Conta(this.uid, this.email, this.senha, this.nome, this.provedores);
  final String uid;
  final String email;
  final String senha;
  final String nome;
  final List<String> provedores;
  bool verificado = false;
}

class PerfisEmMemoria implements PerfilRepository {
  final Map<String, PerfilCuidador> bancos = {};

  @override
  Future<PerfilCuidador?> obter(String uid) async => bancos[uid];

  @override
  Future<PerfilCuidador> criar(PerfilCuidador perfil) async => bancos[perfil.uid] = perfil;

  @override
  Future<void> atualizar(String uid, Map<String, dynamic> campos) async {
    var p = bancos[uid]!;
    if (campos.containsKey('primeiroAcesso')) p = p.copiarCom(primeiroAcesso: campos['primeiroAcesso'] as bool);
    if (campos.containsKey('nomeCompleto')) p = p.copiarCom(nomeCompleto: campos['nomeCompleto'] as String);
    bancos[uid] = p;
  }
}

class DadosEmMemoria implements DadosRepository {
  final Map<String, Map<int, Map<String, dynamic>>> bancos = {};

  @override
  Future<List<Idoso>> carregarIdosos(String uid) async =>
      (bancos[uid] ?? {}).values.map((m) => Idoso.fromMap(Map<String, dynamic>.from(m))).toList();

  @override
  Future<void> salvarIdoso(String uid, Idoso idoso) async => (bancos[uid] ??= {})[idoso.id] = idoso.toMap();

  @override
  Future<void> removerIdoso(String uid, int id) async => bancos[uid]?.remove(id);
}


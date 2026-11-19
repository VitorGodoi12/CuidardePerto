import 'dart:async';

import 'package:cuidar_de_perto/models/alerta.dart';
import 'package:cuidar_de_perto/models/central_cuidado.dart';
import 'package:cuidar_de_perto/models/contato.dart';
import 'package:cuidar_de_perto/models/idoso.dart';
import 'package:cuidar_de_perto/models/medicamento.dart';
import 'package:cuidar_de_perto/models/perfil_cuidador.dart';
import 'package:cuidar_de_perto/services/auth_repository.dart';
import 'package:cuidar_de_perto/services/dados_repository.dart';
import 'package:cuidar_de_perto/services/perfil_repository.dart';

/// Implementações em memória para autenticação e dados locais do protótipo.
class AuthEmMemoria implements AuthRepository {
  AuthEmMemoria() {
    _contas[CredenciaisDemo.email] = _Conta(
      CredenciaisDemo.uid,
      CredenciaisDemo.email,
      CredenciaisDemo.senha,
      CredenciaisDemo.nome,
      ['password'],
    )..verificado = true;
  }

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
    c.verificado = true;
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

  PerfisEmMemoria() {
    bancos[CredenciaisDemo.uid] = PerfilCuidador(
      uid: CredenciaisDemo.uid,
      nomeCompleto: CredenciaisDemo.nome,
      email: CredenciaisDemo.email,
      telefone: '(11) 90000-0000',
      criadoEm: DateTime(2026, 1, 1),
      primeiroAcesso: false,
      provedores: const ['password'],
    );
  }

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

  DadosEmMemoria() {
    bancos[CredenciaisDemo.uid] = {for (final idoso in criarIdososDemo()) idoso.id: idoso.toMap()};
  }

  /// Cria uma amostra independente para cada experiência de demonstração.
  static List<Idoso> criarIdososDemo() {
    final idosos = [
      Idoso(
        id: 1,
        nome: 'Dona Maria',
        idade: 78,
        condicoes: ['Hipertensão'],
        endereco: 'Rua das Flores, 100',
        telefone: '(11) 90000-0001',
        alergias: 'Nenhuma alergia informada',
        observacoes: 'Prefere receber recados pelo cuidador.',
        horasSemMovimento: 0.5,
        dispositivoOnline: true,
        avatar: 'assets/images/avatar_maria.png',
        contatos: [
          Contato(nome: 'Clara Lima', parentesco: 'Filha', telefone: '(11) 90000-0011', principal: true),
        ],
        medicamentos: [
          Medicamento(nome: 'Losartana', dose: '50 mg', horario: '08:00', tomado: true, observacao: 'Registro fictício de demonstração.'),
          Medicamento(nome: 'Vitamina D', dose: '1 cápsula', horario: '13:00', tomado: true, observacao: 'Registro fictício de demonstração.'),
          Medicamento(nome: 'Suplemento de cálcio', dose: '1 comprimido', horario: '20:00', tomado: false, observacao: 'Registro fictício de demonstração.'),
        ],
      ),
      Idoso(
        id: 2,
        nome: 'Seu José',
        idade: 82,
        condicoes: ['Diabetes tipo 2'],
        endereco: 'Rua dos Ipês, 45',
        telefone: '(11) 90000-0002',
        alergias: 'Penicilina',
        observacoes: 'Usa bengala para caminhar.',
        horasSemMovimento: 3.5,
        dispositivoOnline: true,
        avatar: 'assets/images/avatar_jose.png',
        contatos: [
          Contato(nome: 'Paulo Almeida', parentesco: 'Filho', telefone: '(11) 90000-0012', principal: true),
        ],
        medicamentos: [
          Medicamento(nome: 'Metformina', dose: '500 mg', horario: '08:30', tomado: true, observacao: 'Registro fictício de demonstração.'),
          Medicamento(nome: 'Vitamina B12', dose: '1 comprimido', horario: '12:00', tomado: false, observacao: 'Registro fictício de demonstração.'),
          Medicamento(nome: 'Atorvastatina', dose: '20 mg', horario: '21:00', tomado: false, observacao: 'Registro fictício de demonstração.'),
        ],
      ),
      Idoso(
        id: 3,
        nome: 'Dona Antônia',
        idade: 74,
        condicoes: ['Osteoartrite'],
        endereco: 'Rua das Acácias, 72',
        telefone: '(11) 90000-0003',
        alergias: 'Nenhuma alergia informada',
        observacoes: 'Usa óculos para ler e prefere letras grandes.',
        horasSemMovimento: 6,
        dispositivoOnline: false,
        avatar: 'assets/images/avatar_antonia.png',
        contatos: [
          Contato(nome: 'Lúcia Rocha', parentesco: 'Irmã', telefone: '(11) 90000-0013', principal: true),
        ],
        medicamentos: [
          Medicamento(nome: 'Vitamina D', dose: '1 cápsula', horario: '09:00', tomado: true, observacao: 'Registro fictício de demonstração.'),
          Medicamento(nome: 'Suplemento de cálcio', dose: '1 comprimido', horario: '15:30', tomado: false, observacao: 'Registro fictício de demonstração.'),
          Medicamento(nome: 'Melatonina', dose: '1 comprimido', horario: '22:00', tomado: false, observacao: 'Registro fictício de demonstração.'),
        ],
      ),
    ];
    final agora = DateTime.now();
    for (final idoso in idosos) {
      final central = idoso.central;
      final contato = idoso.contatos.first;
      central.consultas.add(Consulta('Consulta de acompanhamento', Consulta.formatarData(agora), '16:00', 'UBS da demonstração'));
      central.diario.add(Registro('Rotina da manhã registrada pelo cuidador.', '09:30'));
      central.recados.add(Registro('Confirmar o horário da próxima visita com ${contato.nome}.', '10:15'));
      central.equipe.add(MembroEquipe(contato.nome, contato.parentesco));
      central.rotina.add('Café da manhã');
      central.historico.add('Check-in da manhã registrado.');
      central.agua = idoso.id + 1;
      central.humor = 'Bem';
      central.checkin = true;
      idoso.alertas.add(Alerta(
        id: idoso.id,
        idoso: idoso,
        tipo: TipoAlerta.semMovimento,
        nivel: NivelRisco.medio,
        descricao: 'Período sem movimento conferido pelo cuidador.',
        dataHora: DateTime(agora.year, agora.month, agora.day - 1, 11),
        resolvido: true,
      ));
    }
    return idosos;
  }

  @override
  Future<List<Idoso>> carregarIdosos(String uid) async =>
      (bancos[uid] ?? {}).values.map((m) => Idoso.fromMap(Map<String, dynamic>.from(m))).toList();

  @override
  Future<void> salvarIdoso(String uid, Idoso idoso) async => (bancos[uid] ??= {})[idoso.id] = idoso.toMap();

  @override
  Future<void> removerIdoso(String uid, int id) async => bancos[uid]?.remove(id);
}

import 'package:cuidar_de_perto/core/validadores.dart';
import 'package:cuidar_de_perto/data/dados_cuidador.dart';
import 'package:cuidar_de_perto/main.dart';
import 'package:cuidar_de_perto/models/alerta.dart';
import 'package:cuidar_de_perto/models/idoso.dart';
import 'package:cuidar_de_perto/models/medicamento.dart';
import 'package:cuidar_de_perto/screens/medicamentos_screen.dart';
import 'package:cuidar_de_perto/services/auth_repository.dart';
import 'package:cuidar_de_perto/state/sessao.dart';
import 'package:cuidar_de_perto/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fakes.dart';

Idoso criarIdoso({double horasSemMovimento = 0.3, List<Medicamento>? medicamentos, int id = 99}) {
  return Idoso(
    id: id,
    nome: 'Teste',
    idade: 80,
    condicoes: ['Hipertensão'],
    endereco: 'Rua A, 1',
    horasSemMovimento: horasSemMovimento,
    dispositivoOnline: true,
    avatar: 'assets/images/avatar.png',
    medicamentos: medicamentos,
  );
}

Medicamento atrasado() => Medicamento(nome: 'A', dose: '1 mg', horario: '08:00');
Medicamento pendente() => Medicamento(nome: 'B', dose: '1 mg', horario: '20:00');

void usarTelaDeCelular(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2700);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

class Ambiente {
  Ambiente() {
    sessao = Sessao(auth: auth, perfis: perfis, dados: dados);
  }
  final auth = AuthEmMemoria();
  final perfis = PerfisEmMemoria();
  final dados = DadosEmMemoria();
  late final Sessao sessao;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    DadosCuidador.fixarMinutosParaTestes(14 * 60);
    DadosCuidador.limpar();
  });
  tearDown(() => DadosCuidador.fixarMinutosParaTestes(null));

  group('Regras de risco', () {
    test('baixo quando nenhuma condição é atendida', () {
      expect(criarIdoso(medicamentos: [pendente()]).risco, NivelRisco.baixo);
    });
    test('médio com 3 h sem movimento', () => expect(criarIdoso(horasSemMovimento: 3).risco, NivelRisco.medio));
    test('médio com 1 dose atrasada', () => expect(criarIdoso(medicamentos: [atrasado()]).risco, NivelRisco.medio));
    test('alto com 6 h sem movimento', () => expect(criarIdoso(horasSemMovimento: 6).risco, NivelRisco.alto));
    test('alto com 2 doses atrasadas', () => expect(criarIdoso(medicamentos: [atrasado(), atrasado()]).risco, NivelRisco.alto));

    test('crítico com alerta de queda aberto e volta ao normal ao resolver', () {
      final idoso = criarIdoso();
      final alerta = idoso.registrarEvento(TipoAlerta.queda);
      expect(idoso.risco, NivelRisco.critico);
      alerta.resolvido = true;
      expect(idoso.risco, NivelRisco.baixo);
    });

    test('marcar a dose como tomada recalcula o risco', () {
      final dose = atrasado();
      final idoso = criarIdoso(medicamentos: [dose]);
      expect(idoso.risco, NivelRisco.medio);
      dose.tomado = true;
      expect(idoso.risco, NivelRisco.baixo);
    });
  });

  group('Medicamento', () {
    test('atraso depende do horário e de não ter sido tomado', () {
      expect(Medicamento(nome: 'X', dose: '1', horario: '13:59').atrasado, isTrue);
      expect(Medicamento(nome: 'X', dose: '1', horario: '14:00').atrasado, isFalse);
      expect(Medicamento(nome: 'X', dose: '1', horario: '08:00', tomado: true).atrasado, isFalse);
    });
  });

  group('Serialização', () {
    test('idoso completo ida e volta preserva medicamentos, alertas e agenda', () {
      final idoso = criarIdoso(medicamentos: [atrasado()]);
      idoso.registrarEvento(TipoAlerta.panico);
      idoso.central.agua = 4;
      final copia = Idoso.fromMap(idoso.toMap());
      expect(copia.medicamentos.single.nome, 'A');
      expect(copia.alertas.single.tipo, TipoAlerta.panico);
      expect(copia.alertas.single.idoso, same(copia));
      expect(copia.central.agua, 4);
    });
  });

  group('Validadores', () {
    test('e-mail', () {
      expect(Validadores.email('a@b.com'), isNull);
      expect(Validadores.email('a@b'), isNotNull);
      expect(Validadores.email(''), isNotNull);
    });
    test('senha com pelo menos 8 caracteres', () {
      expect(Validadores.senhaNova('1234567'), isNotNull);
      expect(Validadores.senhaNova('12345678'), isNull);
    });
    test('confirmação diferente', () {
      expect(Validadores.confirmacao('abc', 'abd'), 'As senhas não coincidem');
      expect(Validadores.confirmacao('abc', 'abc'), isNull);
    });
    test('telefone opcional', () {
      expect(Validadores.telefoneOpcional(''), isNull);
      expect(Validadores.telefoneOpcional('(11) 98765-4321'), isNull);
      expect(Validadores.telefoneOpcional('123'), isNotNull);
    });
  });

  group('Sessão (cadastro, login, isolamento)', () {
    test('cadastro cria perfil de cuidador e pede verificação de e-mail', () async {
      final a = Ambiente();
      await a.sessao.cadastrar(nome: 'Ana Souza', email: 'ana@x.com', senha: '12345678', telefone: '(11) 98765-4321');
      expect(a.sessao.status, StatusSessao.verificandoEmail);
      final perfil = a.perfis.bancos.values.single;
      expect(perfil.tipoUsuario, 'cuidador');
      expect(perfil.nomeCompleto, 'Ana Souza');
      expect(perfil.telefone, '(11) 98765-4321');
      expect(perfil.primeiroAcesso, isTrue);
      expect(a.auth.verificacoesEnviadas, 1);
    });

    test('e-mail só é considerado verificado quando o servidor confirma', () async {
      final a = Ambiente();
      await a.sessao.cadastrar(nome: 'Ana Souza', email: 'ana@x.com', senha: '12345678');
      expect(await a.sessao.atualizarVerificacao(), isFalse);
      expect(a.sessao.status, StatusSessao.verificandoEmail);
      a.auth.verificarEmailNoServidor('ana@x.com');
      expect(await a.sessao.atualizarVerificacao(), isTrue);
      expect(a.sessao.status, StatusSessao.primeiroAcesso);
    });

    test('cadastro com e-mail já existente é recusado', () async {
      final a = Ambiente();
      await a.sessao.cadastrar(nome: 'Ana Souza', email: 'ana@x.com', senha: '12345678');
      await a.sessao.sair();
      expect(
        () => a.sessao.cadastrar(nome: 'Outra Pessoa', email: 'ana@x.com', senha: '87654321'),
        throwsA(isA<AuthFalha>().having((f) => f.codigo, 'codigo', CodigoFalha.emailEmUso)),
      );
    });

    test('login com senha incorreta falha e com a correta funciona', () async {
      final a = Ambiente();
      await a.sessao.cadastrar(nome: 'Ana Souza', email: 'ana@x.com', senha: '12345678');
      a.auth.verificarEmailNoServidor('ana@x.com');
      await a.sessao.sair();
      expect(() => a.sessao.entrarComEmail(email: 'ana@x.com', senha: 'errada123', lembrar: true), throwsA(isA<AuthFalha>()));
      await a.sessao.entrarComEmail(email: 'ana@x.com', senha: '12345678', lembrar: true);
      expect(a.sessao.status, StatusSessao.primeiroAcesso);
    });

    test('primeiro acesso aparece uma vez por usuário', () async {
      final a = Ambiente();
      await a.sessao.cadastrar(nome: 'Ana Souza', email: 'ana@x.com', senha: '12345678');
      a.auth.verificarEmailNoServidor('ana@x.com');
      await a.sessao.atualizarVerificacao();
      await a.sessao.concluirPrimeiroAcesso(acao: AcaoInicial.cadastrarIdoso);
      expect(a.sessao.status, StatusSessao.autenticado);
      expect(a.sessao.consumirAcaoInicial(), AcaoInicial.cadastrarIdoso);
      expect(a.sessao.consumirAcaoInicial(), AcaoInicial.nenhuma);
      await a.sessao.sair();
      await a.sessao.entrarComEmail(email: 'ana@x.com', senha: '12345678', lembrar: true);
      expect(a.sessao.status, StatusSessao.autenticado);
    });

    test('recuperação de senha envia o e-mail', () async {
      final a = Ambiente();
      await a.sessao.enviarRecuperacaoSenha(' ana@x.com ');
      expect(a.auth.recuperacoesEnviadas, ['ana@x.com']);
    });

    test('dados persistem entre logins e ficam isolados entre cuidadores', () async {
      final a = Ambiente();
      // Cuidadora 1
      await a.sessao.cadastrar(nome: 'Ana Souza', email: 'ana@x.com', senha: '12345678');
      a.auth.verificarEmailNoServidor('ana@x.com');
      await a.sessao.atualizarVerificacao();
      await a.sessao.concluirPrimeiroAcesso();
      DadosCuidador.adicionar(criarIdoso(id: 1, medicamentos: [pendente()]));
      await DadosCuidador.sincronizarPendentes();
      await a.sessao.sair();
      expect(DadosCuidador.idosos, isEmpty);

      // Cuidador 2 não enxerga nada da Ana
      await a.sessao.cadastrar(nome: 'Bruno Lima', email: 'bruno@x.com', senha: '12345678');
      expect(DadosCuidador.idosos, isEmpty);
      await a.sessao.sair();

      // Ana volta e recupera os dados
      await a.sessao.entrarComEmail(email: 'ana@x.com', senha: '12345678', lembrar: true);
      expect(DadosCuidador.idosos, hasLength(1));
      expect(DadosCuidador.idosos.single.medicamentos.single.nome, 'B');
    });

    test('"Lembrar-me" desmarcado encerra a sessão ao reabrir o app', () async {
      final a = Ambiente();
      await a.sessao.cadastrar(nome: 'Ana Souza', email: 'ana@x.com', senha: '12345678');
      // O usuário desmarcou "Lembrar-me" no último login.
      SharedPreferences.setMockInitialValues({'manter_sessao': false});
      expect(a.auth.atual, isNotNull);
      final reaberto = Sessao(auth: a.auth, perfis: a.perfis, dados: a.dados);
      await reaberto.iniciar();
      await Future<void>.delayed(Duration.zero);
      expect(a.auth.atual, isNull);
      expect(reaberto.status, StatusSessao.deslogado);
    });

    test('sessão salva é restaurada ao abrir o app', () async {
      final a = Ambiente();
      await a.sessao.cadastrar(nome: 'Ana Souza', email: 'ana@x.com', senha: '12345678');
      a.auth.verificarEmailNoServidor('ana@x.com');
      await a.sessao.atualizarVerificacao();
      await a.sessao.concluirPrimeiroAcesso();
      final reaberto = Sessao(auth: a.auth, perfis: a.perfis, dados: a.dados);
      await reaberto.iniciar();
      await Future<void>.delayed(Duration.zero);
      expect(reaberto.status, StatusSessao.autenticado);
      expect(reaberto.perfil!.nomeCompleto, 'Ana Souza');
    });
  });

  group('Telas de acesso', () {
    Future<Ambiente> abrir(WidgetTester tester) async {
      usarTelaDeCelular(tester);
      final a = Ambiente();
      await tester.runAsync(() => a.sessao.iniciar());
      await tester.pumpWidget(CuidarDePertoApp(sessao: a.sessao));
      await tester.pumpAndSettle();
      return a;
    }

    testWidgets('login valida campos vazios', (tester) async {
      await abrir(tester);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Entrar'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), '');
      await tester.enterText(find.byType(TextFormField).at(1), '');
      final entrar = find.widgetWithText(ElevatedButton, 'Entrar');
      await tester.ensureVisible(entrar);
      await tester.tap(entrar);
      await tester.pump();
      expect(find.text('Informe seu e-mail'), findsOneWidget);
      expect(find.text('Informe sua senha'), findsOneWidget);
    });

    testWidgets('login com credenciais incorretas mostra erro', (tester) async {
      await abrir(tester);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Entrar'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'ana@x.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'senhaerrada');
      final entrar = find.widgetWithText(ElevatedButton, 'Entrar');
      await tester.ensureVisible(entrar);
      await tester.tap(entrar);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('E-mail ou senha incorretos.'), findsOneWidget);
    });

    testWidgets('cadastro com senhas diferentes é bloqueado', (tester) async {
      final a = await abrir(tester);
      await tester.tap(find.widgetWithText(OutlinedButton, 'Cadastrar'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'Ana Souza');
      await tester.enterText(find.byType(TextFormField).at(1), 'ana@x.com');
      await tester.enterText(find.byType(TextFormField).at(3), '12345678');
      await tester.enterText(find.byType(TextFormField).at(4), '12345679');
      await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Criar conta'));
      await tester.tap(find.widgetWithText(ElevatedButton, 'Criar conta'));
      await tester.pumpAndSettle();
      expect(find.text('As senhas não coincidem'), findsOneWidget);
      expect(a.auth.atual, isNull);
    });

    testWidgets('cadastro exige aceitar os termos', (tester) async {
      final a = await abrir(tester);
      await tester.tap(find.widgetWithText(OutlinedButton, 'Cadastrar'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'Ana Souza');
      await tester.enterText(find.byType(TextFormField).at(1), 'ana@x.com');
      await tester.enterText(find.byType(TextFormField).at(3), '12345678');
      await tester.enterText(find.byType(TextFormField).at(4), '12345678');
      await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Criar conta'));
      await tester.tap(find.widgetWithText(ElevatedButton, 'Criar conta'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Aceite os Termos de Uso'), findsOneWidget);
      expect(a.auth.atual, isNull);
    });

    testWidgets('cadastro completo leva à verificação de e-mail', (tester) async {
      final a = await abrir(tester);
      await tester.tap(find.widgetWithText(OutlinedButton, 'Cadastrar'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'Ana Souza');
      await tester.enterText(find.byType(TextFormField).at(1), 'ana@x.com');
      await tester.enterText(find.byType(TextFormField).at(3), '12345678');
      await tester.enterText(find.byType(TextFormField).at(4), '12345678');
      await tester.ensureVisible(find.byType(Checkbox));
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Criar conta'));
      await tester.tap(find.widgetWithText(ElevatedButton, 'Criar conta'));
      await tester.pumpAndSettle();
      expect(find.text('Verifique seu e-mail'), findsOneWidget);
      expect(a.auth.atual?.email, 'ana@x.com');
    });

    testWidgets('recuperação de senha confirma o envio', (tester) async {
      final a = await abrir(tester);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Entrar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Esqueceu a senha?'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'ana@x.com');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Enviar link de recuperação'));
      await tester.pumpAndSettle();
      expect(find.text('Confira seu e-mail'), findsOneWidget);
      expect(a.auth.recuperacoesEnviadas, ['ana@x.com']);
      // Encerra a contagem de reenvio antes de finalizar o teste.
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('Medicamentos', () {
    testWidgets('cadastro rejeita horário inválido e salva horário digitado sem dois-pontos', (tester) async {
      usarTelaDeCelular(tester);
      final idoso = criarIdoso();
      await tester.pumpWidget(MaterialApp(theme: AppTheme.tema, home: MedicamentosScreen(idoso: idoso)));
      await tester.tap(find.text('Adicionar Medicamento'));
      await tester.pumpAndSettle();

      final campos = find.byType(TextFormField);
      await tester.enterText(campos.at(0), 'Medicamento de teste');
      await tester.enterText(campos.at(1), '1 comprimido');
      await tester.enterText(campos.at(2), '2570');
      final salvar = find.text('Salvar medicamento');
      await tester.ensureVisible(salvar);
      await tester.tap(salvar);
      await tester.pumpAndSettle();
      expect(find.textContaining('Horário inválido'), findsOneWidget);
      expect(idoso.medicamentos, isEmpty);

      await tester.enterText(campos.at(2), '0830');
      await tester.ensureVisible(salvar);
      await tester.tap(salvar);
      await tester.pumpAndSettle();
      expect(idoso.medicamentos.single.horario, '08:30');
      expect(find.text('Medicamento de teste'), findsOneWidget);
    });

    testWidgets('marcar como tomado atualiza o contador na hora', (tester) async {
      usarTelaDeCelular(tester);
      final idoso = criarIdoso(medicamentos: [atrasado(), pendente()]);
      await tester.pumpWidget(MaterialApp(theme: AppTheme.tema, home: MedicamentosScreen(idoso: idoso)));
      expect(find.text('0 de 2'), findsOneWidget);
      await tester.tap(find.text('A'));
      await tester.pumpAndSettle();
      expect(find.text('1 de 2'), findsOneWidget);
      expect(idoso.medicamentos.first.tomado, isTrue);
    });
  });
}


import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/dados_cuidador.dart';
import '../models/perfil_cuidador.dart';
import '../services/auth_repository.dart';
import '../services/dados_repository.dart';
import '../services/perfil_repository.dart';

enum StatusSessao {
  /// Descobrindo se já existe uma sessão salva.
  iniciando,

  /// Ninguém autenticado.
  deslogado,

  /// Conta de e-mail/senha com endereço ainda não verificado.
  verificandoEmail,

  /// Conta nova: apresenta as boas-vindas.
  primeiroAcesso,

  /// Sessão ativa com perfil e dados carregados.
  autenticado,

  /// Autenticou, mas não foi possível carregar o perfil/dados.
  erro,
}

/// Ação sugerida na tela de boas-vindas, executada ao abrir o início.
enum AcaoInicial { nenhuma, cadastrarIdoso, conhecerFuncionalidades, configurarNotificacoes }

/// Orquestra login, cadastro, perfil e dados do cuidador.
class Sessao extends ChangeNotifier {
  Sessao({
    required this.auth,
    required this.perfis,
    required this.dados,
  });

  final AuthRepository auth;
  final PerfilRepository perfis;
  final DadosRepository dados;

  static const String _chaveEmail = 'lembrar_email';
  static const String _chaveManter = 'manter_sessao';

  StatusSessao _status = StatusSessao.iniciando;
  UsuarioAuth? _usuario;
  PerfilCuidador? _perfil;
  String? _mensagemErro;
  StreamSubscription<UsuarioAuth?>? _assinatura;
  bool _fluxoManual = false;
  String? _nomeInicial;
  String? _telefoneInicial;
  AcaoInicial _acaoInicial = AcaoInicial.nenhuma;
  String _emailLembrado = '';
  bool _lembrar = true;

  StatusSessao get status => _status;
  UsuarioAuth? get usuario => _usuario;
  PerfilCuidador? get perfil => _perfil;
  String? get mensagemErro => _mensagemErro;
  String get emailLembrado => _emailLembrado;
  bool get lembrarPadrao => _lembrar;

  /// Lê as preferências e passa a acompanhar a autenticação.
  Future<void> iniciar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _emailLembrado = prefs.getString(_chaveEmail) ?? '';
      _lembrar = prefs.getBool(_chaveManter) ?? true;
    } catch (_) {
      // Sem acesso às preferências o app segue com os padrões.
    }
    // "Lembrar-me" desmarcado: a sessão não sobrevive ao fechamento do aplicativo.
    if (!_lembrar && auth.atual != null) {
      await auth.sair();
    }
    _assinatura = auth.mudancas.listen(_aoMudar, onError: (Object e) {
      _status = StatusSessao.deslogado;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _assinatura?.cancel();
    super.dispose();
  }

  Future<void> _guardarPreferencias({required bool lembrar, String? email}) async {
    _lembrar = lembrar;
    _emailLembrado = lembrar ? (email ?? _emailLembrado) : '';
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_chaveManter, lembrar);
      if (lembrar && email != null) {
        await prefs.setString(_chaveEmail, email.trim());
      } else if (!lembrar) {
        await prefs.remove(_chaveEmail);
      }
    } catch (_) {}
  }

  Future<void> _aoMudar(UsuarioAuth? u) async {
    if (_fluxoManual) return;
    if (u == null) {
      _descartarDados();
      _status = StatusSessao.deslogado;
      notifyListeners();
      return;
    }
    await _carregar(u);
  }

  void _descartarDados() {
    DadosCuidador.limpar();
    _usuario = null;
    _perfil = null;
  }

  /// Carrega (ou cria, no primeiro acesso) o perfil e os dados do usuário autenticado.
  Future<void> _carregar(UsuarioAuth u) async {
    _usuario = u;
    _mensagemErro = null;
    try {
      var perfil = await perfis.obter(u.uid);
      perfil ??= await perfis.criar(PerfilCuidador(
        uid: u.uid,
        nomeCompleto: _nomeInicial ?? ((u.nome ?? '').trim().isNotEmpty ? u.nome!.trim() : u.email.split('@').first),
        email: u.email,
        telefone: _telefoneInicial ?? '',
        fotoUrl: u.fotoUrl,
        criadoEm: DateTime.now(),
        primeiroAcesso: true,
        provedores: u.provedores,
      ));
      final idosos = await dados.carregarIdosos(u.uid);
      DadosCuidador.definir(u.uid, idosos, dados);
      _perfil = perfil;
      if (u.exigeVerificacao) {
        _status = StatusSessao.verificandoEmail;
      } else if (perfil.primeiroAcesso) {
        _status = StatusSessao.primeiroAcesso;
      } else {
        _status = StatusSessao.autenticado;
      }
    } catch (e) {
      debugPrint('Falha ao carregar perfil: $e');
      _perfil = null;
      DadosCuidador.limpar();
      _status = StatusSessao.erro;
      _mensagemErro = 'Não foi possível carregar seus dados locais. Tente novamente.';
    } finally {
      _nomeInicial = null;
      _telefoneInicial = null;
    }
    notifyListeners();
  }

  /// Executa um fluxo de autenticação sem que o ouvinte global interfira.
  Future<T> _fluxo<T>(Future<T> Function() acao, Future<void> Function(T resultado) aposSucesso) async {
    _fluxoManual = true;
    try {
      final r = await acao();
      await aposSucesso(r);
      return r;
    } finally {
      _fluxoManual = false;
    }
  }

  Future<void> cadastrar({
    required String nome,
    required String email,
    required String senha,
    String telefone = '',
  }) async {
    _nomeInicial = nome.trim();
    _telefoneInicial = telefone.trim();
    try {
      await _fluxo<UsuarioAuth>(
        () => auth.cadastrarComEmail(nome: nome, email: email, senha: senha),
        (u) async {
          await _guardarPreferencias(lembrar: true, email: email);
          await _carregar(u);
        },
      );
    } catch (_) {
      _nomeInicial = null;
      _telefoneInicial = null;
      rethrow;
    }
  }

  Future<void> entrarComEmail({required String email, required String senha, required bool lembrar}) async {
    await _fluxo<UsuarioAuth>(
      () => auth.entrarComEmail(email: email, senha: senha, lembrar: lembrar),
      (u) async {
        await _guardarPreferencias(lembrar: lembrar, email: email);
        await _carregar(u);
      },
    );
  }

  Future<void> enviarRecuperacaoSenha(String email) => auth.enviarRecuperacaoSenha(email);

  Future<void> reenviarVerificacao() => auth.reenviarVerificacao();

  /// Atualiza o status de verificação do e-mail. Devolve true quando já está verificado.
  Future<bool> atualizarVerificacao() async {
    final u = await auth.recarregar();
    if (u == null) return false;
    if (!u.exigeVerificacao) {
      await _carregar(u);
      return true;
    }
    _usuario = u;
    notifyListeners();
    return false;
  }

  /// Tenta carregar de novo os dados após uma falha.
  Future<void> tentarNovamente() async {
    final u = auth.atual;
    if (u == null) {
      _status = StatusSessao.deslogado;
      notifyListeners();
      return;
    }
    _status = StatusSessao.iniciando;
    notifyListeners();
    await _carregar(u);
  }

  /// Retorna (uma única vez) a ação escolhida nas boas-vindas.
  AcaoInicial consumirAcaoInicial() {
    final a = _acaoInicial;
    _acaoInicial = AcaoInicial.nenhuma;
    return a;
  }

  /// Marca o primeiro acesso e recarrega as pessoas acompanhadas.
  Future<void> recarregarDados() async {
    final u = _usuario;
    if (u == null) return;
    await DadosCuidador.sincronizarPendentes();
    final idosos = await dados.carregarIdosos(u.uid);
    DadosCuidador.definir(u.uid, idosos, dados);
    notifyListeners();
  }

  Future<void> concluirPrimeiroAcesso({AcaoInicial acao = AcaoInicial.nenhuma}) async {
    final p = _perfil;
    if (p == null) return;
    await perfis.atualizar(p.uid, {'primeiroAcesso': false});
    _perfil = p.copiarCom(primeiroAcesso: false);
    _acaoInicial = acao;
    _status = StatusSessao.autenticado;
    notifyListeners();
  }

  /// Atualiza nome e telefone. O tipo de usuário nunca é enviado.
  Future<void> atualizarPerfil({String? nomeCompleto, String? telefone}) async {
    final p = _perfil;
    if (p == null) return;
    final campos = <String, dynamic>{
      if (nomeCompleto != null) 'nomeCompleto': nomeCompleto.trim(),
      if (telefone != null) 'telefone': telefone.trim(),
    };
    if (campos.isEmpty) return;
    await perfis.atualizar(p.uid, campos);
    _perfil = p.copiarCom(nomeCompleto: nomeCompleto?.trim(), telefone: telefone?.trim());
    notifyListeners();
  }

  Future<void> atualizarNotificacoes(PreferenciasNotificacao prefs) async {
    final p = _perfil;
    if (p == null) return;
    await perfis.atualizar(p.uid, {'notificacoes': prefs.toMap()});
    _perfil = p.copiarCom(notificacoes: prefs);
    notifyListeners();
  }

  /// Envia o e-mail de redefinição de senha da conta atual.
  Future<void> enviarAlteracaoSenha() async {
    final email = _usuario?.email ?? '';
    if (email.isEmpty) return;
    await auth.enviarRecuperacaoSenha(email);
  }

  Future<void> sair() async {
    _fluxoManual = true;
    try {
      await DadosCuidador.sincronizarPendentes();
      await auth.sair();
    } finally {
      _fluxoManual = false;
    }
    _descartarDados();
    _status = StatusSessao.deslogado;
    notifyListeners();
  }
}

/// Disponibiliza a [Sessao] para toda a árvore de widgets.
class SessaoScope extends InheritedNotifier<Sessao> {
  const SessaoScope({super.key, required Sessao sessao, required super.child}) : super(notifier: sessao);

  static Sessao of(BuildContext context) {
    final escopo = context.dependOnInheritedWidgetOfExactType<SessaoScope>();
    assert(escopo != null, 'SessaoScope não encontrado na árvore de widgets');
    return escopo!.notifier!;
  }

  /// Versão sem registrar dependência (para usar em callbacks).
  static Sessao leitura(BuildContext context) {
    final escopo = context.getInheritedWidgetOfExactType<SessaoScope>();
    assert(escopo != null, 'SessaoScope não encontrado na árvore de widgets');
    return escopo!.notifier!;
  }
}

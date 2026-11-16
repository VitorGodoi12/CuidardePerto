import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/idoso.dart';
import '../services/dados_repository.dart';

/// Dados em memória do cuidador autenticado (pessoas acompanhadas, medicamentos,
/// contatos, alertas e agenda), mantidos localmente durante a execução.
///
/// Os dados são carregados no login e descartados no logout, de modo que
/// um cuidador nunca enxerga as informações de outro.
class DadosCuidador {
  DadosCuidador._();

  static final List<Idoso> idosos = <Idoso>[];
  static String? _uid;
  static DadosRepository? _repositorio;
  static final Map<int, Timer> _pendentes = <int, Timer>{};
  static final Map<int, Idoso> _porSalvar = <int, Idoso>{};
  static int? _minutosFixos;

  /// Mensagem do último erro de sincronização (null quando tudo certo).
  static final ValueNotifier<String?> erroSincronizacao = ValueNotifier<String?>(null);

  /// Minutos desde 00:00 usados para decidir se uma dose está atrasada.
  static int get minutosAgora {
    if (_minutosFixos != null) return _minutosFixos!;
    final agora = DateTime.now();
    return agora.hour * 60 + agora.minute;
  }

  /// Permite fixar o relógio nos testes automatizados.
  @visibleForTesting
  static void fixarMinutosParaTestes(int? minutos) => _minutosFixos = minutos;

  static void definir(String uid, List<Idoso> lista, DadosRepository repositorio) {
    _cancelarPendentes();
    _uid = uid;
    _repositorio = repositorio;
    idosos
      ..clear()
      ..addAll(lista);
  }

  /// Remove tudo da memória (logout).
  static void limpar() {
    _cancelarPendentes();
    _uid = null;
    _repositorio = null;
    idosos.clear();
    erroSincronizacao.value = null;
  }

  static void _cancelarPendentes() {
    for (final t in _pendentes.values) {
      t.cancel();
    }
    _pendentes.clear();
    _porSalvar.clear();
  }

  /// Agenda a gravação (com pequena espera para agrupar alterações seguidas).
  /// Não faz nada se não há conta autenticada (por exemplo, em testes de widget).
  static void salvar(Idoso idoso) {
    if (_repositorio == null || _uid == null) return;
    _pendentes[idoso.id]?.cancel();
    _porSalvar[idoso.id] = idoso;
    _pendentes[idoso.id] = Timer(const Duration(milliseconds: 500), () => _gravar(idoso));
  }

  static Future<void> _gravar(Idoso idoso) async {
    final repo = _repositorio;
    final uid = _uid;
    _pendentes.remove(idoso.id);
    _porSalvar.remove(idoso.id);
    if (repo == null || uid == null) return;
    try {
      await repo.salvarIdoso(uid, idoso);
      erroSincronizacao.value = null;
    } catch (e) {
      debugPrint('Falha ao sincronizar ${idoso.id}: $e');
      erroSincronizacao.value = 'Não foi possível salvar suas alterações agora. Verifique a conexão.';
    }
  }

  /// Grava imediatamente o que ainda está na fila (usado antes do logout).
  static Future<void> sincronizarPendentes() async {
    final fila = _porSalvar.values.toList();
    for (final t in _pendentes.values) {
      t.cancel();
    }
    _pendentes.clear();
    _porSalvar.clear();
    for (final idoso in fila) {
      await _gravar(idoso);
    }
  }

  static void adicionar(Idoso idoso) {
    idosos.add(idoso);
    salvar(idoso);
  }

  static int proximoId() => idosos.fold<int>(0, (maior, i) => i.id > maior ? i.id : maior) + 1;
}

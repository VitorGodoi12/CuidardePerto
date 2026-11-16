import '../models/idoso.dart';

/// Persistência das pessoas acompanhadas de um cuidador.
abstract class DadosRepository {
  Future<List<Idoso>> carregarIdosos(String uid);
  Future<void> salvarIdoso(String uid, Idoso idoso);
  Future<void> removerIdoso(String uid, int id);
}


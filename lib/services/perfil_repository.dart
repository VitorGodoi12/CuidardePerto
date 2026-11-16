import '../models/perfil_cuidador.dart';

/// Persistência do perfil do cuidador.
abstract class PerfilRepository {
  Future<PerfilCuidador?> obter(String uid);
  Future<PerfilCuidador> criar(PerfilCuidador perfil);
  Future<void> atualizar(String uid, Map<String, dynamic> campos);
}


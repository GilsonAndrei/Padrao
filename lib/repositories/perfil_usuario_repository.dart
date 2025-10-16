// repositories/perfil_usuario_repository.dart
import 'package:projeto_padrao/core/constants/app_constants.dart';
import 'package:projeto_padrao/models/perfil_usuario.dart';
import 'package:projeto_padrao/repositories/generic_repository.dart';

class PerfilUsuarioRepository extends GenericRepository<PerfilUsuario> {
  PerfilUsuarioRepository()
    : super(
        collectionName: AppConstants.profilesCollection,
        fromMap: (map, id) => PerfilUsuario.fromFirestore(
          map,
          id,
        ), // ✅ CORRETO se tiver fromFirestore
      );
}

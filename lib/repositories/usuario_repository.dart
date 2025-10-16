// repositories/usuario_repository.dart
import 'package:projeto_padrao/core/constants/app_constants.dart';
import 'package:projeto_padrao/models/usuario.dart';
import 'package:projeto_padrao/repositories/generic_repository.dart';

class UsuarioRepository extends GenericRepository<Usuario> {
  UsuarioRepository()
    : super(
        collectionName: AppConstants.usersCollection,
        fromMap: (map, id) => Usuario.fromMap(map, id), // CORREÇÃO AQUI
      );

  // Métodos específicos para usuários
  Future<Usuario?> getByEmail(String email) async {
    final query = collection.where('email', isEqualTo: email).limit(1);
    final snapshot = await query.get();

    if (snapshot.docs.isEmpty) return null;

    final doc = snapshot.docs.first;
    return fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }
}

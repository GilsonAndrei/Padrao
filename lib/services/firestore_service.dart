// services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projeto_padrao/core/constants/app_constants.dart';
import '../models/usuario.dart';
import '../models/perfil_usuario.dart';
import '../enums/permissao_usuario.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Salva/Atualiza um usuário no Firestore
  Future<void> saveUser(Usuario usuario) async {
    try {
      
      print('💾 [FIRESTORE] Salvando usuário: ${usuario.id}');

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(usuario.id)
          .set(usuario.toMap());

      print('✅ [FIRESTORE] Usuário salvo com sucesso!');
    } catch (e) {
      print('❌ [FIRESTORE] Erro ao salvar usuário: $e');
      rethrow;
    }
  }

  // Busca um usuário pelo ID
  Future<Usuario?> getUserById(String userId) async {
    try {
      print('🔍 [FIRESTORE] Buscando usuário com ID: $userId');

      DocumentSnapshot userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();

      print('📄 [FIRESTORE] Documento existe: ${userDoc.exists}');

      if (userDoc.exists) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        print('📊 [FIRESTORE] Campos encontrados: ${data.keys}');

        try {
          Usuario usuario = Usuario.fromMap(data);
          print('✅ [FIRESTORE] Usuário convertido: ${usuario.nome}');
          return usuario;
        } catch (e) {
          print('❌ [FIRESTORE] Erro na conversão: $e');
          return null;
        }
      } else {
        print('❌ [FIRESTORE] Documento não existe no Firestore');
        return null;
      }
    } catch (e) {
      print('❌ [FIRESTORE] Erro ao buscar usuário: $e');
      return null;
    }
  }

  // Deletar usuário
  Future<void> deleteUser(String userId) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .delete();
      print('✅ [FIRESTORE] Usuário deletado: $userId');
    } catch (e) {
      print('❌ [FIRESTORE] Erro ao deletar usuário: $e');
      rethrow;
    }
  }

  // Verificar se usuário existe
  Future<bool> userExists(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();
      return doc.exists;
    } catch (e) {
      print('❌ [FIRESTORE] Erro ao verificar usuário: $e');
      return false;
    }
  }
}

// controllers/usuario/usuario_controller.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projeto_padrao/models/usuario.dart';
import 'package:projeto_padrao/models/perfil_usuario.dart';

class UsuarioController with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _usuariosCollection = FirebaseFirestore.instance
      .collection('usuarios');

  List<Usuario> _items = [];
  bool _isLoading = false;
  int _currentPage = 0;
  int _totalItems = 0;
  bool _hasMoreItems = true;
  final int _itemsPerPage = 20;
  DocumentSnapshot? _lastDocument;

  List<Usuario> get items => _items;
  bool get isLoading => _isLoading;
  int get totalItems => _totalItems;
  bool get hasMoreItems => _hasMoreItems;

  Future<void> loadItems({bool reset = false}) async {
    if (reset) {
      _currentPage = 0;
      _items = [];
      _hasMoreItems = true;
      _totalItems = 0;
      _lastDocument = null;
    }

    if (_isLoading || !_hasMoreItems) return;

    _isLoading = true;
    notifyListeners();

    try {
      Query query = _usuariosCollection.orderBy('nome').limit(_itemsPerPage);

      // Para paginação, usa o último documento carregado
      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final querySnapshot = await query.get();

      if (querySnapshot.docs.isEmpty) {
        _hasMoreItems = false;
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Converte os documentos do Firestore para objetos Usuario
      final newUsers = await _convertDocsToUsuarios(querySnapshot.docs);

      _items.addAll(newUsers);
      _lastDocument = querySnapshot.docs.last;
      _currentPage++;

      // Atualiza o total de itens (para estatísticas)
      await _updateTotalCount();

      _hasMoreItems = querySnapshot.docs.length == _itemsPerPage;
    } catch (error) {
      print('Erro ao carregar usuários do Firebase: $error');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Usuario>> _convertDocsToUsuarios(
    List<QueryDocumentSnapshot> docs,
  ) async {
    final List<Usuario> usuarios = [];

    for (final doc in docs) {
      try {
        final usuarioData = doc.data() as Map<String, dynamic>;
        final usuario = Usuario.fromMap({...usuarioData, 'id': doc.id});
        usuarios.add(usuario);
      } catch (e) {
        print('Erro ao converter documento ${doc.id}: $e');
      }
    }

    return usuarios;
  }

  Future<void> _updateTotalCount() async {
    try {
      final countQuery = await _usuariosCollection.count().get();
      _totalItems = countQuery.count!;
    } catch (error) {
      print('Erro ao contar usuários: $error');
      _totalItems = _items.length;
    }
  }

  Future<void> saveItem(Usuario usuario) async {
    try {
      _isLoading = true;
      notifyListeners();

      final usuarioMap = usuario.toMap();

      if (usuario.id.isEmpty || usuario.id == '0') {
        // Novo usuário - cria no Firestore
        final docRef = await _usuariosCollection.add(usuarioMap);

        // Adiciona à lista local com o ID gerado pelo Firestore
        final novoUsuario = usuario.copyWith(id: docRef.id);
        _items.insert(0, novoUsuario);
      } else {
        // Usuário existente - atualiza no Firestore
        await _usuariosCollection.doc(usuario.id).update(usuarioMap);

        // Atualiza na lista local
        final index = _items.indexWhere((item) => item.id == usuario.id);
        if (index >= 0) {
          _items[index] = usuario;
        }
      }

      // Atualiza o total
      await _updateTotalCount();

      notifyListeners();
    } catch (error) {
      print('Erro ao salvar usuário no Firebase: $error');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteItem(Usuario usuario) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Remove do Firestore
      await _usuariosCollection.doc(usuario.id).delete();

      // Remove da lista local
      _items.removeWhere((item) => item.id == usuario.id);

      // Atualiza o total
      await _updateTotalCount();

      notifyListeners();
    } catch (error) {
      print('Erro ao excluir usuário do Firebase: $error');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleUserStatus(Usuario usuario) async {
    try {
      final updatedUser = usuario.copyWith(
        ativo: !usuario.ativo,
        dataAtualizacao: DateTime.now(),
      );
      await saveItem(updatedUser);
    } catch (error) {
      print('Erro ao alternar status do usuário: $error');
      rethrow;
    }
  }

  // Busca usuários por termo (para a funcionalidade de search)
  Future<List<Usuario>> searchUsuarios(String searchTerm) async {
    if (searchTerm.isEmpty) return _items;

    try {
      final query = _usuariosCollection
          .where('nome', isGreaterThanOrEqualTo: searchTerm)
          .where('nome', isLessThan: searchTerm + 'z')
          .limit(20);

      final querySnapshot = await query.get();
      return await _convertDocsToUsuarios(querySnapshot.docs);
    } catch (error) {
      print('Erro na busca de usuários: $error');
      return [];
    }
  }

  // Busca usuário por ID específico
  Future<Usuario?> getUsuarioById(String id) async {
    try {
      final doc = await _usuariosCollection.doc(id).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return Usuario.fromMap({...data, 'id': doc.id});
      }
      return null;
    } catch (error) {
      print('Erro ao buscar usuário por ID: $error');
      return null;
    }
  }

  // Filtro local (para quando já temos os dados carregados)
  List<Usuario> filterUsuarios(String query) {
    if (query.isEmpty) return _items;

    final lowercaseQuery = query.toLowerCase();
    return _items
        .where(
          (usuario) =>
              usuario.nome.toLowerCase().contains(lowercaseQuery) ||
              usuario.email.toLowerCase().contains(lowercaseQuery) ||
              usuario.perfil.nome.toLowerCase().contains(lowercaseQuery) ||
              (usuario.telefone?.toLowerCase().contains(lowercaseQuery) ??
                  false),
        )
        .toList();
  }

  // Atualiza último acesso do usuário
  Future<void> updateLastAccess(String userId) async {
    try {
      await _usuariosCollection.doc(userId).update({
        'ultimoAcesso': DateTime.now().millisecondsSinceEpoch,
      });

      // Atualiza localmente também
      final index = _items.indexWhere((user) => user.id == userId);
      if (index >= 0) {
        _items[index] = _items[index].copyWith(ultimoAcesso: DateTime.now());
        notifyListeners();
      }
    } catch (error) {
      print('Erro ao atualizar último acesso: $error');
    }
  }

  // Carrega mais dados (para paginação)
  Future<void> loadMore() async {
    if (!_isLoading && _hasMoreItems) {
      await loadItems();
    }
  }

  // Reseta a lista
  void reset() {
    _currentPage = 0;
    _items.clear();
    _hasMoreItems = true;
    _totalItems = 0;
    _lastDocument = null;
    notifyListeners();
  }
}

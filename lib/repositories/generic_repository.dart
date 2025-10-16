// repositories/generic_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/base_model.dart';

class GenericRepository<T extends BaseModel> {
  final CollectionReference collection;
  final T Function(Map<String, dynamic>, String) fromMap;

  GenericRepository({required String collectionName, required this.fromMap})
    : collection = FirebaseFirestore.instance.collection(collectionName);

  // Busca com paginação e filtros
  Future<List<T>> search({
    required int limit,
    String? lastDocumentId,
    String? searchTerm,
    Map<String, dynamic> filters = const {},
    String orderBy = 'createdAt',
    bool descending = true,
  }) async {
    Query query = collection;

    // Aplica filtros
    filters.forEach((key, value) {
      if (value != null) {
        query = query.where(key, isEqualTo: value);
      }
    });

    // Aplica busca textual se houver termo
    if (searchTerm != null && searchTerm.isNotEmpty) {
      query = query.where(
        'searchable',
        arrayContains: searchTerm.toLowerCase(),
      );
    }

    // Ordenação
    query = query.orderBy(orderBy, descending: descending).limit(limit);

    // Paginação
    if (lastDocumentId != null) {
      final lastDoc = await collection.doc(lastDocumentId).get();
      query = query.startAfterDocument(lastDoc);
    }

    final querySnapshot = await query.get();

    return querySnapshot.docs.map((doc) {
      return fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }).toList();
  }

  // Contador para paginação
  Future<int?> getCount({Map<String, dynamic> filters = const {}}) async {
    Query query = collection;

    filters.forEach((key, value) {
      if (value != null) {
        query = query.where(key, isEqualTo: value);
      }
    });

    final querySnapshot = await query.count().get();
    return querySnapshot.count;
  }
}

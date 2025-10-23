// core/models/paginated_response.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class PaginatedResponse<T> {
  final List<T> items;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final bool hasNextPage;

  // ✅ NOVOS CAMPOS PARA PAGINAÇÃO BASEADA EM CURSOR
  final DocumentSnapshot? lastDocument;
  final bool hasPreviousPage;

  PaginatedResponse({
    required this.items,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.hasNextPage,

    // ✅ NOVOS PARÂMETROS (opcionais para compatibilidade)
    this.lastDocument,
    this.hasPreviousPage = false,
  });

  // ✅ CONSTRUTOR PARA PAGINAÇÃO BASEADA EM CURSOR
  factory PaginatedResponse.cursorBased({
    required List<T> items,
    required bool hasNextPage,
    DocumentSnapshot? lastDocument,
    bool hasPreviousPage = false,
  }) {
    return PaginatedResponse<T>(
      items: items,
      currentPage: 0, // Não aplicável em cursor-based
      totalPages: 0, // Não aplicável em cursor-based
      totalItems: 0, // Não aplicável em cursor-based
      hasNextPage: hasNextPage,
      lastDocument: lastDocument,
      hasPreviousPage: hasPreviousPage,
    );
  }

  // ✅ MÉTODO PARA CONVERSÃO DE/PARA JSON
  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    return PaginatedResponse<T>(
      items: (json['items'] as List).map((item) => fromJson(item)).toList(),
      currentPage: json['currentPage'] ?? 1,
      totalPages: json['totalPages'] ?? 1,
      totalItems: json['totalItems'] ?? 0,
      hasNextPage: json['hasNextPage'] ?? false,
      hasPreviousPage: json['hasPreviousPage'] ?? false,
    );
  }

  Map<String, dynamic> toJson(Map<String, dynamic> Function(T) toJson) {
    return {
      'items': items.map((item) => toJson(item)).toList(),
      'currentPage': currentPage,
      'totalPages': totalPages,
      'totalItems': totalItems,
      'hasNextPage': hasNextPage,
      'hasPreviousPage': hasPreviousPage,
    };
  }

  // ✅ MÉTODOS ÚTEIS
  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;
  int get count => items.length;

  // ✅ MÉTODO PARA VERIFICAR SE É PAGINAÇÃO BASEADA EM CURSOR
  bool get isCursorBased => lastDocument != null;

  // ✅ MÉTODO PARA VERIFICAR SE É PAGINAÇÃO NUMÉRICA
  bool get isNumericBased => totalPages > 0 && totalItems > 0;

  @override
  String toString() {
    if (isCursorBased) {
      return 'PaginatedResponse(cursor-based, items: ${items.length}, hasNext: $hasNextPage, hasPrevious: $hasPreviousPage)';
    } else {
      return 'PaginatedResponse(numeric, page: $currentPage/$totalPages, items: ${items.length}/$totalItems, hasNext: $hasNextPage)';
    }
  }
}

// controllers/generic_search_controller.dart
import 'package:flutter/foundation.dart';
import '../models/base_model.dart';
import '../repositories/generic_repository.dart';

class GenericSearchController<T extends BaseModel> extends ChangeNotifier {
  final GenericRepository<T> repository;

  List<T> _items = [];
  bool _isLoading = false;
  bool _hasMore = true;
  String? _lastDocumentId;
  String _searchTerm = '';
  Map<String, dynamic> _filters = {};
  String _orderBy = 'createdAt';
  bool _descending = true;
  int _limit = 20;

  GenericSearchController({required this.repository});

  // Getters
  List<T> get items => _items;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String get searchTerm => _searchTerm;
  Map<String, dynamic> get filters => _filters;

  // Busca inicial
  Future<void> initialSearch() async {
    _resetPagination();
    await _performSearch();
  }

  // Busca com termo
  Future<void> search(String term) async {
    _searchTerm = term;
    _resetPagination();
    await _performSearch();
  }

  // Aplicar filtros
  Future<void> applyFilters(Map<String, dynamic> newFilters) async {
    _filters = {..._filters, ...newFilters};
    _resetPagination();
    await _performSearch();
  }

  // Limpar filtros
  Future<void> clearFilters() async {
    _filters.clear();
    _resetPagination();
    await _performSearch();
  }

  // Carregar mais dados (paginação)
  Future<void> loadMore() async {
    if (_isLoading || !_hasMore) return;

    await _performSearch(loadMore: true);
  }

  // Busca principal
  Future<void> _performSearch({bool loadMore = false}) async {
    if (_isLoading) return;

    _isLoading = true;
    if (!loadMore) notifyListeners();

    try {
      final results = await repository.search(
        limit: _limit,
        lastDocumentId: loadMore ? _lastDocumentId : null,
        searchTerm: _searchTerm.isEmpty ? null : _searchTerm,
        filters: _filters,
        orderBy: _orderBy,
        descending: _descending,
      );

      if (loadMore) {
        _items.addAll(results);
      } else {
        _items = results;
      }

      // Atualiza paginação
      _hasMore = results.length == _limit;
      if (results.isNotEmpty) {
        _lastDocumentId = results.last.id;
      }
    } catch (e) {
      print('Erro na busca: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _resetPagination() {
    _items.clear();
    _lastDocumentId = null;
    _hasMore = true;
  }

  // Atualizar ordenação
  Future<void> updateSorting(String field, {bool descending = true}) async {
    _orderBy = field;
    _descending = descending;
    _resetPagination();
    await _performSearch();
  }

  // Disposer
  @override
  void dispose() {
    super.dispose();
  }
}

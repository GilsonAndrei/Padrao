// core/controllers/base_search_controller.dart
import 'package:flutter/material.dart';
import 'package:projeto_padrao/models/paginated_response.dart';

abstract class BaseSearchController<T> extends ChangeNotifier {
  List<T> _items = [];
  List<T> get items => _items;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  String _searchTerm = '';
  String get searchTerm => _searchTerm;

  int _currentPage = 1;
  int get currentPage => _currentPage;

  int _totalItems = 0;
  int get totalItems => _totalItems;

  bool _hasMore = true;
  bool get hasMore => _hasMore;

  // Método abstrato que deve ser implementado
  Future<PaginatedResponse<T>> searchItems({
    required String searchTerm,
    required int page,
    int pageSize = 20,
  });

  // Busca inicial
  Future<void> performSearch(String searchTerm, {bool reset = true}) async {
    if (reset) {
      _currentPage = 1;
      _hasMore = true;
      _items.clear();
    }

    _searchTerm = searchTerm;
    _isLoading = true;
    notifyListeners();

    try {
      final response = await searchItems(
        searchTerm: searchTerm,
        page: _currentPage,
      );

      if (reset) {
        _items = response.items;
      } else {
        _items.addAll(response.items);
      }

      _hasMore = response.hasNextPage;
      _totalItems = response.totalItems;
      _currentPage++;
    } catch (error) {
      // Tratar erro
      print('Erro na busca: $error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Carregar mais itens (infinite scroll)
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore || _searchTerm.isEmpty) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final response = await searchItems(
        searchTerm: _searchTerm,
        page: _currentPage,
      );

      _items.addAll(response.items);
      _hasMore = response.hasNextPage;
      _totalItems = response.totalItems;
      _currentPage++;
    } catch (error) {
      print('Erro ao carregar mais: $error');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // Limpar busca
  void clearSearch() {
    _searchTerm = '';
    _items.clear();
    _currentPage = 1;
    _hasMore = true;
    _totalItems = 0;
    notifyListeners();
  }

  // Atualizar um item na lista
  void updateItem(T oldItem, T newItem) {
    final index = _items.indexWhere((item) => item == oldItem);
    if (index != -1) {
      _items[index] = newItem;
      notifyListeners();
    }
  }

  // Remover um item da lista
  void removeItem(T item) {
    _items.remove(item);
    _totalItems--;
    notifyListeners();
  }
}

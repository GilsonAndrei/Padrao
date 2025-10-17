// core/controllers/base_controller.dart
import 'package:flutter/material.dart';

abstract class BaseController<T> with ChangeNotifier {
  bool _isLoading = false;
  List<T> _items = [];
  T? _selectedItem;

  bool get isLoading => _isLoading;
  List<T> get items => _items;
  T? get selectedItem => _selectedItem;

  set isLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  set items(List<T> value) {
    _items = value;
    notifyListeners();
  }

  set selectedItem(T? value) {
    _selectedItem = value;
    notifyListeners();
  }

  // ✅ CORREÇÃO: Adicione o parâmetro reset opcional
  Future<void> loadItems({bool reset = false});

  Future<bool> saveItem(T item);
  Future<bool> deleteItem(T item);

  // Métodos utilitários
  void addItem(T item) {
    _items.add(item);
    notifyListeners();
  }

  void removeItem(T item) {
    _items.remove(item);
    notifyListeners();
  }

  void updateItem(T oldItem, T newItem) {
    final index = _items.indexOf(oldItem);
    if (index != -1) {
      _items[index] = newItem;
      notifyListeners();
    }
  }

  void clearItems() {
    _items.clear();
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Método para mostrar mensagens de erro/sucesso
  void showMessage(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }
}

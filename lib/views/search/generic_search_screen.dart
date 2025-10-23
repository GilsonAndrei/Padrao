// core/views/generic_search_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:projeto_padrao/controllers/search/base_search_controller.dart';
import 'package:projeto_padrao/core/themes/app_colors.dart';
import 'package:provider/provider.dart';

class GenericSearchScreen<T> extends StatefulWidget {
  final BaseSearchController<T> controller;
  final String title;
  final String searchHint;
  final Widget Function(T) itemBuilder;
  final Widget Function()? emptyStateBuilder;
  final Widget Function()? loadingStateBuilder;
  final void Function(T)? onItemSelected;
  final bool enableSelection;
  final Widget? floatingActionButton;
  final bool isModal; // ✅ Indica se é um modal
  final bool showAppBar; // ✅ NOVO: Controla se mostra o AppBar

  const GenericSearchScreen({
    super.key,
    required this.controller,
    required this.title,
    required this.searchHint,
    required this.itemBuilder,
    this.emptyStateBuilder,
    this.loadingStateBuilder,
    this.onItemSelected,
    this.enableSelection = false,
    this.floatingActionButton,
    this.isModal = false,
    this.showAppBar = true, // ✅ NOVO: Padrão é true
  });

  @override
  State<GenericSearchScreen<T>> createState() => _GenericSearchScreenState<T>();
}

class _GenericSearchScreenState<T> extends State<GenericSearchScreen<T>> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _debounce = Debounce(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);

    // Busca inicial se necessário
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.performSearch('');
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      widget.controller.loadMore();
    }
  }

  void _onSearchChanged() {
    _debounce.run(() {
      widget.controller.performSearch(_searchController.text.trim());
    });
  }

  void _clearSearch() {
    _searchController.clear();
    widget.controller.clearSearch();
  }

  void _handleItemSelected(T item) {
    widget.onItemSelected?.call(item);

    if (widget.isModal) {
      Navigator.of(context).pop(item);
    } else {
      Navigator.of(context).pop(item);
    }
  }

  void _handleBack() {
    if (widget.isModal) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.controller,
      child: Scaffold(
        // ✅ CORREÇÃO: AppBar condicional
        appBar: widget.showAppBar
            ? AppBar(
                title: Text(widget.title),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _handleBack,
                ),
              )
            : null,
        body: Column(
          children: [
            // ✅ CORREÇÃO: Título condicional quando não tem AppBar
            if (!widget.showAppBar) ...[
              Container(
                padding: const EdgeInsets.all(16),
                color: AppColors.primary,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: _handleBack,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Campo de busca
            _buildSearchField(),
            // Resultados
            Expanded(
              child: Consumer<BaseSearchController<T>>(
                builder: (context, controller, child) {
                  if (controller.isLoading && controller.items.isEmpty) {
                    return widget.loadingStateBuilder?.call() ??
                        _buildDefaultLoading();
                  }

                  if (controller.items.isEmpty &&
                      controller.searchTerm.isEmpty) {
                    return widget.emptyStateBuilder?.call() ??
                        _buildDefaultEmptyState();
                  }

                  if (controller.items.isEmpty) {
                    return _buildNoResults();
                  }

                  return _buildResultsList(controller);
                },
              ),
            ),
          ],
        ),
        floatingActionButton: widget.floatingActionButton,
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: widget.searchHint,
          prefixIcon: Icon(Icons.search, color: AppColors.primary),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: AppColors.textSecondary),
                  onPressed: _clearSearch,
                )
              : null,
          filled: true,
          fillColor: AppColors.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildResultsList(BaseSearchController<T> controller) {
    return Column(
      children: [
        // Contador de resultados
        if (controller.searchTerm.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${controller.totalItems} resultado(s) encontrado(s)',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        // Lista de itens
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: controller.items.length + (controller.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= controller.items.length) {
                return _buildLoadMoreIndicator();
              }

              final item = controller.items[index];
              return widget.enableSelection
                  ? _buildSelectableItem(item, index)
                  : _buildStandardItem(item, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSelectableItem(T item, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => _handleItemSelected(item),
        title: widget.itemBuilder(item),
      ),
    );
  }

  Widget _buildStandardItem(T item, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: widget.itemBuilder(item),
    );
  }

  Widget _buildLoadMoreIndicator() {
    return Consumer<BaseSearchController<T>>(
      builder: (context, controller, child) {
        if (!controller.isLoadingMore) return const SizedBox();
        return const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  Widget _buildDefaultLoading() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildDefaultEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 64, color: AppColors.textDisabled),
          const SizedBox(height: 16),
          Text(
            'Nenhum item cadastrado',
            style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: AppColors.textDisabled),
          const SizedBox(height: 16),
          Text(
            'Nenhum resultado encontrado',
            style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Tente alterar os termos da busca',
            style: TextStyle(fontSize: 14, color: AppColors.textDisabled),
          ),
        ],
      ),
    );
  }
}

// Helper para debounce
class Debounce {
  final int milliseconds;
  Timer? _timer;

  Debounce({required this.milliseconds});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void dispose() {
    _timer?.cancel();
  }
}

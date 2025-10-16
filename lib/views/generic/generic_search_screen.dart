// views/generic_search_screen.dart
import 'package:flutter/material.dart';
import 'package:projeto_padrao/controllers/generic_search_controller.dart';
import 'package:projeto_padrao/models/base_model.dart';

typedef ItemBuilder<T> = Widget Function(BuildContext context, T item);
typedef FilterBuilder =
    Widget Function(
      BuildContext context,
      Function(Map<String, dynamic>) onFiltersApplied,
    );

class GenericSearchScreen<T extends BaseModel> extends StatefulWidget {
  final GenericSearchController<T> controller;
  final ItemBuilder<T> itemBuilder;
  final String title;
  final FilterBuilder? filterBuilder;
  final Widget? floatingActionButton;
  final bool showSearchField;

  const GenericSearchScreen({
    Key? key,
    required this.controller,
    required this.itemBuilder,
    required this.title,
    this.filterBuilder,
    this.floatingActionButton,
    this.showSearchField = true,
  }) : super(key: key);

  @override
  State<GenericSearchScreen<T>> createState() => _GenericSearchScreenState<T>();
}

class _GenericSearchScreenState<T extends BaseModel>
    extends State<GenericSearchScreen<T>> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    widget.controller.initialSearch();
    _searchController.text = widget.controller.searchTerm;
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      widget.controller.loadMore();
    }
  }

  void _onSearch(String term) {
    widget.controller.search(term);
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filtros',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            if (widget.filterBuilder != null)
              widget.filterBuilder!(context, (filters) {
                widget.controller.applyFilters(filters);
                Navigator.pop(context);
              }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (widget.filterBuilder != null)
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterDialog,
            ),
        ],
      ),
      body: Column(
        children: [
          // Campo de busca
          if (widget.showSearchField)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _onSearch('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  // Debounce seria ideal aqui
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (_searchController.text == value) {
                      _onSearch(value);
                    }
                  });
                },
              ),
            ),
          // Lista de resultados
          Expanded(
            child: AnimatedBuilder(
              animation: widget.controller,
              builder: (context, child) {
                if (widget.controller.items.isEmpty &&
                    !widget.controller.isLoading) {
                  return const Center(
                    child: Text('Nenhum resultado encontrado'),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => widget.controller.initialSearch(),
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: widget.controller.items.length + 1,
                    itemBuilder: (context, index) {
                      if (index < widget.controller.items.length) {
                        return widget.itemBuilder(
                          context,
                          widget.controller.items[index],
                        );
                      } else if (widget.controller.hasMore) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      } else if (widget.controller.items.isNotEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: Text('Fim dos resultados')),
                        );
                      } else {
                        return const SizedBox.shrink();
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: widget.floatingActionButton,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}

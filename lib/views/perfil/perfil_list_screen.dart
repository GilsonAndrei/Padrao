import 'package:flutter/material.dart';
import 'package:projeto_padrao/controllers/perfil/perfil_controller.dart';
import 'package:projeto_padrao/views/perfil/perfil_form_screen.dart';
import 'package:provider/provider.dart';
import 'package:projeto_padrao/models/perfil_usuario.dart';
import 'package:projeto_padrao/core/themes/app_colors.dart';
import 'package:projeto_padrao/core/themes/app_theme.dart';
import 'package:projeto_padrao/core/responsive/responsive_layout.dart';
import 'package:projeto_padrao/core/responsive/responsive_utils.dart';
import 'package:projeto_padrao/core/responsive/breakpoints.dart';

class PerfilListScreen extends StatefulWidget {
  const PerfilListScreen({super.key});

  @override
  State<PerfilListScreen> createState() => _PerfilListScreenState();
}

class _PerfilListScreenState extends State<PerfilListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadPerfis();
    _setupScrollListener();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 100) {
        _loadMorePerfis();
      }
    });
  }

  void _loadPerfis() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<PerfilController>(context, listen: false);
      controller.loadItems(reset: true);
    });
  }

  void _loadMorePerfis() {
    final controller = Provider.of<PerfilController>(context, listen: false);

    if (!_isLoadingMore &&
        controller.hasMoreItems &&
        !controller.isLoading &&
        _searchQuery.isEmpty) {
      setState(() => _isLoadingMore = true);

      controller
          .loadItems()
          .then((_) {
            setState(() => _isLoadingMore = false);
          })
          .catchError((_) {
            setState(() => _isLoadingMore = false);
          });
    }
  }

  List<PerfilUsuario> _filterPerfis(List<PerfilUsuario> perfis) {
    if (_searchQuery.isEmpty) return perfis;

    return perfis
        .where(
          (perfil) =>
              perfil.nome.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              perfil.descricao.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ),
        )
        .toList();
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value);

    if (value.isEmpty) {
      _loadPerfis();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTheme.createGradientAppBar(
        title: 'Gerenciar Perfis',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPerfis,
            tooltip: 'Atualizar lista',
          ),
        ],
      ),
      body: Consumer<PerfilController>(
        builder: (context, controller, child) {
          final filteredPerfis = _filterPerfis(controller.items);

          if (controller.isLoading && controller.items.isEmpty) {
            return _buildLoadingState();
          }

          return ResponsiveLayout(
            mobile: _buildMobileLayout(context, controller, filteredPerfis),
            tablet: _buildTabletLayout(context, controller, filteredPerfis),
            desktop: _buildDesktopLayout(context, controller, filteredPerfis),
          );
        },
      ),
      floatingActionButton: ResponsiveValue<double>(
        mobile: 16.0,
        tablet: 24.0,
        desktop: 32.0,
        builder: (padding) => Padding(
          padding: EdgeInsets.all(padding),
          child: FloatingActionButton.extended(
            onPressed: () => _navigateToForm(context, null),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 4,
            icon: const Icon(Icons.add),
            label: const Text('Novo Perfil'),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    PerfilController controller,
    List<PerfilUsuario> filteredPerfis,
  ) {
    return Column(
      children: [
        _buildHeader(context, controller, filteredPerfis),
        Expanded(
          child: filteredPerfis.isEmpty
              ? _buildEmptyState(_searchQuery.isNotEmpty)
              : _buildPerfilList(context, controller, filteredPerfis),
        ),
      ],
    );
  }

  Widget _buildTabletLayout(
    BuildContext context,
    PerfilController controller,
    List<PerfilUsuario> filteredPerfis,
  ) {
    return Padding(
      padding: ResponsiveUtils.getResponsiveScreenPadding(context),
      child: Column(
        children: [
          _buildHeader(context, controller, filteredPerfis),
          const SizedBox(height: 16),
          Expanded(
            child: filteredPerfis.isEmpty
                ? _buildEmptyState(_searchQuery.isNotEmpty)
                : _buildPerfilGrid(context, controller, filteredPerfis, 2),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    PerfilController controller,
    List<PerfilUsuario> filteredPerfis,
  ) {
    return Padding(
      padding: ResponsiveUtils.getResponsiveScreenPadding(context),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDesktopSidebar(context, controller),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              children: [
                _buildDesktopHeader(context, controller, filteredPerfis),
                const SizedBox(height: 16),
                Expanded(
                  child: filteredPerfis.isEmpty
                      ? _buildEmptyState(_searchQuery.isNotEmpty)
                      : _buildPerfilGrid(
                          context,
                          controller,
                          filteredPerfis,
                          3,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopSidebar(
    BuildContext context,
    PerfilController controller,
  ) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estatísticas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          _buildStatItem(
            'Total de Perfis',
            '${controller.totalItems}',
            Icons.manage_accounts,
            AppColors.primary,
          ),
          const SizedBox(height: 16),
          _buildStatItem(
            'Perfis Ativos',
            '${controller.items.where((p) => p.ativo).length}',
            Icons.check_circle,
            AppColors.success,
          ),
          const SizedBox(height: 16),
          _buildStatItem(
            'Permissões Média',
            '${_calculateAveragePermissions(controller.items)}',
            Icons.security,
            AppColors.info,
          ),
          const Spacer(),
          if (controller.hasMoreItems && !_searchQuery.isNotEmpty)
            _buildPaginationInfo(context),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                title,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _calculateAveragePermissions(List<PerfilUsuario> perfis) {
    if (perfis.isEmpty) return '0';
    final total = perfis.fold(
      0,
      (sum, perfil) => sum + perfil.permissoes.length,
    );
    return (total / perfis.length).toStringAsFixed(1);
  }

  Widget _buildDesktopHeader(
    BuildContext context,
    PerfilController controller,
    List<PerfilUsuario> filteredPerfis,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar por nome ou descrição...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '${filteredPerfis.length} perfil(s)',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Carregando perfis...',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    PerfilController controller,
    List<PerfilUsuario> filteredPerfis,
  ) {
    return Container(
      padding: ResponsiveUtils.getResponsivePaddingAll(context),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar por nome ou descrição...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onChanged: _onSearchChanged,
          ),
          const SizedBox(height: 12),
          ResponsiveLayout(
            mobile: _buildMobileStats(controller, filteredPerfis),
            tablet: _buildTabletStats(controller, filteredPerfis),
          ),
          if (controller.hasMoreItems && !_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildPaginationInfo(context),
          ],
        ],
      ),
    );
  }

  Widget _buildMobileStats(
    PerfilController controller,
    List<PerfilUsuario> filteredPerfis,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildStatCard(
            'Total',
            '${controller.totalItems}',
            Icons.manage_accounts,
            AppColors.primary,
          ),
          const SizedBox(width: 8),
          _buildStatCard(
            'Ativos',
            '${controller.items.where((p) => p.ativo).length}',
            Icons.check_circle,
            AppColors.success,
          ),
          const SizedBox(width: 8),
          _buildStatCard(
            'Filtrados',
            '${filteredPerfis.length}',
            Icons.filter_list,
            AppColors.secondary,
          ),
        ],
      ),
    );
  }

  Widget _buildTabletStats(
    PerfilController controller,
    List<PerfilUsuario> filteredPerfis,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatCard(
          'Total',
          '${controller.totalItems}',
          Icons.manage_accounts,
          AppColors.primary,
        ),
        _buildStatCard(
          'Ativos',
          '${controller.items.where((p) => p.ativo).length}',
          Icons.check_circle,
          AppColors.success,
        ),
        _buildStatCard(
          'Filtrados',
          '${filteredPerfis.length}',
          Icons.filter_list,
          AppColors.secondary,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return ResponsiveValue<double>(
      mobile: 100,
      tablet: 120,
      desktop: 140,
      builder: (width) => Container(
        width: width,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationInfo(BuildContext context) {
    final controller = Provider.of<PerfilController>(context, listen: false);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.info_outline, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          '${controller.items.length} de ${controller.totalItems} perfis carregados',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        if (_isLoadingMore) ...[
          const SizedBox(width: 8),
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState(bool isSearching) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearching ? Icons.search_off : Icons.manage_accounts_outlined,
            size: 80,
            color: AppColors.textDisabled,
          ),
          const SizedBox(height: 16),
          Text(
            isSearching
                ? 'Nenhum perfil encontrado'
                : 'Nenhum perfil cadastrado',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSearching
                ? 'Tente ajustar os termos da busca'
                : 'Clique no botão abaixo para criar o primeiro perfil',
            style: TextStyle(color: AppColors.textDisabled, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPerfilList(
    BuildContext context,
    PerfilController controller,
    List<PerfilUsuario> perfis,
  ) {
    return Padding(
      padding: ResponsiveUtils.getResponsivePaddingAll(context),
      child: ListView.separated(
        controller: _scrollController,
        itemCount: perfis.length + (_isLoadingMore ? 1 : 0),
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == perfis.length && _isLoadingMore) {
            return _buildLoadingItem();
          }

          final perfil = perfis[index];
          return _buildPerfilCard(context, perfil, controller);
        },
      ),
    );
  }

  Widget _buildPerfilGrid(
    BuildContext context,
    PerfilController controller,
    List<PerfilUsuario> perfis,
    int crossAxisCount,
  ) {
    return Padding(
      padding: ResponsiveUtils.getResponsivePaddingAll(context),
      child: GridView.builder(
        controller: _scrollController,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.4,
        ),
        itemCount: perfis.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == perfis.length && _isLoadingMore) {
            return _buildLoadingItem();
          }
          final perfil = perfis[index];
          return _buildPerfilCard(context, perfil, controller);
        },
      ),
    );
  }

  Widget _buildLoadingItem() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Carregando mais perfis...',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerfilCard(
    BuildContext context,
    PerfilUsuario perfil,
    PerfilController controller,
  ) {
    return ResponsiveLayout(
      mobile: _buildMobilePerfilCard(context, perfil, controller),
      tablet: _buildTabletPerfilCard(context, perfil, controller),
      desktop: _buildDesktopPerfilCard(context, perfil, controller),
    );
  }

  Widget _buildMobilePerfilCard(
    BuildContext context,
    PerfilUsuario perfil,
    PerfilController controller,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _navigateToForm(context, perfil),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildPerfilAvatar(perfil),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      perfil.nome,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      perfil.descricao,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    _buildPerfilBadges(perfil),
                  ],
                ),
              ),
              _buildActionMenu(context, perfil, controller),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabletPerfilCard(
    BuildContext context,
    PerfilUsuario perfil,
    PerfilController controller,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _navigateToForm(context, perfil),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildPerfilAvatar(perfil),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          perfil.nome,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          perfil.descricao,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildActionMenu(context, perfil, controller),
                ],
              ),
              const SizedBox(height: 12),
              _buildPerfilBadges(perfil),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopPerfilCard(
    BuildContext context,
    PerfilUsuario perfil,
    PerfilController controller,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _navigateToForm(context, perfil),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              _buildPerfilAvatar(perfil),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      perfil.nome,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      perfil.descricao,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(child: _buildPerfilBadges(perfil)),
              _buildActionMenu(context, perfil, controller),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPerfilAvatar(PerfilUsuario perfil) {
    return ResponsiveValue<double>(
      mobile: 48,
      tablet: 56,
      desktop: 64,
      builder: (size) => Stack(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
              border: Border.all(
                color: perfil.ativo
                    ? AppColors.success.withOpacity(0.5)
                    : AppColors.error.withOpacity(0.5),
                width: 2,
              ),
            ),
            child: Icon(
              _getPerfilIcon(perfil.nome),
              color: Colors.white,
              size: size * 0.4,
            ),
          ),
          if (!perfil.ativo)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.block,
                  color: AppColors.error,
                  size: size * 0.25,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPerfilBadges(PerfilUsuario perfil) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        _buildStatusBadge(
          perfil.ativo ? 'Ativo' : 'Inativo',
          perfil.ativo ? AppColors.success : AppColors.error,
        ),
        _buildStatusBadge(
          '${perfil.permissoes.length} permissões',
          AppColors.info,
          icon: Icons.security,
        ),
        _buildStatusBadge(
          'Criado ${_formatDate(perfil.dataCriacao)}',
          AppColors.secondary,
          icon: Icons.calendar_today,
        ),
        if (perfil.dataAtualizacao != null)
          _buildStatusBadge(
            'Atualizado ${_formatDate(perfil.dataAtualizacao!)}',
            AppColors.warning,
            icon: Icons.update,
          ),
      ],
    );
  }

  IconData _getPerfilIcon(String nome) {
    final lowerNome = nome.toLowerCase();
    if (lowerNome.contains('admin')) return Icons.admin_panel_settings;
    if (lowerNome.contains('gerente')) return Icons.manage_accounts;
    if (lowerNome.contains('user')) return Icons.person;
    if (lowerNome.contains('moderador')) return Icons.shield;
    return Icons.manage_accounts;
  }

  Widget _buildStatusBadge(String text, Color color, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) Icon(icon, size: 12, color: color),
          if (icon != null) const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionMenu(
    BuildContext context,
    PerfilUsuario perfil,
    PerfilController controller,
  ) {
    return PopupMenuButton<String>(
      onSelected: (value) =>
          _handleMenuAction(context, value, perfil, controller),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text('Editar'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'toggle_status',
          child: Row(
            children: [
              Icon(
                perfil.ativo ? Icons.block : Icons.check_circle,
                size: 20,
                color: perfil.ativo ? AppColors.warning : AppColors.success,
              ),
              const SizedBox(width: 8),
              Text(perfil.ativo ? 'Inativar' : 'Ativar'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 20, color: AppColors.error),
              const SizedBox(width: 8),
              Text('Excluir', style: TextStyle(color: AppColors.error)),
            ],
          ),
        ),
      ],
    );
  }

  void _navigateToForm(BuildContext context, PerfilUsuario? perfil) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => PerfilFormScreen(perfil: perfil),
          ),
        )
        .then((_) => _loadPerfis());
  }

  void _handleMenuAction(
    BuildContext context,
    String action,
    PerfilUsuario perfil,
    PerfilController controller,
  ) {
    switch (action) {
      case 'edit':
        _navigateToForm(context, perfil);
        break;
      case 'toggle_status':
        _togglePerfilStatus(context, perfil, controller);
        break;
      case 'delete':
        _deletePerfil(context, perfil, controller);
        break;
    }
  }

  void _togglePerfilStatus(
    BuildContext context,
    PerfilUsuario perfil,
    PerfilController controller,
  ) {
    final novoPerfil = perfil.copyWith(ativo: !perfil.ativo);
    controller.saveItem(novoPerfil);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Perfil ${novoPerfil.ativo ? 'ativado' : 'inativado'} com sucesso',
        ),
        backgroundColor: novoPerfil.ativo
            ? AppColors.success
            : AppColors.warning,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _deletePerfil(
    BuildContext context,
    PerfilUsuario perfil,
    PerfilController controller,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 48,
              color: AppColors.warning,
            ),
            const SizedBox(height: 16),
            Text(
              'Tem certeza que deseja excluir o perfil "${perfil.nome}"?',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Esta ação não pode ser desfeita.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              controller.deleteItem(perfil);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Perfil "${perfil.nome}" excluído com sucesso'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) return 'hoje';
    if (difference.inDays == 1) return 'ontem';
    if (difference.inDays < 7) return 'há ${difference.inDays}d';
    if (difference.inDays < 30)
      return 'há ${(difference.inDays / 7).floor()}sem';
    return 'há ${(difference.inDays / 30).floor()}mes';
  }
}

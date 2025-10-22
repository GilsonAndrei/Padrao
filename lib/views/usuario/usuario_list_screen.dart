import 'package:flutter/material.dart';
import 'package:projeto_padrao/controllers/usuario/usuario_controller.dart';
import 'package:projeto_padrao/core/themes/app_theme.dart';
import 'package:projeto_padrao/views/usuario/usuario_form_screen.dart';
import 'package:provider/provider.dart';
import 'package:projeto_padrao/models/usuario.dart';
import 'package:projeto_padrao/core/themes/app_colors.dart';
import 'package:projeto_padrao/core/responsive/responsive_layout.dart';
import 'package:projeto_padrao/core/responsive/responsive_utils.dart';
import 'package:projeto_padrao/core/responsive/breakpoints.dart';

class UsuarioListScreen extends StatefulWidget {
  const UsuarioListScreen({super.key});

  @override
  State<UsuarioListScreen> createState() => _UsuarioListScreenState();
}

class _UsuarioListScreenState extends State<UsuarioListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadUsuarios();
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
        _loadMoreUsuarios();
      }
    });
  }

  void _loadUsuarios() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<UsuarioController>(context, listen: false);
      controller.loadItems(reset: true);
    });
  }

  void _loadMoreUsuarios() {
    final controller = Provider.of<UsuarioController>(context, listen: false);

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

  List<Usuario> _filterUsers(List<Usuario> users) {
    if (_searchQuery.isEmpty) return users;

    return users
        .where(
          (user) =>
              user.nome.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              user.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              user.perfil.nome.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ),
        )
        .toList();
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value);
    if (value.isEmpty) {
      _loadUsuarios();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTheme.createGradientAppBar(
        title: 'Gerenciar Usuários',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsuarios,
            tooltip: 'Atualizar lista',
          ),
        ],
      ),
      body: Consumer<UsuarioController>(
        builder: (context, controller, child) {
          final filteredUsers = _filterUsers(controller.items);

          if (controller.isLoading && controller.items.isEmpty) {
            return _buildLoadingState();
          }

          return ResponsiveLayout(
            mobile: _buildMobileLayout(context, controller, filteredUsers),
            tablet: _buildTabletLayout(context, controller, filteredUsers),
            desktop: _buildDesktopLayout(context, controller, filteredUsers),
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
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Novo Usuário'),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    UsuarioController controller,
    List<Usuario> filteredUsers,
  ) {
    return Column(
      children: [
        _buildHeader(context, controller, filteredUsers),
        Expanded(
          child: filteredUsers.isEmpty
              ? _buildEmptyState(_searchQuery.isNotEmpty)
              : _buildUserList(context, controller, filteredUsers),
        ),
      ],
    );
  }

  Widget _buildTabletLayout(
    BuildContext context,
    UsuarioController controller,
    List<Usuario> filteredUsers,
  ) {
    return Padding(
      padding: ResponsiveUtils.getResponsiveScreenPadding(context),
      child: Column(
        children: [
          _buildHeader(context, controller, filteredUsers),
          const SizedBox(height: 16),
          Expanded(
            child: filteredUsers.isEmpty
                ? _buildEmptyState(_searchQuery.isNotEmpty)
                : _buildUserGrid(context, controller, filteredUsers, 2),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    UsuarioController controller,
    List<Usuario> filteredUsers,
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
                _buildDesktopHeader(context, controller, filteredUsers),
                const SizedBox(height: 16),
                Expanded(
                  child: filteredUsers.isEmpty
                      ? _buildEmptyState(_searchQuery.isNotEmpty)
                      : _buildUserGrid(context, controller, filteredUsers, 3),
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
    UsuarioController controller,
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
            'Total de Usuários',
            '${controller.totalItems}',
            Icons.people,
            AppColors.primary,
          ),
          const SizedBox(height: 16),
          _buildStatItem(
            'Usuários Ativos',
            '${controller.items.where((u) => u.ativo).length}',
            Icons.check_circle,
            AppColors.success,
          ),
          const SizedBox(height: 16),
          _buildStatItem(
            'Carregados',
            '${controller.items.length}',
            Icons.download_done,
            AppColors.secondary,
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

  Widget _buildDesktopHeader(
    BuildContext context,
    UsuarioController controller,
    List<Usuario> filteredUsers,
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
                    hintText: 'Buscar por nome, email ou perfil...',
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
                '${filteredUsers.length} usuário(s)',
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
            'Carregando usuários...',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    UsuarioController controller,
    List<Usuario> filteredUsers,
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
              hintText: 'Buscar por nome, email ou perfil...',
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
            mobile: _buildMobileStats(controller),
            tablet: _buildTabletStats(controller),
          ),
          if (controller.hasMoreItems && !_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildPaginationInfo(context),
          ],
        ],
      ),
    );
  }

  Widget _buildMobileStats(UsuarioController controller) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildStatCard(
            'Total',
            '${controller.totalItems}',
            Icons.people,
            AppColors.primary,
          ),
          const SizedBox(width: 8),
          _buildStatCard(
            'Ativos',
            '${controller.items.where((u) => u.ativo).length}',
            Icons.check_circle,
            AppColors.success,
          ),
          const SizedBox(width: 8),
          _buildStatCard(
            'Carregados',
            '${controller.items.length}',
            Icons.download_done,
            AppColors.secondary,
          ),
        ],
      ),
    );
  }

  Widget _buildTabletStats(UsuarioController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatCard(
          'Total',
          '${controller.totalItems}',
          Icons.people,
          AppColors.primary,
        ),
        _buildStatCard(
          'Ativos',
          '${controller.items.where((u) => u.ativo).length}',
          Icons.check_circle,
          AppColors.success,
        ),
        _buildStatCard(
          'Carregados',
          '${controller.items.length}',
          Icons.download_done,
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
    final controller = Provider.of<UsuarioController>(context, listen: false);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.info_outline, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          '${controller.items.length} de ${controller.totalItems} usuários carregados',
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
            isSearching ? Icons.search_off : Icons.people_outline,
            size: 80,
            color: AppColors.textDisabled,
          ),
          const SizedBox(height: 16),
          Text(
            isSearching
                ? 'Nenhum usuário encontrado'
                : 'Nenhum usuário cadastrado',
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
                : 'Clique no botão abaixo para adicionar o primeiro usuário',
            style: TextStyle(color: AppColors.textDisabled, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUserList(
    BuildContext context,
    UsuarioController controller,
    List<Usuario> users,
  ) {
    return Padding(
      padding: ResponsiveUtils.getResponsivePaddingAll(context),
      child: ListView.separated(
        controller: _scrollController,
        itemCount: users.length + (_isLoadingMore ? 1 : 0),
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == users.length && _isLoadingMore) {
            return _buildLoadingItem();
          }
          final usuario = users[index];
          return _buildUserCard(context, usuario, controller);
        },
      ),
    );
  }

  Widget _buildUserGrid(
    BuildContext context,
    UsuarioController controller,
    List<Usuario> users,
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
          childAspectRatio: 1.6,
        ),
        itemCount: users.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == users.length && _isLoadingMore) {
            return _buildLoadingItem();
          }
          final usuario = users[index];
          return _buildUserCard(context, usuario, controller);
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
              'Carregando mais usuários...',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(
    BuildContext context,
    Usuario usuario,
    UsuarioController controller,
  ) {
    return ResponsiveLayout(
      mobile: _buildMobileUserCard(context, usuario, controller),
      tablet: _buildTabletUserCard(context, usuario, controller),
      desktop: _buildDesktopUserCard(context, usuario, controller),
    );
  }

  Widget _buildMobileUserCard(
    BuildContext context,
    Usuario usuario,
    UsuarioController controller,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _navigateToForm(context, usuario),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildUserAvatar(usuario),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      usuario.nome,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      usuario.email,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    _buildUserBadges(usuario),
                  ],
                ),
              ),
              _buildActionMenu(context, usuario, controller),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabletUserCard(
    BuildContext context,
    Usuario usuario,
    UsuarioController controller,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _navigateToForm(context, usuario),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildUserAvatar(usuario),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          usuario.nome,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          usuario.email,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildActionMenu(context, usuario, controller),
                ],
              ),
              const SizedBox(height: 12),
              if (usuario.telefone != null) ...[
                Text(
                  usuario.telefone!,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              _buildUserBadges(usuario),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopUserCard(
    BuildContext context,
    Usuario usuario,
    UsuarioController controller,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _navigateToForm(context, usuario),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              _buildUserAvatar(usuario),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      usuario.nome,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      usuario.email,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    if (usuario.telefone != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        usuario.telefone!,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(child: _buildUserBadges(usuario)),
              _buildActionMenu(context, usuario, controller),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserAvatar(Usuario usuario) {
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
              color: AppColors.primary.withOpacity(0.1),
              border: Border.all(
                color: usuario.ativo
                    ? AppColors.success.withOpacity(0.5)
                    : AppColors.error.withOpacity(0.5),
                width: 2,
              ),
              image: usuario.fotoUrl != null
                  ? DecorationImage(
                      image: NetworkImage(usuario.fotoUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: usuario.fotoUrl == null
                ? Icon(Icons.person, color: AppColors.primary, size: size * 0.5)
                : null,
          ),
          if (usuario.emailVerificado)
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
                  Icons.verified,
                  color: AppColors.success,
                  size: size * 0.25,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUserBadges(Usuario usuario) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        _buildStatusBadge(
          usuario.ativo ? 'Ativo' : 'Inativo',
          usuario.ativo ? AppColors.success : AppColors.error,
        ),
        _buildStatusBadge(usuario.perfil.nome, AppColors.secondary),
        if (usuario.emailVerificado)
          _buildStatusBadge(
            'Email Verificado',
            AppColors.success,
            icon: Icons.verified,
          ),
        if (usuario.ultimoAcesso != null)
          _buildStatusBadge(
            'Acessou ${_formatLastAccess(usuario.ultimoAcesso!)}',
            AppColors.info,
            icon: Icons.access_time,
          ),
      ],
    );
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
    Usuario usuario,
    UsuarioController controller,
  ) {
    return PopupMenuButton<String>(
      onSelected: (value) =>
          _handleMenuAction(context, value, usuario, controller),
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
                usuario.ativo ? Icons.block : Icons.check_circle,
                size: 20,
                color: usuario.ativo ? AppColors.warning : AppColors.success,
              ),
              const SizedBox(width: 8),
              Text(usuario.ativo ? 'Inativar' : 'Ativar'),
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

  void _navigateToForm(BuildContext context, Usuario? usuario) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => UsuarioFormScreen(usuario: usuario),
          ),
        )
        .then((_) => _loadUsuarios());
  }

  void _handleMenuAction(
    BuildContext context,
    String action,
    Usuario usuario,
    UsuarioController controller,
  ) {
    switch (action) {
      case 'edit':
        _navigateToForm(context, usuario);
        break;
      case 'toggle_status':
        _toggleUserStatus(context, usuario, controller);
        break;
      case 'delete':
        _deleteUser(context, usuario, controller);
        break;
    }
  }

  void _toggleUserStatus(
    BuildContext context,
    Usuario usuario,
    UsuarioController controller,
  ) {
    final novoUsuario = usuario.copyWith(ativo: !usuario.ativo);
    controller.saveItem(novoUsuario);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Usuário ${novoUsuario.ativo ? 'ativado' : 'inativado'} com sucesso',
        ),
        backgroundColor: novoUsuario.ativo
            ? AppColors.success
            : AppColors.warning,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _deleteUser(
    BuildContext context,
    Usuario usuario,
    UsuarioController controller,
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
              'Tem certeza que deseja excluir o usuário ${usuario.nome}?',
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
              controller.deleteItem(usuario);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Usuário ${usuario.nome} excluído com sucesso'),
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

  String _formatLastAccess(DateTime ultimoAcesso) {
    final now = DateTime.now();
    final difference = now.difference(ultimoAcesso);

    if (difference.inMinutes < 1) return 'agora';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m';
    if (difference.inHours < 24) return '${difference.inHours}h';
    if (difference.inDays < 7) return '${difference.inDays}d';
    if (difference.inDays < 30) return '${(difference.inDays / 7).floor()}sem';
    return '${(difference.inDays / 30).floor()}mes';
  }
}

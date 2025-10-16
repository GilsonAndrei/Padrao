// views/usuarios/usuario_form_screen.dart
import 'package:flutter/material.dart';
import 'package:projeto_padrao/core/themes/app_colors.dart';
import 'package:projeto_padrao/models/usuario.dart';
import 'package:projeto_padrao/models/perfil_usuario.dart';
import 'package:projeto_padrao/repositories/usuario_repository.dart';
import 'package:projeto_padrao/repositories/perfil_usuario_repository.dart';
import 'package:projeto_padrao/controllers/perfil_usuario_controller.dart';
import 'package:projeto_padrao/views/generic/generic_search_screen.dart';

class UsuarioFormScreen extends StatefulWidget {
  final Usuario? usuario;

  const UsuarioFormScreen({Key? key, this.usuario}) : super(key: key);

  @override
  State<UsuarioFormScreen> createState() => _UsuarioFormScreenState();
}

class _UsuarioFormScreenState extends State<UsuarioFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usuarioRepository = UsuarioRepository();
  final _perfilController = PerfilUsuarioController();

  late TextEditingController _nomeController;
  late TextEditingController _emailController;
  late TextEditingController _telefoneController;

  PerfilUsuario? _perfilSelecionado;
  bool _ativo = true;
  bool _isLoading = false;
  bool _carregandoPerfis = true;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.usuario?.nome ?? '');
    _emailController = TextEditingController(text: widget.usuario?.email ?? '');
    _telefoneController = TextEditingController(
      text: widget.usuario?.telefone ?? '',
    );
    _ativo = widget.usuario?.ativo ?? true;
    _carregarPerfis();
  }

  Future<void> _carregarPerfis() async {
    try {
      print("AAAAA");
      await _perfilController.initialSearch();

      setState(() {
        _carregandoPerfis = false;

        // Definir perfil selecionado
        if (widget.usuario != null && widget.usuario!.perfil.id.isNotEmpty) {
          print("BBBBBBBBB");
          _perfilSelecionado = _perfilController.items.firstWhere(
            (p) => p.id == widget.usuario!.perfil.id,
            orElse: () => _perfilController.items.isNotEmpty
                ? _perfilController.items.firstWhere(
                    (p) => p.ativo,
                    orElse: () => _perfilController.items.first,
                  )
                : _criarPerfilVazio(),
          );
        } else if (_perfilController.items.isNotEmpty) {
          print("CCCCCCCCC");
          // Encontrar primeiro perfil ativo, ou o primeiro disponível
          _perfilSelecionado = _perfilController.items.firstWhere(
            (p) => p.ativo,
            orElse: () => _perfilController.items.first,
          );
        }
      });
    } catch (e) {
      print('❌ Erro ao carregar perfis: $e');
      setState(() => _carregandoPerfis = false);
      _showError('Erro ao carregar perfis: $e');
    }
  }

  PerfilUsuario _criarPerfilVazio() {
    return PerfilUsuario(
      id: '',
      nome: 'Nenhum perfil disponível',
      descricao: 'Cadastre perfis primeiro',
      permissoes: [],
      dataCriacao: DateTime.now(),
      ativo: false,
    );
  }

  Future<void> _abrirSelecaoPerfis() async {
    if (_carregandoPerfis) return;

    final perfilSelecionado = await showModalBottomSheet<PerfilUsuario>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: _SelecaoPerfisScreen(
          controller: _perfilController,
          perfilSelecionado: _perfilSelecionado,
        ),
      ),
    );

    if (perfilSelecionado != null) {
      setState(() {
        _perfilSelecionado = perfilSelecionado;
      });
    }
  }

  Future<void> _salvarUsuario() async {
    if (!_formKey.currentState!.validate()) return;
    if (_perfilSelecionado == null || _perfilSelecionado!.id.isEmpty) {
      _showError('Selecione um perfil válido');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final usuario = Usuario(
        id:
            widget.usuario?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        nome: _nomeController.text.trim(),
        email: _emailController.text.trim(),
        telefone: _telefoneController.text.trim().isEmpty
            ? null
            : _telefoneController.text.trim(),
        fotoUrl: widget.usuario?.fotoUrl,
        perfil: _perfilSelecionado!,
        dataCriacao: widget.usuario?.dataCriacao ?? DateTime.now(),
        dataAtualizacao: DateTime.now(),
        ultimoAcesso: widget.usuario?.ultimoAcesso,
        ativo: _ativo,
        emailVerificado: widget.usuario?.emailVerificado ?? false,
      );

      if (widget.usuario == null) {
        // Novo usuário
        await _usuarioRepository.collection.add(usuario.toMap());
        _showSuccess('Usuário criado com sucesso!');
      } else {
        // Editar usuário
        await _usuarioRepository.collection
            .doc(usuario.id)
            .update(usuario.toMap());
        _showSuccess('Usuário atualizado com sucesso!');
      }

      Navigator.pop(context);
    } catch (e) {
      _showError('Erro ao salvar usuário: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.success),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  Widget _buildCampoPerfil() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Perfil *',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _carregandoPerfis ? null : _abrirSelecaoPerfis,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: _perfilSelecionado == null
                    ? AppColors.error
                    : AppColors.border,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _carregandoPerfis
                ? const Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 12),
                      Text('Carregando perfis...'),
                    ],
                  )
                : _perfilSelecionado == null || _perfilSelecionado!.id.isEmpty
                ? const Row(
                    children: [
                      Icon(
                        Icons.assignment_ind,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Selecione um perfil...',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _perfilSelecionado!.ativo
                              ? AppColors.primary.withOpacity(0.1)
                              : AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.assignment_ind,
                          color: _perfilSelecionado!.ativo
                              ? AppColors.primary
                              : AppColors.error,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _perfilSelecionado!.nome,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _perfilSelecionado!.ativo
                                    ? AppColors.textPrimary
                                    : AppColors.error,
                              ),
                            ),
                            Text(
                              _perfilSelecionado!.descricao,
                              style: TextStyle(
                                color: _perfilSelecionado!.ativo
                                    ? AppColors.textSecondary
                                    : AppColors.error,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 4,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _perfilSelecionado!.ativo
                                        ? AppColors.success
                                        : AppColors.error,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _perfilSelecionado!.ativo
                                        ? 'Ativo'
                                        : 'Inativo',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.info,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${_perfilSelecionado!.permissoes.length} perms',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
          ),
        ),
        if (_perfilSelecionado == null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Selecione um perfil para o usuário',
              style: TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.usuario == null ? 'Novo Usuário' : 'Editar Usuário'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (widget.usuario != null)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _isLoading ? null : _salvarUsuario,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    // Campo Nome
                    TextFormField(
                      controller: _nomeController,
                      decoration: const InputDecoration(
                        labelText: 'Nome completo *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira o nome';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Campo Email
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'E-mail *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira o e-mail';
                        }
                        if (!value.contains('@')) {
                          return 'Por favor, insira um e-mail válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Campo Telefone
                    TextFormField(
                      controller: _telefoneController,
                      decoration: const InputDecoration(
                        labelText: 'Telefone (opcional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 24),

                    // Campo Perfil com busca
                    _buildCampoPerfil(),
                    const SizedBox(height: 16),

                    // Switch Ativo
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Usuário ativo',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            const Spacer(),
                            Switch(
                              value: _ativo,
                              onChanged: (value) {
                                setState(() {
                                  _ativo = value;
                                });
                              },
                              activeColor: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Botão Salvar
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _salvarUsuario,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Salvar Usuário',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    _perfilController.dispose();
    super.dispose();
  }
}

// Tela de seleção de perfis usando a GenericSearchScreen
class _SelecaoPerfisScreen extends StatelessWidget {
  final PerfilUsuarioController controller;
  final PerfilUsuario? perfilSelecionado;

  const _SelecaoPerfisScreen({
    Key? key,
    required this.controller,
    this.perfilSelecionado,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecionar Perfil'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: GenericSearchScreen<PerfilUsuario>(
        title: '',
        controller: controller,
        showSearchField: true,
        itemBuilder: (context, perfil) => ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: perfil.ativo
                  ? AppColors.primary.withOpacity(0.1)
                  : AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.assignment_ind,
              color: perfil.ativo ? AppColors.primary : AppColors.error,
            ),
          ),
          title: Text(
            perfil.nome,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: perfil.ativo
                  ? AppColors.textPrimary
                  : AppColors.textDisabled,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                perfil.descricao,
                style: TextStyle(
                  color: perfil.ativo
                      ? AppColors.textSecondary
                      : AppColors.textDisabled,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: perfil.ativo ? AppColors.success : AppColors.error,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      perfil.ativo ? 'Ativo' : 'Inativo',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.info,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${perfil.permissoes.length} perms',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: perfil.id == perfilSelecionado?.id
              ? Icon(Icons.check, color: AppColors.primary)
              : null,
          onTap: perfil.ativo ? () => Navigator.pop(context, perfil) : null,
        ),
        filterBuilder: (context, onFiltersApplied) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Filtrar por status',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Todos os perfis'),
                  ),
                  const DropdownMenuItem(
                    value: 'ativo',
                    child: Text('Apenas ativos'),
                  ),
                  const DropdownMenuItem(
                    value: 'inativo',
                    child: Text('Apenas inativos'),
                  ),
                ],
                onChanged: (value) {
                  final filters = <String, dynamic>{};
                  if (value != null) {
                    filters['ativo'] = value == 'ativo';
                  }
                  onFiltersApplied(filters);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

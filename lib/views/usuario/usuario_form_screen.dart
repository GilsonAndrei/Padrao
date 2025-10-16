import 'package:flutter/material.dart';
import 'package:projeto_padrao/controllers/perfil/perfil_controller.dart';
import 'package:projeto_padrao/controllers/usuario/usuario_controller.dart';
import 'package:provider/provider.dart';
import 'package:projeto_padrao/models/usuario.dart';
import 'package:projeto_padrao/models/perfil_usuario.dart';
import 'package:projeto_padrao/core/themes/app_colors.dart';

class UsuarioFormScreen extends StatefulWidget {
  final Usuario? usuario;

  const UsuarioFormScreen({super.key, this.usuario});

  @override
  State<UsuarioFormScreen> createState() => _UsuarioFormScreenState();
}

class _UsuarioFormScreenState extends State<UsuarioFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nomeController;
  late TextEditingController _emailController;
  late TextEditingController _telefoneController;

  PerfilUsuario? _perfilSelecionado;
  bool _ativo = true;
  bool _emailVerificado = false;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.usuario?.nome ?? '');
    _emailController = TextEditingController(text: widget.usuario?.email ?? '');
    _telefoneController = TextEditingController(
      text: widget.usuario?.telefone ?? '',
    );
    _perfilSelecionado = widget.usuario?.perfil;
    _ativo = widget.usuario?.ativo ?? true;
    _emailVerificado = widget.usuario?.emailVerificado ?? false;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final UsuarioController usuarioController = Provider.of<UsuarioController>(
      context,
    );
    final PerfilController perfilController = Provider.of<PerfilController>(
      context,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.usuario == null ? 'Novo Usuário' : 'Editar Usuário'),
        actions: [
          if (widget.usuario != null)
            _buildDeleteButton(context, usuarioController),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Foto do usuário
                      _buildUserPhoto(),
                      const SizedBox(height: 24),

                      // Nome
                      TextFormField(
                        controller: _nomeController,
                        decoration: const InputDecoration(
                          labelText: 'Nome completo',
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

                      // Email
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'E-mail',
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

                      // Telefone
                      TextFormField(
                        controller: _telefoneController,
                        decoration: const InputDecoration(
                          labelText: 'Telefone (opcional)',
                          prefixIcon: Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),

                      // Perfil
                      _buildPerfilDropdown(perfilController),
                      const SizedBox(height: 24),

                      // Status
                      _buildStatusSwitch(),
                      const SizedBox(height: 16),

                      // Email Verificado
                      _buildEmailVerificadoSwitch(),
                    ],
                  ),
                ),
              ),

              // Botões de ação
              _buildActionButtons(context, usuarioController),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserPhoto() {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.1),
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: Icon(Icons.person, size: 40, color: AppColors.primary),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(Icons.camera_alt, size: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // No _buildPerfilDropdown() do usuario_form_screen.dart, ADICIONE:
  Widget _buildPerfilDropdown(PerfilController perfilController) {
    return Consumer<PerfilController>(
      builder: (context, controller, child) {
        if (controller.perfisAtivos.isEmpty && !controller.isLoading) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning, color: AppColors.warning),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Nenhum perfil ativo cadastrado. Crie um perfil ativo primeiro.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          );
        }

        // ✅ MÉTODO ROBUSTO: Garante que o valor inicial seja válido
        PerfilUsuario? getInitialValue() {
          // 1. Se já temos um perfil selecionado, tenta encontrar na lista
          if (_perfilSelecionado != null) {
            try {
              return controller.perfisAtivos.firstWhere(
                (p) => p.id == _perfilSelecionado!.id,
              );
            } catch (e) {
              // Se não encontrar, continua para outras opções
            }
          }

          // 2. Se está editando um usuário, usa o perfil dele
          if (widget.usuario != null) {
            try {
              return controller.perfisAtivos.firstWhere(
                (p) => p.id == widget.usuario!.perfil.id,
              );
            } catch (e) {
              // Se não encontrar, continua para outras opções
            }
          }

          // 3. Se nada acima funcionou, retorna null (usuário terá que selecionar)
          return null;
        }

        final selectedValue = getInitialValue();

        return DropdownButtonFormField<PerfilUsuario>(
          value: selectedValue,
          decoration: const InputDecoration(
            labelText: 'Perfil',
            prefixIcon: Icon(Icons.manage_accounts),
            hintText: 'Selecione um perfil',
          ),
          items: controller.perfisAtivos.map((perfil) {
            return DropdownMenuItem<PerfilUsuario>(
              value: perfil,
              child: Text(perfil.nome),
            );
          }).toList(),
          onChanged: (PerfilUsuario? perfil) {
            setState(() {
              _perfilSelecionado = perfil;
            });
          },
          validator: (value) {
            if (value == null) {
              return 'Por favor, selecione um perfil';
            }
            return null;
          },
          // ✅ Adiciona comportamento para quando o valor é nulo
          hint: const Text('Selecione um perfil'),
        );
      },
    );
  }

  Widget _buildStatusSwitch() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              _ativo ? Icons.check_circle : Icons.block,
              color: _ativo ? AppColors.success : AppColors.error,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Usuário ativo',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    _ativo
                        ? 'O usuário pode acessar o sistema'
                        : 'O usuário não pode acessar o sistema',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: _ativo,
              onChanged: (value) {
                setState(() {
                  _ativo = value;
                });
              },
              activeColor: AppColors.success,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailVerificadoSwitch() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              _emailVerificado ? Icons.verified : Icons.unpublished,
              color: _emailVerificado ? AppColors.success : AppColors.warning,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'E-mail verificado',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    _emailVerificado
                        ? 'O e-mail do usuário foi verificado'
                        : 'O e-mail do usuário não foi verificado',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: _emailVerificado,
              onChanged: (value) {
                setState(() {
                  _emailVerificado = value;
                });
              },
              activeColor: AppColors.success,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    UsuarioController controller,
  ) {
    return Column(
      children: [
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _saveUsuario(context, controller),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Salvar Usuário'),
          ),
        ),
        const SizedBox(height: 8),
        if (widget.usuario == null)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ),
      ],
    );
  }

  Widget _buildDeleteButton(
    BuildContext context,
    UsuarioController controller,
  ) {
    return IconButton(
      icon: const Icon(Icons.delete),
      onPressed: () => _deleteUsuario(context, controller),
    );
  }

  void _saveUsuario(BuildContext context, UsuarioController controller) async {
    if (_formKey.currentState!.validate() && _perfilSelecionado != null) {
      final usuario = Usuario(
        id:
            widget.usuario?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        nome: _nomeController.text,
        email: _emailController.text,
        telefone: _telefoneController.text.isEmpty
            ? null
            : _telefoneController.text,
        fotoUrl: null,
        perfil: _perfilSelecionado!,
        dataCriacao: widget.usuario?.dataCriacao ?? DateTime.now(),
        dataAtualizacao: DateTime.now(),
        ultimoAcesso: widget.usuario?.ultimoAcesso,
        ativo: _ativo,
        emailVerificado: _emailVerificado,
      );

      final success = await controller.saveItem(usuario);
      if (success) {
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Usuário ${widget.usuario == null ? 'criado' : 'atualizado'} com sucesso',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao salvar usuário'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else if (_perfilSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecione um perfil'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _deleteUsuario(BuildContext context, UsuarioController controller) {
    if (widget.usuario != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: Text(
            'Tem certeza que deseja excluir o usuário ${widget.usuario!.nome}?',
            textAlign: TextAlign.center,
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () async {
                Navigator.of(context).pop(); // Fecha o dialog

                final success = await controller.deleteItem(widget.usuario!);
                if (success) {
                  Navigator.of(context).pop(); // Volta para a lista

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Usuário ${widget.usuario!.nome} excluído com sucesso',
                      ),
                      backgroundColor: AppColors.success,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Erro ao excluir usuário'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Excluir'),
            ),
          ],
        ),
      );
    }
  }
}

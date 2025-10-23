// models/usuario.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:projeto_padrao/enums/permissao_usuario.dart';
import 'package:projeto_padrao/models/perfil_usuario.dart';

class Usuario {
  final String id;
  final String nome;
  final String email;
  final String? telefone;
  final String? fotoUrl;
  final PerfilUsuario perfil;
  final DateTime dataCriacao;
  final DateTime? dataAtualizacao;
  final DateTime? ultimoAcesso;
  final bool ativo;
  final bool emailVerificado;
  final bool isAdmin;
  final bool? temSenhaDefinida; // ✅ NOVO: Indica se já tem senha definida
  final String? uidFirebase; // ✅ NOVO: ID do Firebase Auth

  Usuario({
    required this.id,
    required this.nome,
    required this.email,
    this.telefone,
    this.fotoUrl,
    required this.perfil,
    required this.dataCriacao,
    this.dataAtualizacao,
    this.ultimoAcesso,
    required this.ativo,
    required this.emailVerificado,
    required this.isAdmin,
    this.temSenhaDefinida, // ✅ NOVO PARÂMETRO
    this.uidFirebase, // ✅ NOVO PARÂMETRO
  });

  // Converte para Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'email': email,
      'telefone': telefone,
      'fotoUrl': fotoUrl,
      'perfil': perfil.toMap(),
      'dataCriacao': dataCriacao.millisecondsSinceEpoch,
      'dataAtualizacao': dataAtualizacao?.millisecondsSinceEpoch,
      'ultimoAcesso': ultimoAcesso?.millisecondsSinceEpoch,
      'ativo': ativo,
      'emailVerificado': emailVerificado,
      'isAdmin': isAdmin,
      'temSenhaDefinida': temSenhaDefinida, // ✅ SALVA NO BANCO
      'uidFirebase': uidFirebase, // ✅ SALVA NO BANCO
    };
  }

  // Factory fromMap atualizado
  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      id: map['id']?.toString() ?? '',
      nome: map['nome']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      telefone: map['telefone']?.toString(),
      fotoUrl: map['fotoUrl']?.toString(),
      perfil: PerfilUsuario.fromMap(
        map['perfil'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(map['perfil'])
            : {},
      ),
      dataCriacao: _parseDateTime(map['dataCriacao']),
      dataAtualizacao: _parseDateTime(map['dataAtualizacao']),
      ultimoAcesso: _parseDateTime(map['ultimoAcesso']),
      ativo: map['ativo'] ?? true,
      emailVerificado: map['emailVerificado'] ?? false,
      isAdmin: map['isAdmin'] ?? false,
      temSenhaDefinida: map['temSenhaDefinida'] ?? false, // ✅ LÊ DO BANCO
      uidFirebase: map['uidFirebase']?.toString(), // ✅ LÊ DO BANCO
    );
  }

  // Método auxiliar para parse de datas
  static DateTime _parseDateTime(dynamic date) {
    if (date == null) return DateTime.now();
    if (date is DateTime) return date;
    if (date is Timestamp) return date.toDate();
    if (date is int) return DateTime.fromMillisecondsSinceEpoch(date);
    if (date is String) return DateTime.tryParse(date) ?? DateTime.now();
    return DateTime.now();
  }

  // Cria uma cópia do usuário com possíveis alterações
  Usuario copyWith({
    String? id,
    String? nome,
    String? email,
    String? telefone,
    String? fotoUrl,
    PerfilUsuario? perfil,
    DateTime? dataCriacao,
    DateTime? dataAtualizacao,
    DateTime? ultimoAcesso,
    bool? ativo,
    bool? emailVerificado,
    bool? isAdmin,
    bool? temSenhaDefinida, // ✅ NOVO PARÂMETRO
    String? uidFirebase, // ✅ NOVO PARÂMETRO
  }) {
    return Usuario(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      telefone: telefone ?? this.telefone,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      perfil: perfil ?? this.perfil,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      dataAtualizacao: dataAtualizacao ?? this.dataAtualizacao,
      ultimoAcesso: ultimoAcesso ?? this.ultimoAcesso,
      ativo: ativo ?? this.ativo,
      emailVerificado: emailVerificado ?? this.emailVerificado,
      isAdmin: isAdmin ?? this.isAdmin,
      temSenhaDefinida: temSenhaDefinida ?? this.temSenhaDefinida,
      uidFirebase: uidFirebase ?? this.uidFirebase,
    );
  }

  // ✅ MÉTODOS PARA AUTENTICAÇÃO

  // Verifica se o usuário pode fazer login (tem senha definida e está ativo)
  bool get podeFazerLogin => (temSenhaDefinida ?? false) && ativo;

  // Verifica se precisa definir senha
  bool get precisaDefinirSenha => !(temSenhaDefinida ?? false);

  // ✅ MÉTODOS ÚTEIS PARA VERIFICAÇÃO DE PERMISSÕES

  // Verifica se é administrador
  bool get ehAdmin => isAdmin;

  // Verifica se tem uma permissão específica
  bool temPermissao(PermissaoUsuario permissao) {
    // Se é admin, tem todas as permissões
    if (isAdmin) return true;

    // Caso contrário, verifica no perfil
    return perfil.permissoes.contains(permissao);
  }

  // Verifica se tem todas as permissões da lista
  bool temTodasPermissoes(List<PermissaoUsuario> permissoes) {
    // Se é admin, tem todas as permissões
    if (isAdmin) return true;

    // Caso contrário, verifica se tem todas as permissões
    for (final permissao in permissoes) {
      if (!perfil.permissoes.contains(permissao)) {
        return false;
      }
    }
    return true;
  }

  // Verifica se tem pelo menos uma permissão da lista
  bool temAlgumaPermissao(List<PermissaoUsuario> permissoes) {
    // Se é admin, tem todas as permissões
    if (isAdmin) return true;

    // Caso contrário, verifica se tem pelo menos uma
    for (final permissao in permissoes) {
      if (perfil.permissoes.contains(permissao)) {
        return true;
      }
    }
    return false;
  }

  // Verifica se pode gerenciar pedidos
  bool get podeGerenciarPedidos {
    return temAlgumaPermissao([
      PermissaoUsuario.cadastrarPedidos,
      PermissaoUsuario.editarPedidos,
      PermissaoUsuario.excluirPedidos,
    ]);
  }

  // Verifica se pode visualizar relatórios
  bool get podeVisualizarRelatorios {
    return temAlgumaPermissao([
      PermissaoUsuario.visualizarRelatorios,
      PermissaoUsuario.relatorioVisualizar,
    ]);
  }

  // Verifica se pode gerenciar usuários
  bool get podeGerenciarUsuarios {
    return temAlgumaPermissao([
      PermissaoUsuario.administrarUsuarios,
      PermissaoUsuario.usuarioVisualizar,
      PermissaoUsuario.usuarioEditar,
    ]);
  }

  // ✅ MÉTODO PARA EXIBIÇÃO NO DRAWER/HEADER
  String get tipoUsuario {
    if (isAdmin) return 'Administrador';
    return perfil.nome;
  }

  // ✅ MÉTODO PARA COR DO BADGE
  Color get corTipoUsuario {
    if (isAdmin) return Colors.red;
    return Colors.blue;
  }

  // ✅ MÉTODO PARA STATUS DE SENHA
  String get statusSenha {
    if (temSenhaDefinida ?? false) return 'Senha definida';
    return 'Senha não definida';
  }

  // ✅ MÉTODO PARA COR DO STATUS DE SENHA
  Color get corStatusSenha {
    if (temSenhaDefinida ?? false) return Colors.green;
    return Colors.orange;
  }
}

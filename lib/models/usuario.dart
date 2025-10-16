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
    };
  }

  // Cria a partir de um Map
  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      id: map['id'] ?? '',
      nome: map['nome'] ?? '',
      email: map['email'] ?? '',
      telefone: map['telefone'],
      fotoUrl: map['fotoUrl'],
      perfil: PerfilUsuario.fromMap(Map<String, dynamic>.from(map['perfil'])),
      dataCriacao: DateTime.fromMillisecondsSinceEpoch(map['dataCriacao']),
      dataAtualizacao: map['dataAtualizacao'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['dataAtualizacao'])
          : null,
      ultimoAcesso: map['ultimoAcesso'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['ultimoAcesso'])
          : null,
      ativo: map['ativo'] ?? true,
      emailVerificado: map['emailVerificado'] ?? false,
    );
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
    );
  }
}

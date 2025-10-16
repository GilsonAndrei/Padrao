import 'package:cloud_firestore/cloud_firestore.dart';
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

  // models/usuario.dart - ATUALIZE o fromMap:
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
    );
  }

  // ✅ ADICIONE este método auxiliar:
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

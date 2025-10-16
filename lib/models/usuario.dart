// models/usuario.dart
import 'package:projeto_padrao/enums/permissao_usuario.dart';
import 'package:projeto_padrao/models/perfil_usuario.dart';
import 'package:projeto_padrao/models/base_model.dart';

class Usuario extends BaseModel {
  @override
  String id;
  String nome;
  String email;
  String? telefone;
  String? fotoUrl;
  PerfilUsuario perfil;
  DateTime dataCriacao;
  DateTime? dataAtualizacao;
  DateTime? ultimoAcesso;
  bool ativo;
  bool emailVerificado;

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
  @override
  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'email': email,
      'telefone': telefone,
      'fotoUrl': fotoUrl,
      'perfilId': perfil.id,
      'dataCriacao': dataCriacao.millisecondsSinceEpoch,
      'dataAtualizacao': dataAtualizacao?.millisecondsSinceEpoch,
      'ultimoAcesso': ultimoAcesso?.millisecondsSinceEpoch,
      'ativo': ativo,
      'emailVerificado': emailVerificado,
      'searchable': _createSearchableFields(),
    };
  }

  List<String> _createSearchableFields() {
    List<String> searchable = [nome.toLowerCase(), email.toLowerCase()];

    if (telefone != null) {
      searchable.add(telefone!.toLowerCase());
    }

    return searchable;
  }

  // MÉTODO CORRIGIDO: Agora é um factory constructor
  factory Usuario.fromMap(Map<String, dynamic> map, String id) {
    return Usuario(
      id: id,
      nome: map['nome'] ?? '',
      email: map['email'] ?? '',
      telefone: map['telefone'],
      fotoUrl: map['fotoUrl'],
      perfil: PerfilUsuario(
        id: map['perfilId'] ?? '',
        nome: '',
        descricao: '',
        permissoes: [],
        dataCriacao: DateTime.now(),
        ativo: true,
      ), // Será carregado depois
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

  // REMOVA o método fromMap antigo (o void) e mantenha apenas este:

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

  // REMOVA o método fromFirestore pois agora temos o fromMap
}

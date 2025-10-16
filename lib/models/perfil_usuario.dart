// models/perfil_usuario.dart
import 'package:projeto_padrao/enums/permissao_usuario.dart';
import 'package:projeto_padrao/models/base_model.dart';

class PerfilUsuario extends BaseModel {
  @override
  String id;
  String nome;
  String descricao;
  List<PermissaoUsuario> permissoes;
  DateTime dataCriacao;
  DateTime? dataAtualizacao;
  bool ativo;

  PerfilUsuario({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.permissoes,
    required this.dataCriacao,
    this.dataAtualizacao,
    required this.ativo,
  });

  // Converte para Map
  @override
  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'descricao': descricao,
      'permissoes': permissoes.map((e) => e.codigo).toList(),
      'dataCriacao': dataCriacao.millisecondsSinceEpoch,
      'dataAtualizacao': dataAtualizacao?.millisecondsSinceEpoch,
      'ativo': ativo,
      'searchable': _createSearchableFields(),
    };
  }

  List<String> _createSearchableFields() {
    return [nome.toLowerCase(), descricao.toLowerCase()];
  }

  // Cria a partir de um Map
  @override
  void fromMap(Map<String, dynamic> map, String id) {
    this.id = id;
    nome = map['nome'] ?? '';
    descricao = map['descricao'] ?? '';
    permissoes =
        (map['permissoes'] as List<dynamic>?)
            ?.map((e) => _permissaoFromString(e.toString()))
            .whereType<PermissaoUsuario>()
            .toList() ??
        [];
    dataCriacao = DateTime.fromMillisecondsSinceEpoch(map['dataCriacao']);
    dataAtualizacao = map['dataAtualizacao'] != null
        ? DateTime.fromMillisecondsSinceEpoch(map['dataAtualizacao'])
        : null;
    ativo = map['ativo'] ?? true;
  }

  // Cria uma cópia do perfil com possíveis alterações
  PerfilUsuario copyWith({
    String? id,
    String? nome,
    String? descricao,
    List<PermissaoUsuario>? permissoes,
    DateTime? dataCriacao,
    DateTime? dataAtualizacao,
    bool? ativo,
  }) {
    return PerfilUsuario(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      permissoes: permissoes ?? this.permissoes,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      dataAtualizacao: dataAtualizacao ?? this.dataAtualizacao,
      ativo: ativo ?? this.ativo,
    );
  }

  // Verifica se o perfil tem uma permissão específica
  bool temPermissao(PermissaoUsuario permissao) {
    return permissoes.contains(permissao);
  }

  // Verifica se o perfil tem todas as permissões de uma lista
  bool temTodasPermissoes(List<PermissaoUsuario> permissoesRequeridas) {
    return permissoesRequeridas.every(
      (permissao) => permissoes.contains(permissao),
    );
  }

  // Verifica se o perfil tem pelo menos uma das permissões da lista
  bool temAlgumaPermissao(List<PermissaoUsuario> permissoesRequeridas) {
    return permissoesRequeridas.any(
      (permissao) => permissoes.contains(permissao),
    );
  }

  // Helper para converter string para PermissaoUsuario
  static PermissaoUsuario? _permissaoFromString(String codigo) {
    try {
      return PermissaoUsuario.values.firstWhere((e) => e.codigo == codigo);
    } catch (e) {
      return null;
    }
  }

  // Helper para criar perfil do Firestore
  static PerfilUsuario fromFirestore(Map<String, dynamic> data, String id) {
    return PerfilUsuario(
      id: id,
      nome: data['nome'] ?? '',
      descricao: data['descricao'] ?? '',
      permissoes:
          (data['permissoes'] as List<dynamic>?)
              ?.map((e) => _permissaoFromString(e.toString()))
              .whereType<PermissaoUsuario>()
              .toList() ??
          [],
      dataCriacao: DateTime.fromMillisecondsSinceEpoch(data['dataCriacao']),
      dataAtualizacao: data['dataAtualizacao'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['dataAtualizacao'])
          : null,
      ativo: data['ativo'] ?? true,
    );
  }
}

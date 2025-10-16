import 'package:projeto_padrao/enums/permissao_usuario.dart';

class PerfilUsuario {
  final String id;
  final String nome;
  final String descricao;
  final List<PermissaoUsuario> permissoes;
  final DateTime dataCriacao;
  final DateTime? dataAtualizacao;
  final bool ativo;

  PerfilUsuario({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.permissoes,
    required this.dataCriacao,
    this.dataAtualizacao,
    required this.ativo,
  });

  // Converte para Map (para salvar no Firebase/Firestore)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'descricao': descricao,
      'permissoes': permissoes.map((e) => e.codigo).toList(),
      'dataCriacao': dataCriacao.millisecondsSinceEpoch,
      'dataAtualizacao': dataAtualizacao?.millisecondsSinceEpoch,
      'ativo': ativo,
    };
  }

  // Cria a partir de um Map (vindo do Firebase/Firestore)
  factory PerfilUsuario.fromMap(Map<String, dynamic> map) {
    return PerfilUsuario(
      id: map['id'] ?? '',
      nome: map['nome'] ?? '',
      descricao: map['descricao'] ?? '',
      permissoes:
          (map['permissoes'] as List<dynamic>?)
              ?.map((e) => _permissaoFromString(e.toString()))
              .whereType<PermissaoUsuario>()
              .toList() ??
          [],
      dataCriacao: DateTime.fromMillisecondsSinceEpoch(map['dataCriacao']),
      dataAtualizacao: map['dataAtualizacao'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['dataAtualizacao'])
          : null,
      ativo: map['ativo'] ?? true,
    );
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
}

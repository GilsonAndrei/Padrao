import 'package:cloud_firestore/cloud_firestore.dart';
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

  factory PerfilUsuario.fromMap(Map<String, dynamic> map) {
    return PerfilUsuario(
      id: map['id']?.toString() ?? '',
      nome: map['nome']?.toString() ?? '',
      descricao: map['descricao']?.toString() ?? '',
      permissoes: _parsePermissoes(map['permissoes']),
      dataCriacao: _parseDateTime(map['dataCriacao']),
      dataAtualizacao: _parseDateTime(map['dataAtualizacao']),
      ativo: map['ativo'] ?? true,
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

  static List<PermissaoUsuario> _parsePermissoes(dynamic permissoes) {
    if (permissoes is! List) return [];

    return permissoes
        .map((e) {
          try {
            if (e is PermissaoUsuario) return e;
            if (e is String) return _permissaoFromString(e);
            return null;
          } catch (_) {
            return null;
          }
        })
        .whereType<PermissaoUsuario>()
        .toList();
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

  // models/perfil_usuario.dart - ADICIONE este método estático:
  static PermissaoUsuario? _permissaoFromString(String codigo) {
    try {
      return PermissaoUsuario.values.firstWhere((e) => e.codigo == codigo);
    } catch (e) {
      return null;
    }
  }
}

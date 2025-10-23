// controllers/perfil/perfil_search_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projeto_padrao/controllers/search/base_search_controller.dart';
import 'package:projeto_padrao/models/paginated_response.dart';
import 'package:projeto_padrao/models/perfil_usuario.dart';
import 'package:projeto_padrao/services/perfil/perfil_service.dart';

class PerfilSearchController extends BaseSearchController<PerfilUsuario> {
  final PerfilService _perfilService;
  final bool apenasAtivos;

  PerfilSearchController(this._perfilService, {this.apenasAtivos = true});

  @override
  Future<PaginatedResponse<PerfilUsuario>> searchItems({
    required String searchTerm,
    required int page,
    int pageSize = 20,
  }) async {
    if (apenasAtivos) {
      return await _perfilService.searchPerfisAtivos(
        searchTerm: searchTerm,
        page: page,
        pageSize: pageSize,
      );
    } else {
      return await _perfilService.searchPerfis(
        searchTerm: searchTerm,
        page: page,
        pageSize: pageSize,
      );
    }
  }

  // ✅ NOVO: MÉTODO DE BUSCA COM CURSOR (PARA INFINITE SCROLL)
  Future<PaginatedResponse<PerfilUsuario>> searchItemsWithCursor({
    required String searchTerm,
    DocumentSnapshot? lastDocument,
    int limit = 20,
  }) async {
    if (apenasAtivos) {
      return await _perfilService.searchPerfisAtivosWithCursor(
        searchTerm: searchTerm,
        lastDocument: lastDocument,
        limit: limit,
      );
    } else {
      return await _perfilService.searchPerfisWithCursor(
        searchTerm: searchTerm,
        lastDocument: lastDocument,
        limit: limit,
      );
    }
  }

  // ✅ NOVO: MÉTODO DE BUSCA COM FILTROS AVANÇADOS
  Future<PaginatedResponse<PerfilUsuario>> searchWithFilters({
    required String searchTerm,
    required int page,
    int pageSize = 20,
    bool? apenasAtivos,
  }) async {
    final effectiveApenasAtivos = apenasAtivos ?? this.apenasAtivos;

    return await _perfilService.searchPerfis(
      searchTerm: searchTerm,
      page: page,
      pageSize: pageSize,
      apenasAtivos: effectiveApenasAtivos,
    );
  }
}

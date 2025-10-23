// controllers/perfil/perfil_search_controller.dart
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
}

import 'package:campus_connect_interface/core/rede/cliente_http_campus.dart';
import 'package:campus_connect_interface/core/rede/contratos_auth.dart';
import 'package:campus_connect_interface/core/rede/contratos_conteudo.dart';
import 'package:campus_connect_interface/core/rede/excecao_api.dart';

enum AuthActionErrorType {
  unauthorized,
  forbidden,
  generic,
}

class AuthActionError implements Exception {
  AuthActionError(
    this.type, {
    this.cause,
  });

  final AuthActionErrorType type;
  final Object? cause;
}

class ApiAuthRepository {
  ApiAuthRepository(this._api);

  final CampusApiClient _api;

  Future<LoginResponseDto> login({
    required String email,
    required String senha,
  }) {
    return _guarded(() => _api.login(email: email, senha: senha));
  }

  Future<RegisterResponseDto> register(RegisterRequestDto dto) {
    return _guarded(() => _api.register(dto));
  }

  Future<Map<String, dynamic>> me() => _guarded(() => _api.me());

  Future<Map<String, dynamic>> createGroup(Map<String, dynamic> payload) {
    return _guarded(() => _api.createGroup(payload));
  }

  Future<Map<String, dynamic>> createCommunity(Map<String, dynamic> payload) {
    return _guarded(() => _api.createCommunity(payload));
  }

  Future<Map<String, dynamic>> createOpportunity(Map<String, dynamic> payload) {
    final dto = OpportunityPayload(
      title: payload['title'] as String,
      companyName: payload['company_name'] as String,
      shortDescription: payload['short_description'] as String,
      fullDescription: payload['full_description'] as String,
      applyDeadline: DateTime.parse(payload['apply_deadline'] as String),
      workLocation: payload['work_location'] as String,
      typeLabel: payload['type_label'] as String,
      requirements: (payload['requirements'] as List).cast<String>(),
    );
    return _guarded(() => _api.createOpportunity(dto));
  }

  Future<Map<String, dynamic>> createUniversityNotice(
    Map<String, dynamic> payload,
  ) {
    return _guarded(() => _api.createUniversityNotice(payload));
  }

  Future<List<Map<String, dynamic>>> getOpportunityApplicants(String id) {
    return _guarded(() => _api.getOpportunityApplicants(id));
  }

  Future<T> _guarded<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        _api.clearAccessToken();
        throw AuthActionError(AuthActionErrorType.unauthorized, cause: e);
      }
      if (e.isForbidden) {
        throw AuthActionError(AuthActionErrorType.forbidden, cause: e);
      }
      throw AuthActionError(AuthActionErrorType.generic, cause: e);
    }
  }
}

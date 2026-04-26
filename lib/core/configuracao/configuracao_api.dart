import 'package:campus_connect_interface/core/rede/contratos_conteudo.dart';

abstract final class ApiConfig {
  static String get baseUrl {
    const fromEnv = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: '',
    );
    if (fromEnv.isNotEmpty) return _trimSlash(fromEnv);
    return 'http://localhost:8080';
  }

  static String _trimSlash(String u) =>
      u.endsWith('/') ? u.substring(0, u.length - 1) : u;

  static AppUserRole get debugUserRole {
    const fromEnv = String.fromEnvironment(
      'APP_USER_ROLE',
      defaultValue: 'padrao',
    );
    return AppUserRole.fromValue(fromEnv);
  }
}

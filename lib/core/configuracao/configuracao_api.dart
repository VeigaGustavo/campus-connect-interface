import 'package:campus_connect_interface/core/rede/contratos_conteudo.dart';
import 'package:flutter/foundation.dart';

abstract final class ApiConfig {
  static const productionBaseUrl = 'https://campus.veigagustavo.com.br';

  static String get baseUrl {
    const fromEnv = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: '',
    );
    if (fromEnv.isNotEmpty) return _trimSlash(fromEnv);

    if (kIsWeb) {
      final host = Uri.base.host.toLowerCase();
      if (host == 'localhost' || host == '127.0.0.1') {
        return 'http://localhost:8080';
      }
      return productionBaseUrl;
    }

    if (kDebugMode) {
      return 'http://localhost:8080';
    }
    return productionBaseUrl;
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

  static String get profileAvatarUploadPath {
    const fromEnv = String.fromEnvironment(
      'PROFILE_AVATAR_PATH',
      defaultValue: '/api/profile/avatar',
    );
    return fromEnv.startsWith('/') ? fromEnv : '/$fromEnv';
  }

  static String get profileCoverUploadPath {
    const fromEnv = String.fromEnvironment(
      'PROFILE_COVER_PATH',
      defaultValue: '/api/profile/cover',
    );
    return fromEnv.startsWith('/') ? fromEnv : '/$fromEnv';
  }

  static String get feedAttachmentUploadPath {
    const fromEnv = String.fromEnvironment(
      'FEED_ATTACHMENT_PATH',
      defaultValue: '/api/feed/attachments',
    );
    return fromEnv.startsWith('/') ? fromEnv : '/$fromEnv';
  }
}

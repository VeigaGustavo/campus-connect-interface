import 'package:campus_connect_interface/core/rede/contratos_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.tokenType,
    required this.login,
    required this.role,
    required this.userId,
    required this.expiresIn,
    required this.issuedAtEpochSeconds,
  });

  final String accessToken;
  final String tokenType;
  final String login;
  final String role;
  final String userId;
  final int expiresIn;
  final int issuedAtEpochSeconds;

  bool get isExpired {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return now >= issuedAtEpochSeconds + expiresIn;
  }
}

abstract final class LocalSessionStore {
  static const _kAccessToken = 'session.access_token';
  static const _kTokenType = 'session.token_type';
  static const _kLogin = 'session.login';
  static const _kRole = 'session.role';
  static const _kUserId = 'session.user_id';
  static const _kExpiresIn = 'session.expires_in';
  static const _kIssuedAt = 'session.issued_at';

  static Future<void> saveFromLogin(LoginResponseDto dto) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await prefs.setString(_kAccessToken, dto.accessToken);
    await prefs.setString(_kTokenType, dto.tokenType);
    await prefs.setString(_kLogin, dto.login);
    await prefs.setString(_kRole, dto.role);
    await prefs.setString(_kUserId, dto.userId);
    await prefs.setInt(_kExpiresIn, dto.expiresIn);
    await prefs.setInt(_kIssuedAt, now);
  }

  static Future<AuthSession?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_kAccessToken);
    if (token == null || token.isEmpty) return null;

    final session = AuthSession(
      accessToken: token,
      tokenType: prefs.getString(_kTokenType) ?? 'Bearer',
      login: prefs.getString(_kLogin) ?? '',
      role: prefs.getString(_kRole) ?? '',
      userId: prefs.getString(_kUserId) ?? '',
      expiresIn: prefs.getInt(_kExpiresIn) ?? 0,
      issuedAtEpochSeconds: prefs.getInt(_kIssuedAt) ?? 0,
    );
    if (session.isExpired) {
      await clear();
      return null;
    }
    return session;
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kAccessToken);
    await prefs.remove(_kTokenType);
    await prefs.remove(_kLogin);
    await prefs.remove(_kRole);
    await prefs.remove(_kUserId);
    await prefs.remove(_kExpiresIn);
    await prefs.remove(_kIssuedAt);
  }
}

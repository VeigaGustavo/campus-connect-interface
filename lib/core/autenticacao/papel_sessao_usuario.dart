import 'package:campus_connect_interface/core/autenticacao/sessao_local.dart';
import 'package:campus_connect_interface/core/configuracao/configuracao_api.dart';
import 'package:campus_connect_interface/core/rede/contratos_conteudo.dart';
import 'package:flutter/foundation.dart';

class UserSessionRole extends ChangeNotifier {
  AppUserRole _current = ApiConfig.debugUserRole;

  AppUserRole get current => _current;

  void applyRole(String? raw) {
    final next = raw != null && raw.trim().isNotEmpty
        ? AppUserRole.fromValue(raw.trim())
        : ApiConfig.debugUserRole;
    if (next == _current) return;
    _current = next;
    notifyListeners();
  }

  Future<void> syncFromLocalSession() async {
    final session = await LocalSessionStore.read();
    applyRole(session?.role);
  }

  void clear() => applyRole(null);
}

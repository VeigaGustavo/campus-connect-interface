import 'package:campus_connect_interface/core/rede/contratos_conteudo.dart';

abstract final class UiPermissions {
  static bool canManageEvents(AppUserRole role) {
    return role == AppUserRole.universidade ||
        role == AppUserRole.comunidade ||
        role == AppUserRole.sistemaAdmin;
  }

  static bool canManageReadings(AppUserRole role) {
    return role == AppUserRole.universidade ||
        role == AppUserRole.comunidade ||
        role == AppUserRole.empresa ||
        role == AppUserRole.sistemaAdmin;
  }

  static bool canManageGroups(AppUserRole role) {
    return role == AppUserRole.padrao ||
        role == AppUserRole.comunidade ||
        role == AppUserRole.sistemaAdmin;
  }

  static bool canManageOpportunities(AppUserRole role) {
    return role == AppUserRole.empresa || role == AppUserRole.sistemaAdmin;
  }
}

import 'package:campus_connect_interface/features/perfil/domain/perfil_usuario.dart';

abstract class ProfileRepository {
  Future<UserProfile> getCurrentProfile();
}

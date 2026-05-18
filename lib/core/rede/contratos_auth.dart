class LoginRequestDto {
  const LoginRequestDto({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
      };
}

enum RegisterProfileType {
  estudante,
  comunidade,
  empresa,
  universidade;

  String get value => switch (this) {
        RegisterProfileType.estudante => 'estudante',
        RegisterProfileType.comunidade => 'comunidade',
        RegisterProfileType.empresa => 'empresa',
        RegisterProfileType.universidade => 'universidade',
      };
}

class RegisterRequestDto {
  const RegisterRequestDto({
    required this.profileType,
    required this.fullName,
    this.birthDate,
    required this.cpf,
    required this.institution,
    required this.city,
    required this.state,
    required this.email,
    required this.password,
    this.communityType,
    this.communityName,
    this.groupTitle,
    this.groupDescription,
    this.groupVisibility,
    this.companyName,
    this.companyCnpj,
    this.companyDescription,
    this.institutionName,
    this.institutionAcronym,
    this.institutionType,
    this.institutionDescription,
  });

  final RegisterProfileType profileType;
  final String fullName;
  final DateTime? birthDate;
  final String cpf;
  final String institution;
  final String city;
  final String state;
  final String email;
  final String password;
  final String? communityType;
  final String? communityName;
  final String? groupTitle;
  final String? groupDescription;
  final String? groupVisibility;
  final String? companyName;
  final String? companyCnpj;
  final String? companyDescription;
  final String? institutionName;
  final String? institutionAcronym;
  final String? institutionType;
  final String? institutionDescription;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'profile_type': profileType.value,
      'full_name': fullName,
      if (birthDate != null) 'birth_date': _formatDateOnly(birthDate!),
      'cpf': cpf,
      'institution': institution,
      'city': city,
      'state': state,
      'email': email,
      'password': password,
      'community_type': communityType,
      'community_name': communityName,
      'group_title': groupTitle,
      'group_description': groupDescription,
      'group_visibility': groupVisibility,
      'company_name': companyName,
      'company_cnpj': companyCnpj,
      'company_description': companyDescription,
      'institution_name': institutionName,
      'institution_acronym': institutionAcronym,
      'institution_type': institutionType,
      'institution_description': institutionDescription,
    };
    data.removeWhere((_, value) {
      if (value == null) return true;
      if (value is String && value.trim().isEmpty) return true;
      return false;
    });
    return data;
  }

  static String _formatDateOnly(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}

class RegisterResponseDto {
  const RegisterResponseDto({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.profileType,
    this.communityId,
    this.groupId,
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final String profileType;
  final String? communityId;
  final String? groupId;

  factory RegisterResponseDto.fromJson(Map<String, dynamic> json) {
    return RegisterResponseDto(
      id: json['id'].toString(),
      name: (json['name'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      role: (json['role'] ?? '') as String,
      profileType: (json['profile_type'] ?? '') as String,
      communityId: json['community_id']?.toString(),
      groupId: json['group_id']?.toString(),
    );
  }
}

class LoginResponseDto {
  const LoginResponseDto({
    required this.accessToken,
    required this.tokenType,
    required this.login,
    required this.expiresIn,
    required this.role,
    required this.userId,
  });

  final String accessToken;
  final String tokenType;
  final String login;
  final int expiresIn;
  final String role;
  final String userId;

  factory LoginResponseDto.fromJson(Map<String, dynamic> json) {
    return LoginResponseDto(
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String,
      login: (json['login'] ?? '') as String,
      expiresIn: (json['expires_in'] as num).toInt(),
      role: json['role'] as String,
      userId: json['user_id'].toString(),
    );
  }
}

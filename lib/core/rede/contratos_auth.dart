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
    required this.age,
    required this.cpf,
    required this.institution,
    required this.city,
    required this.state,
    required this.email,
    required this.password,
    this.communityType,
    this.communityName,
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
  final int age;
  final String cpf;
  final String institution;
  final String city;
  final String state;
  final String email;
  final String password;
  final String? communityType;
  final String? communityName;
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
      'age': age,
      'cpf': cpf,
      'institution': institution,
      'city': city,
      'state': state,
      'email': email,
      'password': password,
      'community_type': communityType,
      'community_name': communityName,
      'company_name': companyName,
      'company_cnpj': companyCnpj,
      'company_description': companyDescription,
      'institution_name': institutionName,
      'institution_acronym': institutionAcronym,
      'institution_type': institutionType,
      'institution_description': institutionDescription,
    };
    data.removeWhere((_, value) => value == null);
    return data;
  }
}

class RegisterResponseDto {
  const RegisterResponseDto({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.profileType,
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final String profileType;

  factory RegisterResponseDto.fromJson(Map<String, dynamic> json) {
    return RegisterResponseDto(
      id: json['id'].toString(),
      name: (json['name'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      role: (json['role'] ?? '') as String,
      profileType: (json['profile_type'] ?? '') as String,
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

enum AppUserRole {
  padrao,
  comunidade,
  empresa,
  universidade,
  sistemaAdmin;

  String get value => switch (this) {
        AppUserRole.padrao => 'padrao',
        AppUserRole.comunidade => 'comunidade',
        AppUserRole.empresa => 'empresa',
        AppUserRole.universidade => 'universidade',
        AppUserRole.sistemaAdmin => 'sistema_admin',
      };

  static AppUserRole fromValue(String raw) => switch (raw) {
        'padrao' => AppUserRole.padrao,
        'comunidade' => AppUserRole.comunidade,
        'empresa' => AppUserRole.empresa,
        'universidade' => AppUserRole.universidade,
        'sistema_admin' => AppUserRole.sistemaAdmin,
        _ => AppUserRole.padrao,
      };
}

enum ReadingKind {
  campusNews,
  magazine,
  article;

  String get value => switch (this) {
        ReadingKind.campusNews => 'campus_news',
        ReadingKind.magazine => 'magazine',
        ReadingKind.article => 'article',
      };
}

class OpportunityPayload {
  const OpportunityPayload({
    required this.title,
    required this.companyName,
    required this.shortDescription,
    required this.fullDescription,
    required this.applyDeadline,
    required this.workLocation,
    required this.typeLabel,
    required this.requirements,
  });

  final String title;
  final String companyName;
  final String shortDescription;
  final String fullDescription;
  final DateTime applyDeadline;
  final String workLocation;
  final String typeLabel;
  final List<String> requirements;

  Map<String, dynamic> toJson() => {
        'title': title,
        'company_name': companyName,
        'short_description': shortDescription,
        'full_description': fullDescription,
        'apply_deadline': applyDeadline.toIso8601String(),
        'work_location': workLocation,
        'type_label': typeLabel,
        'requirements': requirements,
      };
}

class EventPayload {
  const EventPayload({
    required this.title,
    required this.description,
    required this.startAt,
    required this.location,
    required this.organizer,
  });

  final String title;
  final String description;
  final DateTime startAt;
  final String location;
  final String organizer;

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'start_at': startAt.toIso8601String(),
        'location': location,
        'organizer': organizer,
      };
}

class GroupFilePayload {
  const GroupFilePayload({
    required this.fileName,
    required this.fileUrl,
  });

  final String fileName;
  final String fileUrl;

  Map<String, dynamic> toJson() => {
        'file_name': fileName,
        'file_url': fileUrl,
      };
}

class GroupMeetingPayload {
  const GroupMeetingPayload({
    required this.topic,
    required this.startAt,
    required this.location,
    required this.participantsCount,
  });

  final String topic;
  final DateTime startAt;
  final String location;
  final int participantsCount;

  Map<String, dynamic> toJson() => {
        'topic': topic,
        'start_at': startAt.toIso8601String(),
        'location': location,
        'participants_count': participantsCount,
      };
}

class WeeklyReadingPayload {
  const WeeklyReadingPayload({
    required this.kind,
    required this.title,
    required this.source,
    required this.excerpt,
    required this.imageUrl,
    required this.metaLabel,
  });

  final ReadingKind kind;
  final String title;
  final String source;
  final String excerpt;
  final String imageUrl;
  final String metaLabel;

  Map<String, dynamic> toJson() => {
        'kind': kind.value,
        'title': title,
        'source': source,
        'excerpt': excerpt,
        'image_url': imageUrl,
        'meta_label': metaLabel,
      };
}

class AdminUserPayload {
  const AdminUserPayload({
    required this.name,
    required this.email,
    required this.password,
    required this.role,
  });

  final String name;
  final String email;
  final String password;
  final AppUserRole role;

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'password': password,
        'role': role.value,
      };
}

class OpportunityApplicantDto {
  const OpportunityApplicantDto({
    required this.userId,
    required this.name,
    required this.email,
    required this.profileSummary,
    required this.resumeUrl,
    required this.applicationStatus,
  });

  final String userId;
  final String name;
  final String email;
  final String profileSummary;
  final String resumeUrl;
  final String applicationStatus;

  factory OpportunityApplicantDto.fromJson(Map<String, dynamic> json) {
    return OpportunityApplicantDto(
      userId: json['user_id'].toString(),
      name: json['name'] as String,
      email: json['email'] as String,
      profileSummary: json['profile_summary'] as String,
      resumeUrl: json['resume_url'] as String,
      applicationStatus: json['application_status'] as String,
    );
  }
}

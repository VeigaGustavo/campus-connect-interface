class UserInterest {
  const UserInterest(this.label);
  final String label;
}

enum ProfileActivityKind { application, groupJoined, eventRegistered }

class ProfileActivity {
  const ProfileActivity({
    required this.kind,
    required this.titleHighlight,
    required this.subtitle,
    required this.timeAgoLabel,
  });

  final ProfileActivityKind kind;
  final String titleHighlight;
  final String subtitle;
  final String timeAgoLabel;
}

class UserProfile {
  const UserProfile({
    required this.name,
    required this.initials,
    required this.coverImageUrl,
    required this.avatarImageUrl,
    required this.performanceCertificateLabel,
    required this.courseAndSemester,
    required this.email,
    required this.cityState,
    required this.applicationsCount,
    required this.groupsCount,
    required this.eventsCount,
    required this.interests,
    required this.recentActivity,
  });

  final String name;
  final String initials;
  final String coverImageUrl;
  final String avatarImageUrl;
  final String performanceCertificateLabel;
  final String courseAndSemester;
  final String email;
  final String cityState;
  final int applicationsCount;
  final int groupsCount;
  final int eventsCount;
  final List<UserInterest> interests;
  final List<ProfileActivity> recentActivity;
}

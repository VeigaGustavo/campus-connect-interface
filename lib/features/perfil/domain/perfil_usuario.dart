enum CommunityKind { athletic, academicCenter, community }

enum CommunityRole { member, director, president }

enum ProfileHistoryKind { post, reading, group }

class CommunityHighlight {
  const CommunityHighlight({
    required this.id,
    required this.name,
    required this.kind,
    required this.role,
  });

  final String id;
  final String name;
  final CommunityKind kind;
  final CommunityRole role;
}

class ProfileHistoryItem {
  const ProfileHistoryItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.referenceId,
    required this.createdAt,
  });

  final String id;
  final ProfileHistoryKind kind;
  final String title;
  final String subtitle;
  final String referenceId;
  final DateTime createdAt;
}

class ProfileUpdateInput {
  const ProfileUpdateInput({
    required this.aboutMe,
    required this.jobTitle,
    required this.course,
    required this.semester,
    required this.institutionName,
    required this.interests,
    required this.favoriteTopics,
    required this.specialties,
  });

  final String aboutMe;
  final String jobTitle;
  final String course;
  final String semester;
  final String institutionName;
  final List<String> interests;
  final List<String> favoriteTopics;
  final List<String> specialties;
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.coverImageUrl,
    required this.avatarImageUrl,
    required this.email,
    required this.cityState,
    required this.aboutMe,
    required this.jobTitle,
    required this.course,
    required this.semester,
    required this.institutionName,
    required this.applicationsCount,
    required this.groupsCount,
    required this.eventsCount,
    required this.interests,
    required this.favoriteTopics,
    required this.specialties,
    required this.communityHighlight,
  });

  final String id;
  final String name;
  final String coverImageUrl;
  final String avatarImageUrl;
  final String email;
  final String cityState;
  final String aboutMe;
  final String jobTitle;
  final String course;
  final String semester;
  final String institutionName;
  final int applicationsCount;
  final int groupsCount;
  final int eventsCount;
  final List<String> interests;
  final List<String> favoriteTopics;
  final List<String> specialties;
  final CommunityHighlight? communityHighlight;
}

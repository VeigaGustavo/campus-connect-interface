class CampusEvent {
  const CampusEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.startAt,
    required this.location,
    required this.organizer,
  });

  final String id;
  final String title;
  final String description;
  final DateTime startAt;
  final String location;
  final String organizer;
}

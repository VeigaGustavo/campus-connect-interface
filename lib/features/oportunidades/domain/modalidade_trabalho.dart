enum WorkLocation {
  remote,
  hybrid,
  onSite,
}

extension WorkLocationX on WorkLocation {
  String get labelPt => switch (this) {
    WorkLocation.remote => 'Remoto',
    WorkLocation.hybrid => 'Híbrido',
    WorkLocation.onSite => 'Presencial',
  };
}

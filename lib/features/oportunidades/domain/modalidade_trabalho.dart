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

  String get apiValue => switch (this) {
        WorkLocation.remote => 'remote',
        WorkLocation.hybrid => 'hybrid',
        WorkLocation.onSite => 'on_site',
      };
}

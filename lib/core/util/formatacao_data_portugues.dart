const _months = <String>[
  'Jan',
  'Fev',
  'Mar',
  'Abr',
  'Mai',
  'Jun',
  'Jul',
  'Ago',
  'Set',
  'Out',
  'Nov',
  'Dez',
];

String formatDayMonthYearPt(DateTime date) {
  return '${date.day} de ${_months[date.month - 1]}, ${date.year}';
}

String formatDayMonthTimePt(DateTime date) {
  final h = date.hour.toString().padLeft(2, '0');
  final m = date.minute.toString().padLeft(2, '0');
  return '${date.day} de ${_months[date.month - 1]}, ${date.year} · $h:$m';
}

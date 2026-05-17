class SmartAlert {
  final String title;
  final String description;
  final AlertSeverity severity;

  SmartAlert({
    required this.title,
    required this.description,
    required this.severity,
  });
}

enum AlertSeverity {
  critical,
  warning,
  info,
}
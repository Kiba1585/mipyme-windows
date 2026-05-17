class BusinessInsight {
  final String title;
  final String value;
  final String? subtitle;
  final InsightType type;

  BusinessInsight({
    required this.title,
    required this.value,
    this.subtitle,
    required this.type,
  });
}

enum InsightType {
  positive,
  negative,
  warning,
  info,
}
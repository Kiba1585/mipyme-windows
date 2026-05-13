class Asset {
  final int? id;
  final String name;
  final double value;
  final int usefulLifeYears;
  final DateTime acquisitionDate;

  Asset({this.id, required this.name, required this.value, required this.usefulLifeYears, required this.acquisitionDate});

  double get monthlyDepreciation => value / (usefulLifeYears * 12);

  factory Asset.fromMap(Map<String, dynamic> map) { ... }
  Map<String, dynamic> toMap() { ... }
}

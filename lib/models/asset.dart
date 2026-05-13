class Asset {
  final int? id;
  final String name;
  final double value;
  final int usefulLifeYears;
  final DateTime acquisitionDate;

  Asset({
    this.id,
    required this.name,
    required this.value,
    required this.usefulLifeYears,
    required this.acquisitionDate,
  });

  double get monthlyDepreciation => value / (usefulLifeYears * 12);

  factory Asset.fromMap(Map<String, dynamic> map) {
    return Asset(
      id: map['id'] as int?,
      name: map['name'] as String,
      value: (map['value'] as num).toDouble(),
      usefulLifeYears: map['useful_life_years'] as int,
      acquisitionDate: DateTime.parse(map['acquisition_date'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'value': value,
      'useful_life_years': usefulLifeYears,
      'acquisition_date': acquisitionDate.toIso8601String(),
    };
  }
}

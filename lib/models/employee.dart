class Employee {
  final int? id;
  final String name;
  final double baseSalary;
  final String? notes;

  Employee({this.id, required this.name, required this.baseSalary, this.notes});

  factory Employee.fromMap(Map<String, dynamic> map) {
    return Employee(
      id: map['id'] as int?,
      name: map['name'] as String,
      baseSalary: (map['base_salary'] as num).toDouble(),
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'base_salary': baseSalary, 'notes': notes};
  }
}

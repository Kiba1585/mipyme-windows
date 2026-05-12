class Budget {
  final int? id;
  final String month;
  final double projectedIncome;
  final double projectedExpenses;
  final String? notes;

  Budget({
    this.id,
    required this.month,
    required this.projectedIncome,
    required this.projectedExpenses,
    this.notes,
  });

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'] as int?,
      month: map['month'] as String,
      projectedIncome: (map['projected_income'] as num).toDouble(),
      projectedExpenses: (map['projected_expenses'] as num).toDouble(),
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'month': month,
      'projected_income': projectedIncome,
      'projected_expenses': projectedExpenses,
      'notes': notes,
    };
  }
}

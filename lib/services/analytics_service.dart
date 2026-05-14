import 'package:intl/intl.dart';
import 'database_service.dart';

class CategoryExpense {
  final String category;
  final double amount;
  CategoryExpense({required this.category, required this.amount});
}

class MonthlyTrend {
  final String month;
  final double income;
  final double expenses;
  MonthlyTrend({required this.month, required this.income, required this.expenses});
}

class AnalyticsService {
  /// Gastos agrupados por categoría para el período actual.
  static Future<List<CategoryExpense>> getExpensesByCategory({
    String? startDate,
    String? endDate,
  }) async {
    final db = await DatabaseService.database;
    String where = "type = 'expense'";
    List<dynamic> args = [];
    if (startDate != null && endDate != null) {
      where += ' AND date BETWEEN ? AND ?';
      args.addAll([startDate, endDate]);
    }
    final records = await db.query(
      'financial_records',
      where: where,
      whereArgs: args,
    );

    final Map<String, double> map = {};
    for (final r in records) {
      final cat = r['category'] as String;
      final amount = (r['amount'] as num).toDouble();
      map[cat] = (map[cat] ?? 0) + amount;
    }
    return map.entries
        .map((e) => CategoryExpense(category: e.key, amount: e.value))
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
  }

  /// Tendencia mensual (últimos 12 meses) de ingresos y gastos.
  static Future<List<MonthlyTrend>> getMonthlyTrend() async {
    final trends = <MonthlyTrend>[];
    final now = DateTime.now();
    for (int i = 11; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final monthStr = DateFormat('yyyy-MM').format(date);
      final startDate = '$monthStr-01';
      final endDate = '$monthStr-31';
      final income = await DatabaseService.getTotalByType('income', startDate, endDate);
      final expenses = await DatabaseService.getTotalByType('expense', startDate, endDate);
      trends.add(MonthlyTrend(month: monthStr, income: income, expenses: expenses));
    }
    return trends;
  }
}
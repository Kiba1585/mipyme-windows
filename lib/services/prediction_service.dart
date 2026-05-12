import 'package:intl/intl.dart';
import 'database_service.dart';

class MonthlySummary {
  final String month;
  final double income;
  final double expenses;
  final double profit;

  MonthlySummary({
    required this.month,
    required this.income,
    required this.expenses,
    required this.profit,
  });
}

class PredictionService {
  /// Obtiene resúmenes mensuales de los últimos 12 meses.
  static Future<List<MonthlySummary>> getMonthlyHistory() async {
    final summaries = <MonthlySummary>[];
    final now = DateTime.now();

    for (int i = 11; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final monthStr = DateFormat('yyyy-MM').format(date);
      final startDate = '$monthStr-01';
      final endDate = '$monthStr-31';

      final income = await DatabaseService.getTotalByType('income', startDate, endDate);
      final expenses = await DatabaseService.getTotalByType('expense', startDate, endDate);

      summaries.add(MonthlySummary(
        month: monthStr,
        income: income,
        expenses: expenses,
        profit: income - expenses,
      ));
    }

    return summaries;
  }

  /// Calcula una tendencia simple (promedio de los últimos 3 meses).
  static double calculateTrend(List<MonthlySummary> summaries) {
    if (summaries.length < 3) return 0;
    final lastThree = summaries.sublist(summaries.length - 3);
    final total = lastThree.fold(0.0, (sum, s) => sum + s.profit);
    return total / 3.0;
  }

  /// Predice el próximo mes basándose en el promedio de los últimos 3 meses.
  static MonthlySummary predictNextMonth(List<MonthlySummary> summaries) {
    if (summaries.isEmpty) {
      return MonthlySummary(
        month: DateFormat('yyyy-MM').format(DateTime.now().add(const Duration(days: 30))),
        income: 0,
        expenses: 0,
        profit: 0,
      );
    }

    final lastThree = summaries.length >= 3
        ? summaries.sublist(summaries.length - 3)
        : summaries;

    final avgIncome = lastThree.fold(0.0, (sum, s) => sum + s.income) / lastThree.length;
    final avgExpenses = lastThree.fold(0.0, (sum, s) => sum + s.expenses) / lastThree.length;

    return MonthlySummary(
      month: DateFormat('yyyy-MM').format(DateTime.now().add(const Duration(days: 30))),
      income: avgIncome,
      expenses: avgExpenses,
      profit: avgIncome - avgExpenses,
    );
  }
}
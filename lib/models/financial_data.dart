class DailySales {
  final String date;
  final double total;
  final double cash;
  final double transfer;
  final int tickets;

  DailySales({
    required this.date,
    required this.total,
    required this.cash,
    required this.transfer,
    required this.tickets,
  });

  factory DailySales.fromJson(Map<String, dynamic> json) {
    return DailySales(
      date: json['date'] as String,
      total: (json['total'] as num).toDouble(),
      cash: (json['cash'] as num).toDouble(),
      transfer: (json['transfer'] as num).toDouble(),
      tickets: json['tickets'] as int,
    );
  }
}

class MonthlyReport {
  final String month;
  final double totalSales;
  final double expenses;
  final double netProfit;

  MonthlyReport({
    required this.month,
    required this.totalSales,
    required this.expenses,
    required this.netProfit,
  });
}
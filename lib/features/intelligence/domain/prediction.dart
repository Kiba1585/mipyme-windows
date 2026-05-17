class ProductPrediction {
  final String productName;
  final double currentStock;
  final double dailyConsumption;
  final int daysUntilStockout;

  ProductPrediction({
    required this.productName,
    required this.currentStock,
    required this.dailyConsumption,
    required this.daysUntilStockout,
  });
}

class SalesTrend {
  final String direction; // 'subiendo', 'bajando', 'estable'
  final double changePercent;
  final String suggestion;

  SalesTrend({
    required this.direction,
    required this.changePercent,
    required this.suggestion,
  });
}
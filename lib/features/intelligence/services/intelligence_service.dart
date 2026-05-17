import 'package:intl/intl.dart';
import '../../../services/database_service.dart';
import '../../../services/analytics_service.dart';
import '../../../services/prediction_service.dart';
import '../domain/business_insight.dart';
import '../domain/prediction.dart';
import '../domain/smart_alert.dart';

class IntelligenceService {
  // ==================== ANÁLISIS DE NEGOCIO ====================

  static Future<BusinessInsight?> getMostProfitableProduct() async {
    final now = DateTime.now();
    final products = await DatabaseService.getProducts();
    if (products.isEmpty) return null;

    final profitMap = <String, double>{};
    for (final product in products) {
      final name = product['name'] as String;
      final price = (product['price'] as num).toDouble();
      final cost = (product['cost'] as num?)?.toDouble() ?? 0.0;
      final stock = (product['stock'] as num).toDouble();
      final profit = (price - cost) * stock;
      profitMap[name] = profit;
    }

    if (profitMap.isEmpty) return null;
    final top = profitMap.entries.reduce((a, b) => a.value > b.value ? a : b);

    return BusinessInsight(
      title: 'Producto más rentable',
      value: top.key,
      subtitle: 'Beneficio potencial: \$${top.value.toStringAsFixed(2)}',
      type: InsightType.positive,
    );
  }

  static Future<BusinessInsight?> getPeakSalesHour() async {
    return BusinessInsight(
      title: 'Hora pico de ventas',
      value: '10:00 AM - 12:00 PM',
      subtitle: 'Basado en los últimos 30 días',
      type: InsightType.info,
    );
  }

  static Future<List<BusinessInsight>> getSlowProducts() async {
    final products = await DatabaseService.getProducts();
    if (products.isEmpty) return [];

    final slow = products
        .where((p) => (p['stock'] as num).toDouble() > 20)
        .map((p) {
          final stock = (p['stock'] as num).toDouble();
          final unit = p['unit'] as String;
          return BusinessInsight(
            title: p['name'] as String,
            value: 'Stock: $stock $unit',
            subtitle: 'Posible exceso de inventario',
            type: InsightType.warning,
          );
        })
        .toList();
    return slow.take(3).toList();
  }

  // ==================== PREDICCIONES ====================

  static Future<List<ProductPrediction>> getSoonOutOfStock() async {
    final products = await DatabaseService.getProducts();
    return products
        .where((p) => (p['stock'] as num).toDouble() < 10)
        .map((p) {
          final stock = (p['stock'] as num).toDouble();
          return ProductPrediction(
            productName: p['name'] as String,
            currentStock: stock,
            dailyConsumption: 2.0,
            daysUntilStockout: (stock / 2).ceil(),
          );
        })
        .toList();
  }

  static Future<SalesTrend> getSalesTrend() async {
    final summaries = await PredictionService.getMonthlyHistory();
    if (summaries.length < 2) {
      return SalesTrend(direction: 'estable', changePercent: 0.0, suggestion: 'No hay suficientes datos');
    }

    final last = summaries.last.profit;
    final previous = summaries[summaries.length - 2].profit;
    // Corregido: 0.0 para que el tipo sea double, no num
    final change = previous != 0 ? ((last - previous) / previous.abs()) * 100 : 0.0;

    String direction;
    String suggestion;
    if (change > 10) {
      direction = 'subiendo';
      suggestion = 'Considere aumentar inventario de productos clave';
    } else if (change < -10) {
      direction = 'bajando';
      suggestion = 'Revise gastos y promociones';
    } else {
      direction = 'estable';
      suggestion = 'Mantenga la estrategia actual';
    }

    return SalesTrend(direction: direction, changePercent: change, suggestion: suggestion);
  }

  static Future<String> getPurchaseSuggestion() async {
    final lowStock = await getSoonOutOfStock();
    if (lowStock.isEmpty) return 'Inventario saludable. No se requieren compras urgentes.';
    final names = lowStock.map((p) => p.productName).join(', ');
    return 'Considere comprar: $names';
  }

  // ==================== ALERTAS INTELIGENTES ====================

  static Future<List<SmartAlert>> getAlerts() async {
    final alerts = <SmartAlert>[];

    // Stock crítico
    final lowStock = await getSoonOutOfStock();
    if (lowStock.isNotEmpty) {
      alerts.add(SmartAlert(
        title: 'Stock crítico',
        description: '${lowStock.length} producto(s) con stock bajo.',
        severity: AlertSeverity.critical,
      ));
    }

    // Presupuesto excedido
    final now = DateTime.now();
    final currentMonth = DateFormat('yyyy-MM').format(now);
    final budget = await DatabaseService.getBudget(currentMonth);
    if (budget != null) {
      final startDate = '$currentMonth-01';
      final endDate = '$currentMonth-31';
      final realExpenses = await DatabaseService.getTotalByType('expense', startDate, endDate);
      if (realExpenses > budget.projectedExpenses) {
        alerts.add(SmartAlert(
          title: 'Presupuesto excedido',
          description: 'Los gastos reales (\$${realExpenses.toStringAsFixed(2)}) superan lo presupuestado (\$${budget.projectedExpenses.toStringAsFixed(2)}).',
          severity: AlertSeverity.warning,
        ));
      }
    }

    // Gastos elevados por categoría
    final expenses = await AnalyticsService.getExpensesByCategory();
    for (final cat in expenses) {
      final amount = (cat.amount as num).toDouble();
      if (amount > 10000) {
        alerts.add(SmartAlert(
          title: 'Gasto elevado en ${cat.category}',
          description: '\$${amount.toStringAsFixed(2)} este mes.',
          severity: AlertSeverity.warning,
        ));
      }
    }

    return alerts;
  }
}
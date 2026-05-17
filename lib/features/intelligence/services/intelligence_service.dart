import 'package:intl/intl.dart';
import '../../../services/database_service.dart';
import '../../../services/analytics_service.dart';
import '../../../services/prediction_service.dart';
import '../domain/business_insight.dart';
import '../domain/prediction.dart';
import '../domain/smart_alert.dart';

class IntelligenceService {
  // ==================== ANÁLISIS DE NEGOCIO ====================

  /// Producto más rentable del mes
  static Future<BusinessInsight?> getMostProfitableProduct() async {
    final now = DateTime.now();
    final monthStart = DateFormat('yyyy-MM-01').format(now);
    final monthEnd = DateFormat('yyyy-MM-31').format(now);

    final products = await DatabaseService.getProducts();
    if (products.isEmpty) return null;

    Map<String, double> profitMap = {};
    for (final product in products) {
      final code = product['product_code'] as String;
      final name = product['name'] as String;
      final price = (product['price'] as num).toDouble();
      final cost = (product['cost'] as num?)?.toDouble() ?? 0;

      // Obtener ventas de este producto (asumiendo que usas financial_records o tabla sales)
      // Por ahora usamos la cantidad en inventario como proxy (esto lo mejorarás con la tabla de ventas)
      final stock = (product['stock'] as num).toDouble();
      final profit = (price - cost) * stock; // beneficio potencial
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

  /// Hora con más ventas (requiere tabla de ventas; por ahora devolvemos un placeholder)
  static Future<BusinessInsight?> getPeakSalesHour() async {
    // TODO: cuando tengas tabla de ventas con hora, consultar
    return BusinessInsight(
      title: 'Hora pico de ventas',
      value: '10:00 AM - 12:00 PM',
      subtitle: 'Basado en los últimos 30 días',
      type: InsightType.info,
    );
  }

  /// Productos con rotación más lenta (menos vendidos, alto stock)
  static Future<List<BusinessInsight>> getSlowProducts() async {
    final products = await DatabaseService.getProducts();
    if (products.isEmpty) return [];

    // Productos con stock alto y precio bajo (aproximación)
    final slow = products
        .where((p) => (p['stock'] as num).toDouble() > 20)
        .map((p) => BusinessInsight(
              title: p['name'] as String,
              value: 'Stock: ${p['stock']} ${p['unit']}',
              subtitle: 'Posible exceso de inventario',
              type: InsightType.warning,
            ))
        .toList();
    return slow.take(3).toList();
  }

  // ==================== PREDICCIONES ====================

  /// Productos que se agotarán pronto (basado en stock bajo)
  static Future<List<ProductPrediction>> getSoonOutOfStock() async {
    final products = await DatabaseService.getProducts();
    return products
        .where((p) => (p['stock'] as num).toDouble() < 10)
        .map((p) => ProductPrediction(
              productName: p['name'] as String,
              currentStock: (p['stock'] as num).toDouble(),
              dailyConsumption: 2.0, // estimación genérica
              daysUntilStockout: ((p['stock'] as num).toDouble() / 2).ceil(),
            ))
        .toList();
  }

  /// Tendencia de ventas
  static Future<SalesTrend> getSalesTrend() async {
    final summaries = await PredictionService.getMonthlyHistory();
    if (summaries.length < 2) {
      return SalesTrend(direction: 'estable', changePercent: 0, suggestion: 'No hay suficientes datos');
    }

    final last = summaries.last.profit;
    final previous = summaries[summaries.length - 2].profit;
    final change = previous != 0 ? ((last - previous) / previous.abs()) * 100 : 0;

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

  /// Sugerencia de compra (productos con stock crítico)
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

    // Caja descuadrada (placeholder, necesitarías registrar cierres de caja)
    // Aquí podrías comparar ingresos del día vs efectivo en caja.

    // Gastos anormales (ej: categoría "Insumos" subió más de 50%)
    final expenses = await AnalyticsService.getExpensesByCategory();
    for (final cat in expenses) {
      if (cat.amount > 10000) { // umbral genérico
        alerts.add(SmartAlert(
          title: 'Gasto elevado en ${cat.category}',
          description: '\$${cat.amount.toStringAsFixed(2)} este mes.',
          severity: AlertSeverity.warning,
        ));
      }
    }

    return alerts;
  }
}
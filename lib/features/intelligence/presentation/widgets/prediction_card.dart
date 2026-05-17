import 'package:flutter/material.dart';
import '../../domain/prediction.dart';

class PredictionCard extends StatelessWidget {
  final List<ProductPrediction> products;
  final SalesTrend trend;
  final String purchaseSuggestion;
  const PredictionCard({
    super.key,
    required this.products,
    required this.trend,
    required this.purchaseSuggestion,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Predicciones', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            // Tendencia
            Row(
              children: [
                Icon(
                  trend.direction == 'subiendo' ? Icons.trending_up : Icons.trending_down,
                  color: trend.direction == 'subiendo' ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text('Ventas ${trend.direction} (${trend.changePercent.toStringAsFixed(1)}%)'),
              ],
            ),
            Text(trend.suggestion, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 12),
            // Productos agotándose
            if (products.isNotEmpty) ...[
              const Text('Productos que se agotarán pronto:', style: TextStyle(fontWeight: FontWeight.w500)),
              ...products.map((p) => ListTile(
                    dense: true,
                    title: Text(p.productName),
                    subtitle: Text('Stock: ${p.currentStock} • ~${p.daysUntilStockout} días restantes'),
                  )),
            ],
            const Divider(),
            Text('Sugerencia de compra:', style: const TextStyle(fontWeight: FontWeight.w500)),
            Text(purchaseSuggestion),
          ],
        ),
      ),
    );
  }
}
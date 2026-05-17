import 'package:flutter/material.dart';
import '../services/intelligence_service.dart' as svc;               // ← corregido
import '../domain/business_insight.dart';                             // ← corregido
import '../domain/prediction.dart';                                   // ← corregido
import '../domain/smart_alert.dart';                                  // ← corregido
import 'widgets/insight_card.dart';
import 'widgets/prediction_card.dart';
import 'widgets/alert_card.dart';

class IntelligenceScreen extends StatefulWidget {
  const IntelligenceScreen({super.key});

  @override
  State<IntelligenceScreen> createState() => _IntelligenceScreenState();
}

class _IntelligenceScreenState extends State<IntelligenceScreen> {
  BusinessInsight? mostProfitable;
  BusinessInsight? peakHour;
  List<BusinessInsight> slowProducts = [];
  List<ProductPrediction> outOfStock = [];
  SalesTrend? salesTrend;
  String purchaseSuggestion = '';
  List<SmartAlert> alerts = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadAll();
  }

  Future<void> loadAll() async {
    setState(() { loading = true; error = null; });
    try {
      final results = await Future.wait([
        svc.IntelligenceService.getMostProfitableProduct(),
        svc.IntelligenceService.getPeakSalesHour(),
        svc.IntelligenceService.getSlowProducts(),
        svc.IntelligenceService.getSoonOutOfStock(),
        svc.IntelligenceService.getSalesTrend(),
        svc.IntelligenceService.getPurchaseSuggestion(),
        svc.IntelligenceService.getAlerts(),
      ]);

      mostProfitable = results[0] as BusinessInsight?;
      peakHour = results[1] as BusinessInsight?;
      slowProducts = results[2] as List<BusinessInsight>;
      outOfStock = results[3] as List<ProductPrediction>;
      salesTrend = results[4] as SalesTrend;
      purchaseSuggestion = results[5] as String;
      alerts = results[6] as List<SmartAlert>;
    } catch (e) {
      error = e.toString();
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Centro de Inteligencia')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Error: $error'),
                    ElevatedButton(onPressed: loadAll, child: const Text('Reintentar')),
                  ],
                ))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Análisis de negocio', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      if (mostProfitable != null) InsightCard(insight: mostProfitable!),
                      if (peakHour != null) InsightCard(insight: peakHour!),
                      ...slowProducts.map((p) => InsightCard(insight: p)),

                      const SizedBox(height: 24),

                      if (salesTrend != null)
                        PredictionCard(
                          products: outOfStock,
                          trend: salesTrend!,
                          purchaseSuggestion: purchaseSuggestion,
                        ),

                      const SizedBox(height: 24),

                      const Text('Alertas inteligentes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      if (alerts.isEmpty)
                        const Text('No hay alertas activas.')
                      else
                        ...alerts.map((a) => AlertCard(alert: a)),
                    ],
                  ),
                ),
    );
  }
}
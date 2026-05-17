import 'package:flutter/material.dart';
import '../../domain/business_insight.dart';

class InsightCard extends StatelessWidget {
  final BusinessInsight insight;
  const InsightCard({super.key, required this.insight});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    switch (insight.type) {
      case InsightType.positive:
        color = Colors.green;
        icon = Icons.trending_up;
        break;
      case InsightType.negative:
        color = Colors.red;
        icon = Icons.trending_down;
        break;
      case InsightType.warning:
        color = Colors.orange;
        icon = Icons.warning_amber;
        break;
      case InsightType.info:
        color = Colors.blue;
        icon = Icons.info;
        break;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(insight.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(insight.value, style: TextStyle(fontSize: 18, color: color)),
                  if (insight.subtitle != null)
                    Text(insight.subtitle!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
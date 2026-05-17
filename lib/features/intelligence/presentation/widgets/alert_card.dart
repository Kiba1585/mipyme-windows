import 'package:flutter/material.dart';
import '../../domain/smart_alert.dart';

class AlertCard extends StatelessWidget {
  final SmartAlert alert;
  const AlertCard({super.key, required this.alert});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    switch (alert.severity) {
      case AlertSeverity.critical:
        color = Colors.red;
        icon = Icons.error;
        break;
      case AlertSeverity.warning:
        color = Colors.orange;
        icon = Icons.warning;
        break;
      case AlertSeverity.info:
        color = Colors.blue;
        icon = Icons.info;
        break;
    }

    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(alert.title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                  Text(alert.description),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
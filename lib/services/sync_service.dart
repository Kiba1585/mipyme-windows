import 'dart:convert';
import 'database_service.dart';

class SyncService {
  /// Exporta todos los registros financieros a un JSON (para enviar al móvil).
  static Future<String> exportToJson() async {
    final records = await DatabaseService.getFinancialRecords();
    return jsonEncode(records);
  }

  /// Importa registros desde un JSON (recibido del móvil).
  static Future<void> importFromJson(String jsonString) async {
    final List<dynamic> data = jsonDecode(jsonString);
    for (final item in data) {
      await DatabaseService.addFinancialRecord(
        date: item['date'] as String,
        type: item['type'] as String,
        amount: (item['amount'] as num).toDouble(),
        category: item['category'] as String,
        description: item['description'] as String?,
      );
    }
  }
}
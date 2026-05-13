import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // Necesario para ConflictAlgorithm
import 'database_service.dart';

class ReminderService {
  /// Guarda la fecha del próximo vencimiento de ONAT.
  static Future<void> setTaxDeadline(DateTime date) async {
    final db = await DatabaseService.database;
    await db.insert(
      'reminders',
      {
        'type': 'tax',
        'deadline': date.toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Obtiene el recordatorio de vencimiento más cercano.
  static Future<Map<String, dynamic>?> getUpcomingDeadline() async {
    final db = await DatabaseService.database;
    final results = await db.query('reminders',
        where: 'type = ? AND deadline >= ?',
        whereArgs: ['tax', DateTime.now().toIso8601String()],
        orderBy: 'deadline ASC',
        limit: 1);
    return results.isNotEmpty ? results.first : null;
  }
}
import 'database_service.dart';

class AuditService {
  static Future<void> log(String action, {String? user, String? details}) async {
    await DatabaseService.addAuditLog(
      action: action,
      user: user ?? 'Sistema',
      details: details,
    );
  }
}
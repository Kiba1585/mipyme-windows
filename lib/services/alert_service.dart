import 'package:local_notifier/local_notifier.dart';
import 'package:intl/intl.dart';
import 'database_service.dart';

class AlertService {
  static Future<void> checkAndNotify() async {
    final upcoming = await DatabaseService.getCashflowProjection(
      DateFormat('yyyy-MM').format(DateTime.now().add(const Duration(days: 30))),
    );
    if (upcoming != null) {
      await _showNotification(
        'Próximo vencimiento de impuestos',
        'Tiene un vencimiento programado para el próximo mes.',
      );
    }

    final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
    final budget = await DatabaseService.getBudget(currentMonth);
    if (budget != null) {
      final startDate = '$currentMonth-01';
      final endDate = '$currentMonth-31';
      final realExpenses = await DatabaseService.getTotalByType('expense', startDate, endDate);
      if (realExpenses > budget.projectedExpenses) {
        await _showNotification(
          'Presupuesto excedido',
          'Los gastos reales superan el presupuesto.',
        );
      }
    }
  }

  static Future<void> _showNotification(String title, String body) async {
    await localNotifier.notify(
      LocalNotification(
        title: title,
        body: body,
      ),
    );
  }

  static Future<void> initialize() async {
    await localNotifier.setup(
      appName: 'MIPYME Windows',
      shortcutPolicy: ShortcutPolicy.requireCreate,
    );
  }

  static void startPeriodicCheck() {
    Future.doWhile(() async {
      await checkAndNotify();
      await Future.delayed(const Duration(hours: 1));
      return true;
    });
  }
}
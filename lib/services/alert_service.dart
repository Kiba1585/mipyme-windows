import 'package:local_notifier/local_notifier.dart';
import 'package:intl/intl.dart';
import 'database_service.dart';

class AlertService {
  /// Comprueba todas las condiciones de alerta y muestra notificaciones si es necesario.
  static Future<void> checkAndNotify() async {
    // 1. Vencimientos de impuestos
    final upcoming = await DatabaseService.getCashflowProjection(
      DateFormat('yyyy-MM').format(DateTime.now().add(const Duration(days: 30))),
    );
    if (upcoming != null) {
      await _showNotification(
        'Próximo vencimiento de impuestos',
        'Tiene un vencimiento programado para el próximo mes.',
      );
    }

    // 2. Presupuestos sobrepasados
    final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
    final budget = await DatabaseService.getBudget(currentMonth);
    if (budget != null) {
      final startDate = '$currentMonth-01';
      final endDate = '$currentMonth-31';
      final realExpenses = await DatabaseService.getTotalByType('expense', startDate, endDate);
      if (realExpenses > budget.projectedExpenses) {
        await _showNotification(
          'Presupuesto excedido',
          'Los gastos reales (\$${realExpenses.toStringAsFixed(0)}) superan el presupuesto (\$${budget.projectedExpenses.toStringAsFixed(0)}).',
        );
      }
    }
  }

  /// Muestra una notificación local en Windows.
  static Future<void> _showNotification(String title, String body) async {
    await localNotifier.notify(title, body, icon: null);
  }

  /// Inicializa el sistema de notificaciones (solo necesario la primera vez).
  static Future<void> initialize() async {
    await localNotifier.setup(
      appName: 'MIPYME Windows',
      shortcutPolicy: ShortcutPolicy.requireCreate,
    );
  }

  /// Programa una verificación periódica cada hora.
  static void startPeriodicCheck() {
    Future.doWhile(() async {
      await checkAndNotify();
      await Future.delayed(const Duration(hours: 1));
      return true;
    });
  }
}
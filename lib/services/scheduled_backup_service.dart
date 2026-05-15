import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:intl/intl.dart';
import 'backup_service.dart';

class ScheduledBackupService {
  static const _storage = FlutterSecureStorage();
  static const _activeKey = 'auto_backup_active';
  static const _frequencyDaysKey = 'auto_backup_frequency_days';
  static const _lastBackupKey = 'last_backup_date';

  static Timer? _timer;

  /// Inicia el temporizador solo si el respaldo automático está activado.
  static Future<void> startIfEnabled() async {
    final active = await _storage.read(key: _activeKey);
    if (active == 'true') {
      start();
    }
  }

  /// Detiene el temporizador actual.
  static void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Inicia el temporizador con la frecuencia guardada.
  static void start() {
    stop();
    _checkAndSchedule();
  }

  static Future<void> _checkAndSchedule() async {
    // Leer frecuencia (días), por defecto 7
    final freqStr = await _storage.read(key: _frequencyDaysKey);
    final frequencyDays = int.tryParse(freqStr ?? '7') ?? 7;
    // Leer última fecha de backup
    final lastBackupStr = await _storage.read(key: _lastBackupKey);
    DateTime? lastBackup;
    if (lastBackupStr != null) {
      lastBackup = DateTime.tryParse(lastBackupStr);
    }
    final now = DateTime.now();
    // Calcular tiempo restante hasta el próximo backup
    Duration nextBackupIn;
    if (lastBackup == null) {
      // Nunca se ha hecho backup → programar para dentro de 'frequencyDays' días
      nextBackupIn = Duration(days: frequencyDays);
    } else {
      final nextBackupDate = lastBackup.add(Duration(days: frequencyDays));
      if (now.isAfter(nextBackupDate)) {
        // Ya pasó la fecha, hacer backup ahora mismo
        _performBackup();
        nextBackupIn = Duration(days: frequencyDays);
      } else {
        nextBackupIn = nextBackupDate.difference(now);
      }
    }

    // Programar el timer para que se ejecute después del tiempo calculado
    _timer = Timer(nextBackupIn, () {
      _performBackup();
      // Volver a programar después de ejecutar
      start();
    });
  }

  static Future<void> _performBackup() async {
    try {
      final path = await WindowsBackupService.exportBackup();
      // Guardar fecha actual
      await _storage.write(
          key: _lastBackupKey,
          value: DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()));
      // Notificar
      await localNotifier.notify(
        LocalNotification(
          title: 'Respaldo automático',
          body: 'La copia de seguridad se guardó en: $path',
        ),
      );
    } catch (e) {
      await localNotifier.notify(
        LocalNotification(
          title: 'Error en respaldo automático',
          body: e.toString(),
        ),
      );
    }
  }

  /// Guarda la configuración y reinicia el temporizador.
  static Future<void> updateConfiguration({required bool active, int frequencyDays = 7}) async {
    await _storage.write(key: _activeKey, value: active.toString());
    await _storage.write(key: _frequencyDaysKey, value: frequencyDays.toString());
    if (active) {
      start();
    } else {
      stop();
    }
  }

  /// Obtiene el estado actual de la configuración.
  static Future<Map<String, dynamic>> getConfiguration() async {
    final active = await _storage.read(key: _activeKey);
    final freq = await _storage.read(key: _frequencyDaysKey);
    return {
      'active': active == 'true',
      'frequencyDays': int.tryParse(freq ?? '7') ?? 7,
    };
  }
}
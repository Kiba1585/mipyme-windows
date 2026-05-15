import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/license_service.dart';
import '../services/backup_service.dart';
import '../services/scheduled_backup_service.dart';
import '../core/theme/theme_scope.dart';
import 'activation_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _storage = const FlutterSecureStorage();
  bool _darkMode = false;
  bool _autoBackupActive = false;
  int _autoBackupFrequency = 7;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final dark = await _storage.read(key: 'dark_mode');
    final config = await ScheduledBackupService.getConfiguration();
    setState(() {
      _darkMode = dark == 'true';
      _autoBackupActive = config['active'] as bool;
      _autoBackupFrequency = config['frequencyDays'] as int;
    });
  }

  void _toggleDarkMode(bool val) {
    setState(() => _darkMode = val);
    _storage.write(key: 'dark_mode', value: val.toString());
    ThemeScope.of(context)?.onThemeChanged(val);
  }

  void _toggleAutoBackup(bool val) {
    setState(() => _autoBackupActive = val);
    ScheduledBackupService.updateConfiguration(active: val, frequencyDays: _autoBackupFrequency);
  }

  void _setAutoBackupFrequency(int days) {
    setState(() => _autoBackupFrequency = days);
    ScheduledBackupService.updateConfiguration(active: _autoBackupActive, frequencyDays: days);
  }

  // Los demás métodos (_deactivate, _exportBackup, _importBackup) se mantienen igual
  // ...

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          SwitchListTile(
            title: const Text('Modo oscuro'),
            subtitle: const Text('Cambia la apariencia de la aplicación'),
            value: _darkMode,
            onChanged: _toggleDarkMode,
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Respaldo automático'),
            subtitle: Text(
              _autoBackupActive
                  ? 'Cada $_autoBackupFrequency día(s)'
                  : 'Desactivado',
            ),
            value: _autoBackupActive,
            onChanged: _toggleAutoBackup,
          ),
          if (_autoBackupActive)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonFormField<int>(
                value: _autoBackupFrequency,
                decoration: const InputDecoration(
                  labelText: 'Frecuencia',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Cada 1 día')),
                  DropdownMenuItem(value: 3, child: Text('Cada 3 días')),
                  DropdownMenuItem(value: 7, child: Text('Cada 7 días')),
                  DropdownMenuItem(value: 30, child: Text('Cada 30 días')),
                ],
                onChanged: (val) {
                  if (val != null) _setAutoBackupFrequency(val);
                },
              ),
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('Exportar copia de seguridad'),
            subtitle: const Text('Guarda todos los datos en un archivo'),
            onTap: _exportBackup,
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('Importar copia de seguridad'),
            subtitle: const Text('Restaura una copia anterior'),
            onTap: _importBackup,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Desactivar complemento'),
            subtitle: const Text('Requerirá un nuevo código de activación'),
            onTap: _deactivate,
          ),
        ],
      ),
    );
  }
}
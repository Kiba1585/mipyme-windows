import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/license_service.dart';
import '../services/backup_service.dart';
import 'activation_screen.dart';

class SettingsScreen extends StatefulWidget {
  final Function(bool) onThemeChanged;   // <-- callback
  const SettingsScreen({super.key, required this.onThemeChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _storage = const FlutterSecureStorage();
  bool _darkMode = false;

  @override
  void initState() {
    super.initState();
    _loadDarkMode();
  }

  Future<void> _loadDarkMode() async {
    final value = await _storage.read(key: 'dark_mode');
    setState(() => _darkMode = value == 'true');
  }

  void _toggleDarkMode(bool val) {
    setState(() => _darkMode = val);
    _storage.write(key: 'dark_mode', value: val.toString());
    widget.onThemeChanged(val);
  }

  // … (métodos _deactivate, _exportBackup, _importBackup sin cambios)

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
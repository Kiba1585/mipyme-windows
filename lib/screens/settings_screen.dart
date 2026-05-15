import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/license_service.dart';
import '../services/backup_service.dart';
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
    ThemeScope.of(context)?.onThemeChanged(val);
  }

  Future<void> _deactivate() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desactivar complemento'),
        content: const Text('Se eliminará la licencia de esta PC. ¿Continuar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Desactivar')),
        ],
      ),
    );
    if (confirmed == true) {
      await LicenseService.deactivate();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const ActivationScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _exportBackup() async {
    try {
      final path = await WindowsBackupService.exportBackup();
      if (mounted) await WindowsBackupService.showSuccessDialog(context, path);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _importBackup() async {
    try {
      await WindowsBackupService.importBackup(context);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Base de datos restaurada. Reinicie.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

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
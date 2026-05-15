import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/license_service.dart';
import '../services/backup_service.dart';
import '../services/scheduled_backup_service.dart';
import '../core/theme/theme_scope.dart';
import 'activation_screen.dart';
import 'kiosk_lock_screen.dart';

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
  String? _kioskPin;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final dark = await _storage.read(key: 'dark_mode');
    final config = await ScheduledBackupService.getConfiguration();
    final kioskPin = await _storage.read(key: 'kiosk_pin');
    setState(() {
      _darkMode = dark == 'true';
      _autoBackupActive = config['active'] as bool;
      _autoBackupFrequency = config['frequencyDays'] as int;
      _kioskPin = kioskPin;
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

  Future<void> _setKioskPin() async {
    final controller = TextEditingController(text: _kioskPin ?? '');
    final newPin = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('PIN del modo quiosco'),
        content: TextField(
          controller: controller,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: const InputDecoration(labelText: 'Nuevo PIN', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (newPin != null) {
      await _storage.write(key: 'kiosk_pin', value: newPin.isEmpty ? null : newPin);
      setState(() => _kioskPin = newPin.isEmpty ? null : newPin);
    }
  }

  void _enterKiosk() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const KioskLockScreen()),
    );
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
          SwitchListTile(
            title: const Text('Respaldo automático'),
            subtitle: Text(
              _autoBackupActive ? 'Cada $_autoBackupFrequency día(s)' : 'Desactivado',
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
            leading: const Icon(Icons.supervised_user_circle),
            title: const Text('Modo Quiosco'),
            subtitle: Text(_kioskPin != null ? 'Activado (PIN configurado)' : 'Desactivado'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _setKioskPin,
          ),
          if (_kioskPin != null)
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text('Entrar al modo quiosco'),
              subtitle: const Text('Solo acceso a funciones básicas'),
              onTap: _enterKiosk,
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
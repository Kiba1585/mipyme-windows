import 'package:flutter/material.dart';
import '../services/license_service.dart';
import 'activation_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Acerca de MIPYME Windows'),
            subtitle: const Text('Versión 1.0.0'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Desactivar complemento'),
            subtitle: const Text('Requerirá un nuevo código de activación'),
            onTap: () async {
              await LicenseService.deactivate();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const ActivationScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
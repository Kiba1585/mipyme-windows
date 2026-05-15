import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'kiosk_screen.dart';
import 'dashboard_screen.dart';

class KioskLockScreen extends StatefulWidget {
  const KioskLockScreen({super.key});

  @override
  State<KioskLockScreen> createState() => _KioskLockScreenState();
}

class _KioskLockScreenState extends State<KioskLockScreen> {
  final _pinCtrl = TextEditingController();
  final _storage = const FlutterSecureStorage();
  String? _error;

  Future<void> _validatePin() async {
    final storedPin = await _storage.read(key: 'kiosk_pin');
    if (storedPin == null) {
      // Si no hay PIN configurado, entrar directamente
      _enterKiosk();
      return;
    }
    if (_pinCtrl.text == storedPin) {
      _enterKiosk();
    } else {
      setState(() => _error = 'PIN incorrecto');
    }
  }

  void _enterKiosk() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => KioskScreen(
          onExit: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const DashboardScreen()),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Modo Quiosco')),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock, size: 64, color: Colors.orange),
            const SizedBox(height: 24),
            const Text('Ingrese el PIN del quiosco para continuar'),
            const SizedBox(height: 16),
            TextField(
              controller: _pinCtrl,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'PIN',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _validatePin(),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _validatePin,
              child: const Text('Entrar'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Volver al dashboard'),
            ),
          ],
        ),
      ),
    );
  }
}
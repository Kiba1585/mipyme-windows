import 'package:flutter/material.dart';
import '../services/license_service.dart';

class ActivationScreen extends StatefulWidget {
  const ActivationScreen({super.key});

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  final _codeController = TextEditingController();
  bool _loading = false;
  String? _error;

  void _activate() {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Ingrese el código de activación');
      return;
    }

    setState(() { _loading = true; _error = null; });

    final valid = LicenseService.validateActivationCode(code);
    if (valid) {
      // Navegar al dashboard (próximamente)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Activación exitosa')),
      );
    } else {
      setState(() => _error = 'Código inválido o expirado');
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activar MIPYME Windows')),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock, size: 80, color: Colors.blue),
            const SizedBox(height: 32),
            const Text(
              'Introduzca el código de activación generado en la app MIPYME',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Código de activación',
                border: OutlineInputBorder(),
              ),
              autocorrect: false,
              maxLines: 3,
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _loading ? null : _activate,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('ACTIVAR'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
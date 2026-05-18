import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../services/license_service.dart';
import 'dashboard_screen.dart';

class ActivationScreen extends StatefulWidget {
  const ActivationScreen({super.key});

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  final _codeController = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _activate() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Ingrese el código de activación');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final info = LicenseService.validateActivationCode(code);
      if (info != null) {
        await LicenseService.addLicense(info);

        // Guardar archivo de chequeo con hash criptográfico
        final hash = sha256
            .convert(utf8.encode('${info.ownerName}|${info.phoneNumber}|${info.expiryDate.toIso8601String()}'))
            .toString();
        final dir = await getApplicationDocumentsDirectory();
        final checkFile = File(p.join(dir.path, 'license_check.txt'));
        await checkFile.writeAsString(hash);

        if (!mounted) return;

        if (Navigator.canPop(context)) {
          Navigator.pop(context, true);   // añadir dueño desde dashboard
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
          );
        }
      } else {
        setState(() => _error = 'Código inválido o expirado');
      }
    } catch (e) {
      setState(() => _error = 'Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activar MIPYME Windows'),
      ),
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
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : const Text('ACTIVAR'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
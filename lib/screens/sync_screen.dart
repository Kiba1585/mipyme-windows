import 'package:flutter/material.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sincronizar con Móvil')),
      body: const Center(
        child: Text('Módulo en desarrollo. Próximamente disponible.'),
      ),
    );
  }
}
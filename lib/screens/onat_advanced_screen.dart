import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/onat_forms_service.dart';
import '../services/reminder_service.dart';

class OnatAdvancedScreen extends StatefulWidget {
  const OnatAdvancedScreen({super.key});

  @override
  State<OnatAdvancedScreen> createState() => _OnatAdvancedScreenState();
}

class _OnatAdvancedScreenState extends State<OnatAdvancedScreen> {
  DateTime _selectedDate = DateTime.now();
  Map<String, dynamic>? _upcomingDeadline;

  @override
  void initState() {
    super.initState();
    _loadReminder();
  }

  Future<void> _loadReminder() async {
    final deadline = await ReminderService.getUpcomingDeadline();
    setState(() => _upcomingDeadline = deadline);
  }

  Future<void> _setReminder() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      await ReminderService.setTaxDeadline(picked);
      _loadReminder();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recordatorio guardado')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final period = DateFormat('yyyy-MM').format(_selectedDate);

    return Scaffold(
      appBar: AppBar(title: const Text('ONAT - Trámites Avanzados')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recordatorio
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.notifications_active, color: Colors.red),
                        const SizedBox(width: 8),
                        const Text('Próximo vencimiento',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _upcomingDeadline != null
                        ? Text(
                            '${_upcomingDeadline!['deadline'].toString().substring(0, 10)}')
                        : const Text('No hay recordatorios configurados'),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _setReminder,
                      icon: const Icon(Icons.add_alert),
                      label: const Text('Configurar recordatorio'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Formularios
            const Text('Generar Formularios',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildFormButton('DJ-01 - Declaración de Ingresos', Icons.description, () {
              OnatFormsService.generateDj01(period);
            }),
            const SizedBox(height: 12),
            _buildFormButton('DJ-02 - Declaración de Empleadores', Icons.people, () {
              OnatFormsService.generateDj02(period);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFormButton(String label, IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}

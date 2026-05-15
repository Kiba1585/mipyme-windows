import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/onat_forms_service.dart';
import '../services/reminder_service.dart';
import '../services/calendar_service.dart';
import '../services/database_service.dart';

class OnatAdvancedScreen extends StatefulWidget {
  const OnatAdvancedScreen({super.key});

  @override
  State<OnatAdvancedScreen> createState() => _OnatAdvancedScreenState();
}

class _OnatAdvancedScreenState extends State<OnatAdvancedScreen> {
  DateTime _selectedDate = DateTime.now();
  Map<String, dynamic>? _upcomingDeadline;
  double _taxAmount = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final deadline = await ReminderService.getUpcomingDeadline();
      final period = DateFormat('yyyy-MM').format(_selectedDate);
      final startDate = '$period-01';
      final endDate = '$period-31';
      final income = await DatabaseService.getTotalByType('income', startDate, endDate);
      final expenses = await DatabaseService.getTotalByType('expense', startDate, endDate);
      final netIncome = income - expenses;
      setState(() {
        _upcomingDeadline = deadline;
        _taxAmount = netIncome > 0 ? netIncome * 0.05 : 0;
      });
    } catch (e) {
      _error = 'Error al cargar datos ONAT.\n$e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
      _loadData();
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      const SizedBox(height: 32),
                      const Text('Calendario',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      _buildFormButton('Agregar vencimiento al Calendario de Windows',
                          Icons.calendar_today, () async {
                        final dueDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 20);
                        await CalendarService.addTaxDeadlineToCalendar(
                          period: period,
                          dueDate: dueDate,
                          taxAmount: _taxAmount,
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Archivo de calendario generado. Ábralo para agregar el evento.')),
                          );
                        }
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

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error, size: 48, color: Colors.red),
          const SizedBox(height: 8),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
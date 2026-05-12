import 'package:flutter/material.dart';
import '../services/license_service.dart';
import '../models/license_info.dart';
import 'import_screen.dart';
import 'reports_screen.dart';
import 'tax_screen.dart';
import 'financial_records_screen.dart';
import 'activation_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  LicenseInfo? _license;
  @override
  void initState() { super.initState(); _loadLicense(); }
  Future<void> _loadLicense() async { final license = await LicenseService.getStoredInfo(); setState(() => _license = license); }
  void _logout() { LicenseService.deactivate(); Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ActivationScreen())); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_license?.ownerName ?? 'MIPYME Windows'), actions: [IconButton(icon: const Icon(Icons.logout), onPressed: _logout, tooltip: 'Desactivar')]),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bienvenido, ${_license?.ownerName ?? "Usuario"}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Plan: ${_license?.planType ?? "N/A"}'),
            const SizedBox(height: 4),
            if (_license != null) Text('Vence: ${_license!.expiryDate.toLocal().toString().substring(0, 10)}'),
            const SizedBox(height: 32),
            const Text('Acciones rápidas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
            const SizedBox(height: 16),
            _buildButton(Icons.upload_file, 'Importar datos (.mipyme)', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ImportScreen()))),
            const SizedBox(height: 12),
            _buildButton(Icons.bar_chart, 'Reportes financieros', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen()))),
            const SizedBox(height: 12),
            _buildButton(Icons.account_balance, 'Impuestos (ONAT)', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TaxScreen()))),
            const SizedBox(height: 12),
            _buildButton(Icons.receipt, 'Registros financieros', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FinancialRecordsScreen()))),
            const Spacer(),
            Center(child: Text('v1.0.0 - Complemento Windows', style: TextStyle(color: Colors.grey.shade600))),
          ],
        ),
      ),
    );
  }
  Widget _buildButton(IconData icon, String label, VoidCallback onPressed) => SizedBox(width: double.infinity, height: 48, child: OutlinedButton.icon(onPressed: onPressed, icon: Icon(icon), label: Text(label)));
}
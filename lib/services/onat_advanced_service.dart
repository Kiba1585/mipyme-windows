import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'database_service.dart';

class OnatAdvancedService {
  /// Genera el PDF de la declaración jurada (modelo simplificado DJ-01).
  static Future<void> exportDj01(String period) async {
    // Obtener datos del período
    final startDate = '$period-01';
    final endDate = '$period-31';
    final grossIncome = await DatabaseService.getTotalByType('income', startDate, endDate);
    final totalExpenses = await DatabaseService.getTotalByType('expense', startDate, endDate);
    final netIncome = grossIncome - totalExpenses;
    final taxAmount = netIncome > 0 ? netIncome * 0.05 : 0.0;
    final socialSecurity = grossIncome * 0.02;
    final totalTax = taxAmount + socialSecurity;

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(level: 0, text: 'Declaración Jurada - Período $period'),
              pw.SizedBox(height: 20),
              pw.Text('Contribuyente: ${await _getBusinessName()}'),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Text('1. Ingresos Brutos: \$${grossIncome.toStringAsFixed(2)}'),
              pw.Text('2. Gastos Deducibles: \$${totalExpenses.toStringAsFixed(2)}'),
              pw.Text('3. Ingreso Neto (1-2): \$${netIncome.toStringAsFixed(2)}'),
              pw.SizedBox(height: 10),
              pw.Text('4. Impuesto sobre Ingresos (5%): \$${taxAmount.toStringAsFixed(2)}'),
              pw.Text('5. Seguridad Social (2% s/Ingresos): \$${socialSecurity.toStringAsFixed(2)}'),
              pw.Divider(),
              pw.Text('TOTAL A PAGAR: \$${totalTax.toStringAsFixed(2)}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
              pw.SizedBox(height: 30),
              pw.Text('Firma del Contribuyente: ___________________________'),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  static Future<String> _getBusinessName() async {
    // Podrías leerlo de la configuración, pero para simplificar retornamos un placeholder.
    return 'Nombre del Negocio';
  }
}

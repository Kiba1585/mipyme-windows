import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'database_service.dart';

class OnatAdvancedService {
  /// Genera el PDF del formulario DJ-01 (Declaración Jurada de Ingresos).
  static Future<void> generateDj01(String period) async {
    final startDate = '$period-01';
    final endDate = '$period-31';

    final grossIncome = await DatabaseService.getTotalByType('income', startDate, endDate);
    final totalExpenses = await DatabaseService.getTotalByType('expense', startDate, endDate);
    final netIncome = grossIncome - totalExpenses;
    const incomeTaxRate = 0.05;
    const socialSecurityRate = 0.02;
    final incomeTax = netIncome > 0 ? netIncome * incomeTaxRate : 0.0;
    final socialSecurity = grossIncome * socialSecurityRate;
    final totalToPay = incomeTax + socialSecurity;

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(level: 0, text: 'DJ-01 - Declaración Jurada de Ingresos'),
              pw.Text('Período: $period'),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Text('1. Ingresos Brutos: \$${grossIncome.toStringAsFixed(2)}'),
              pw.Text('2. Gastos Deducibles: \$${totalExpenses.toStringAsFixed(2)}'),
              pw.Text('3. Utilidad / Pérdida (1-2): \$${netIncome.toStringAsFixed(2)}'),
              pw.SizedBox(height: 10),
              pw.Text('4. Impuesto sobre Ingresos (5%): \$${incomeTax.toStringAsFixed(2)}'),
              pw.Text('5. Seguridad Social (2%): \$${socialSecurity.toStringAsFixed(2)}'),
              pw.Divider(),
              pw.Text('TOTAL A PAGAR: \$${totalToPay.toStringAsFixed(2)}',
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

  /// Genera el PDF del formulario DJ-02 (Declaración de Empleadores).
  static Future<void> generateDj02(String period) async {
    final startDate = '$period-01';
    final endDate = '$period-31';
    final totalPayroll = await DatabaseService.getTotalByType('payroll', startDate, endDate);
    final employees = await DatabaseService.getEmployees();
    final workerCount = employees.length;

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(level: 0, text: 'DJ-02 - Declaración de Empleadores'),
              pw.Text('Período: $period'),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Text('Cantidad de Trabajadores: $workerCount'),
              pw.Text('Total Pagado en Nóminas: \$${totalPayroll.toStringAsFixed(2)}'),
              pw.SizedBox(height: 10),
              pw.Text('Contribución Especial (1%): \$${(totalPayroll * 0.01).toStringAsFixed(2)}'),
              pw.SizedBox(height: 30),
              pw.Text('Firma del Empleador: ___________________________'),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}
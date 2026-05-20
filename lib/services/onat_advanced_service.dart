import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'database_service.dart';

class OnatAdvancedService {
  /// Genera el PDF del formulario DJ-01 con columnas Real / Reportado.
  static Future<void> generateDj01(
    String period, {
    double? realIncome,
    double? realExpenses,
    double? reportedIncome,
    double? reportedExpenses,
  }) async {
    final startDate = '$period-01';
    final endDate = '$period-31';

    // Si no se pasan valores, se cargan de la base de datos
    final grossIncomeReal = realIncome ??
        await DatabaseService.getTotalByType('income', startDate, endDate);
    final totalExpensesReal = realExpenses ??
        await DatabaseService.getTotalByType('expense', startDate, endDate);
    final netIncomeReal = grossIncomeReal - totalExpensesReal;

    // Valores reportados (si no se pasan, se asume igual al real)
    final grossIncomeReported = reportedIncome ?? grossIncomeReal;
    final totalExpensesReported = reportedExpenses ?? totalExpensesReal;
    final netIncomeReported = grossIncomeReported - totalExpensesReported;

    const incomeTaxRate = 0.05;
    const socialSecurityRate = 0.02;

    final incomeTaxReal = netIncomeReal > 0 ? netIncomeReal * incomeTaxRate : 0.0;
    final socialSecurityReal = grossIncomeReal * socialSecurityRate;
    final totalToPayReal = incomeTaxReal + socialSecurityReal;

    final incomeTaxReported = netIncomeReported > 0 ? netIncomeReported * incomeTaxRate : 0.0;
    final socialSecurityReported = grossIncomeReported * socialSecurityRate;
    final totalToPayReported = incomeTaxReported + socialSecurityReported;

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
              // Encabezados
              pw.Row(
                children: [
                  pw.Expanded(child: pw.Text('Concepto')),
                  pw.Expanded(child: pw.Text('Real', textAlign: pw.TextAlign.right)),
                  pw.Expanded(child: pw.Text('Reportado', textAlign: pw.TextAlign.right)),
                ],
              ),
              pw.Divider(),
              pw.SizedBox(height: 6),
              _buildRow('Ingresos Brutos', grossIncomeReal, grossIncomeReported),
              _buildRow('Gastos Deducibles', totalExpensesReal, totalExpensesReported),
              _buildRow('Utilidad / Pérdida', netIncomeReal, netIncomeReported),
              pw.SizedBox(height: 10),
              _buildRow('Impuesto s/ Ingresos (5%)', incomeTaxReal, incomeTaxReported),
              _buildRow('Seguridad Social (2%)', socialSecurityReal, socialSecurityReported),
              pw.Divider(),
              _buildRow('TOTAL A PAGAR', totalToPayReal, totalToPayReported,
                  bold: true),
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

  static pw.Widget _buildRow(String label, double real, double reported, {bool bold = false}) {
    final style = pw.TextStyle(fontWeight: bold ? pw.FontWeight.bold : null);
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.Expanded(child: pw.Text(label, style: style)),
          pw.Expanded(
              child: pw.Text('\$${real.toStringAsFixed(2)}',
                  textAlign: pw.TextAlign.right, style: style)),
          pw.Expanded(
              child: pw.Text('\$${reported.toStringAsFixed(2)}',
                  textAlign: pw.TextAlign.right, style: style)),
        ],
      ),
    );
  }

  /// Genera el PDF del formulario DJ-02 (Declaración de Empleadores).
  static Future<void> generateDj02(String period) async {
    final startDate = '$period-01';
    final endDate = '$period-31';
    final totalPayroll =
        await DatabaseService.getTotalByType('payroll', startDate, endDate);
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
              pw.Text(
                  'Total Pagado en Nóminas: \$${totalPayroll.toStringAsFixed(2)}'),
              pw.SizedBox(height: 10),
              pw.Text(
                  'Contribución Especial (1%): \$${(totalPayroll * 0.01).toStringAsFixed(2)}'),
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
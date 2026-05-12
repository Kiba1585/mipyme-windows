import 'dart:math';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/financial_data.dart';

class ReportService {
  /// Genera un PDF de reporte mensual básico.
  static Future<void> exportMonthlyPdf(MonthlyReport report) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(level: 0, text: 'Reporte Mensual - ${report.month}'),
              pw.SizedBox(height: 20),
              pw.Text('Total Ventas: \$${report.totalSales.toStringAsFixed(2)}'),
              pw.Text('Gastos: \$${report.expenses.toStringAsFixed(2)}'),
              pw.Divider(),
              pw.Text('Ganancia Neta: \$${report.netProfit.toStringAsFixed(2)}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  /// Calcula un reporte mensual simple a partir de ventas diarias y gastos.
  static MonthlyReport calculateMonthly(
    String month,
    List<DailySales> dailySales,
    double totalExpenses,
  ) {
    final totalSales = dailySales.fold(0.0, (sum, d) => sum + d.total);
    return MonthlyReport(
      month: month,
      totalSales: totalSales,
      expenses: totalExpenses,
      netProfit: totalSales - totalExpenses,
    );
  }
}
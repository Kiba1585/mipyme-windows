import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'database_service.dart';

class ExportExcelService {
  /// Exporta los registros financieros a un archivo Excel (.xlsx).
  static Future<String> exportFinancialRecordsToExcel() async {
    final records = await DatabaseService.getFinancialRecords();
    if (records.isEmpty) throw Exception('No hay registros para exportar');

    final excel = Excel.createExcel();
    final sheet = excel['Financiero'];

    // Encabezados
    sheet.appendRow([
      TextCellValue('Fecha'),
      TextCellValue('Tipo'),
      TextCellValue('Categoría'),
      TextCellValue('Monto'),
      TextCellValue('Descripción'),
    ]);

    // Datos
    for (final record in records) {
      sheet.appendRow([
        TextCellValue(record['date'] as String),
        TextCellValue(record['type'] as String),
        TextCellValue(record['category'] as String),
        DoubleCellValue((record['amount'] as num).toDouble()),
        TextCellValue(record['description'] as String? ?? ''),
      ]);
    }

    // Guardar archivo
    final fileData = excel.encode();
    final outputPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Seleccione dónde guardar el Excel',
      fileName: 'mipyme_financiero_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx',
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (outputPath == null) throw Exception('No se seleccionó ninguna ubicación');
    final file = File(outputPath);
    await file.writeAsBytes(fileData!);
    return outputPath;
  }
}
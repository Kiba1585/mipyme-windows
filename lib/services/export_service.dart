import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'database_service.dart';

class ExportService {
  /// Exporta los registros financieros a un archivo CSV.
  /// El usuario elige dónde guardarlo mediante el diálogo de guardar archivo.
  static Future<String> exportFinancialRecordsToCsv() async {
    // Obtener todos los registros financieros
    final records = await DatabaseService.getFinancialRecords();

    if (records.isEmpty) {
      throw Exception('No hay registros financieros para exportar');
    }

    // Crear las filas del CSV
    final List<List<dynamic>> rows = [
      ['Fecha', 'Tipo', 'Categoría', 'Monto', 'Descripción'],
    ];

    for (final record in records) {
      rows.add([
        record['date'] as String,
        record['type'] as String,
        record['category'] as String,
        (record['amount'] as num).toDouble(),
        record['description'] as String? ?? '',
      ]);
    }

    // Convertir a CSV
    final csvData = const ListToCsvConverter().convert(rows);

    // Diálogo para guardar archivo
    final outputPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Seleccione dónde guardar el reporte CSV',
      fileName: 'mipyme_financiero_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv',
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (outputPath == null) {
      throw Exception('No se seleccionó ninguna ubicación');
    }

    // Guardar archivo
    final file = File(outputPath);
    await file.writeAsString(csvData);

    return outputPath;
  }

  /// Exporta los datos del archivo .mipyme importado a un JSON legible.
  static Future<String> exportMipymeDataToJson(Map<String, dynamic> data) async {
    final outputPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Seleccione dónde guardar los datos',
      fileName: 'mipyme_datos_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.json',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (outputPath == null) {
      throw Exception('No se seleccionó ninguna ubicación');
    }

    final file = File(outputPath);
    final encoder = const JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(data));

    return outputPath;
  }
}
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class DataImportService {
  /// Abre un diálogo para seleccionar un archivo .mipyme y devuelve su contenido JSON.
  static Future<Map<String, dynamic>?> importMipymeFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mipyme'],
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return null;

    final file = File(result.files.single.path!);
    if (!await file.exists()) return null;

    final content = await file.readAsString();
    try {
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Guarda los datos importados en un archivo local para uso posterior.
  static Future<File> saveLocalData(Map<String, dynamic> data) async {
    final dir = await getApplicationDocumentsDirectory();
    final localFile = File(p.join(dir.path, 'mipyme_data.json'));
    await localFile.writeAsString(jsonEncode(data));
    return localFile;
  }

  /// Carga los datos guardados localmente.
  static Future<Map<String, dynamic>?> loadLocalData() async {
    final dir = await getApplicationDocumentsDirectory();
    final localFile = File(p.join(dir.path, 'mipyme_data.json'));
    if (!await localFile.exists()) return null;
    final content = await localFile.readAsString();
    try {
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
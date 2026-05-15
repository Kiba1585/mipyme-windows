import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../services/license_service.dart';
import '../services/database_service.dart';

class DataImportService {
  static Future<Map<String, dynamic>?> importMipymeFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mipyme'],
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return null;

    final file = File(result.files.single.path!);
    if (!await file.exists()) return null;

    final encryptedContent = await file.readAsString();
    final license = await LicenseService.getStoredInfo();
    if (license == null) throw Exception('Licencia no encontrada');

    final secretKey = _deriveKey(license.ownerName, license.deviceId, license.expiryDate.toIso8601String());
    final decrypted = _decryptData(encryptedContent, secretKey);
    final data = jsonDecode(decrypted) as Map<String, dynamic>;

    if (data.containsKey('products')) {
      final products = (data['products'] as List).cast<Map<String, dynamic>>();
      await DatabaseService.insertProducts(products);
    }

    // Guardar localmente para uso futuro
    await saveLocalData(data);

    return data;
  }

  static Future<void> saveLocalData(Map<String, dynamic> data) async {
    final dir = await getApplicationDocumentsDirectory();
    final localFile = File(p.join(dir.path, 'mipyme_data.json'));
    await localFile.writeAsString(jsonEncode(data));
  }

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

  static enc.Key _deriveKey(String owner, String deviceId, String expiry) {
    final hash = sha256.convert(utf8.encode('$owner$deviceId$expiry')).toString().substring(0, 32);
    return enc.Key.fromUtf8(hash);
  }

  static String _decryptData(String base64Data, enc.Key key) {
    final combined = base64Decode(base64Data);
    final iv = enc.IV(Uint8List.fromList(combined.sublist(0, 16)));
    final ciphertext = combined.sublist(16);
    final encrypter = enc.Encrypter(enc.AES(key));
    return encrypter.decrypt(enc.Encrypted(ciphertext), iv: iv);
  }
}
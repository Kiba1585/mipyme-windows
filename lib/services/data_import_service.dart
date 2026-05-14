import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:crypto/crypto.dart';
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

    // Procesar productos si están presentes
    if (data.containsKey('products')) {
      final products = (data['products'] as List).cast<Map<String, dynamic>>();
      await DatabaseService.insertProducts(products);
    }
    // Aquí puedes añadir más tipos de datos en el futuro

    return data;
  }

  static enc.Key _deriveKey(String owner, String deviceId, String expiry) {
    final hash = sha256
        .convert(utf8.encode('$owner$deviceId$expiry'))
        .toString()
        .substring(0, 32);
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
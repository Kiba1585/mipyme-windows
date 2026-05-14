import 'dart:convert';
import 'dart:io';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import '../services/license_service.dart';

class InventoryExportService {
  /// Exporta una lista de productos a un archivo .mipyme cifrado.
  static Future<String> exportInventoryForMobile(List<Map<String, dynamic>> products) async {
    final license = await LicenseService.getStoredInfo();
    if (license == null) throw Exception('No hay licencia activa');

    final secretKey = _deriveKey(
      license.ownerName,
      license.deviceId,
      license.expiryDate.toIso8601String(),
    );

    final data = jsonEncode({
      'type': 'inventory_bulk',
      'products': products,
      'export_date': DateTime.now().toIso8601String(),
    });

    final encrypted = _encryptData(data, secretKey);

    // Diálogo para guardar archivo
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Guardar inventario para móvil',
      fileName: 'inventario_${DateTime.now().millisecondsSinceEpoch}.mipyme',
      type: FileType.custom,
      allowedExtensions: ['mipyme'],
    );

    if (path == null) throw Exception('No se seleccionó ninguna ubicación');
    final file = File(path);
    await file.writeAsString(encrypted);
    return file.path;
  }

  static enc.Key _deriveKey(String owner, String deviceId, String expiry) {
    final hash = sha256
        .convert(utf8.encode('$owner$deviceId$expiry'))
        .toString()
        .substring(0, 32);
    return enc.Key.fromUtf8(hash);
  }

  static String _encryptData(String plainText, enc.Key key) {
    final encrypter = enc.Encrypter(enc.AES(key));
    final iv = enc.IV.fromLength(16);
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    final combined = iv.bytes + encrypted.bytes;
    return base64Encode(combined);
  }
}
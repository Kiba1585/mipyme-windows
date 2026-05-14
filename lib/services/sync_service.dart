import 'dart:convert';
import 'dart:io';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../models/license_info.dart';
import '../services/license_service.dart';
import '../services/database_service.dart';

class SyncService {

  // ... (métodos existentes)

  /// Exporta los datos de la base de datos local a un archivo .mipyme cifrado.
  static Future<String> exportForMobile(BuildContext context) async {
    final license = await LicenseService.getStoredInfo();
    if (license == null) throw Exception('No hay licencia activa');

    // Derivar clave secreta (idéntica a la del móvil)
    final secretKey = _deriveKey(
      license.ownerName,
      license.deviceId,
      license.expiryDate.toIso8601String(),
    );

    // Recopilar datos financieros
    final db = await DatabaseService.database;
    final records = await DatabaseService.getFinancialRecords();
    final suppliers = await DatabaseService.getSuppliers();
    final employees = await DatabaseService.getEmployees();
    final assets = await DatabaseService.getAssets();

    final data = jsonEncode({
      'financial_records': records,
      'suppliers': suppliers.map((s) => s.toMap()).toList(),
      'employees': employees.map((e) => e.toMap()).toList(),
      'assets': assets.map((a) => a.toMap()).toList(),
      'version': 1,
      'export_date': DateTime.now().toIso8601String(),
    });

    // Cifrar
    final encrypted = _encryptData(data, secretKey);

    // Guardar con diálogo de archivo
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Guardar archivo para el móvil',
      fileName: 'mipyme_pc_export_${DateTime.now().millisecondsSinceEpoch}.mipyme',
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
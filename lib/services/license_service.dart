import 'dart:convert';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/license_info.dart';

class LicenseService {
  static const _storage = FlutterSecureStorage();
  static const _keyLicenseList = 'license_list';
  static const _keyActiveOwner = 'active_owner';

  // CLAVE PÚBLICA DEL DISTRIBUIDOR
  static const String _distributorPublicKeyPem =
      '-----BEGIN RSA PUBLIC KEY-----\n'
      'yzLm8/QmULq+Qa8RhW260tTOhsZwI7by8v+CmMaRP9fksX1St+0eRV/l8Q72s3bqKzTbcl7+irLhsPLaVJKGCeceFN0aZM77Y4dVIoSltBBhMOQS0G33YAsj/5817HZp4oKxprZN22wk8/XP8v2FACHGeQOHisfvBL83h5a3DwQKm2yta1r3mKJI9ujWT5w68fMokj7fYrdToNdIzX2wetk70FBDLf6XPPksY5fgBFE8dg9/JM0D8cqURd/W3cSU5e8EqAvtjKiQ1gJoUyTR0dr4ufDLMNcl/Tcpw3Ma8pHJ5uhGoG6Rv4NNbwJxyzyt6wlTtqaekb6/2cnMyrSWEw==\n'
      'AQAB\n'
      '-----END RSA PUBLIC KEY-----';

  static RSAPublicKey? _cachedPublicKey;
  static RSAPublicKey get _publicKey {
    if (_cachedPublicKey != null) return _cachedPublicKey!;
    _cachedPublicKey = _parsePublicKey(_distributorPublicKeyPem);
    return _cachedPublicKey!;
  }

  static RSAPublicKey _parsePublicKey(String pem) {
    final lines = pem
        .replaceAll('-----BEGIN RSA PUBLIC KEY-----', '')
        .replaceAll('-----END RSA PUBLIC KEY-----', '')
        .trim()
        .split('\n')
        .where((line) => line.isNotEmpty)
        .toList();
    if (lines.length < 2) throw Exception('Formato de clave pública inválido');
    final modulusBytes = base64Decode(lines[0]);
    final exponentBytes = base64Decode(lines[1]);
    final modulus = _bytesToBigInt(Uint8List.fromList(modulusBytes));
    final exponent = _bytesToBigInt(Uint8List.fromList(exponentBytes));
    return RSAPublicKey(modulus, exponent);
  }

  static BigInt _bytesToBigInt(Uint8List bytes) {
    return BigInt.parse(
        bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
        radix: 16);
  }

  // ==================== GESTIÓN DE MÚLTIPLES DUEÑOS ====================

  static Future<List<LicenseInfo>> getAllOwners() async {
    final jsonStr = await _storage.read(key: _keyLicenseList);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    final list = jsonDecode(jsonStr) as List<dynamic>;
    return list.map((e) => LicenseInfo.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<void> _saveOwners(List<LicenseInfo> owners) async {
    final jsonStr = jsonEncode(owners.map((e) => e.toJson()).toList());
    await _storage.write(key: _keyLicenseList, value: jsonStr);
  }

  static Future<LicenseInfo?> getActiveOwner() async {
    final owners = await getAllOwners();
    if (owners.isEmpty) return null;
    final activeIndexStr = await _storage.read(key: _keyActiveOwner);
    final activeIndex = int.tryParse(activeIndexStr ?? '0') ?? 0;
    if (activeIndex >= 0 && activeIndex < owners.length) {
      return owners[activeIndex];
    }
    if (owners.isNotEmpty) {
      await _storage.write(key: _keyActiveOwner, value: '0');
      return owners.first;
    }
    return null;
  }

  static Future<void> setActiveOwner(int index) async {
    await _storage.write(key: _keyActiveOwner, value: index.toString());
  }

  static Future<void> addLicense(LicenseInfo info) async {
    final owners = await getAllOwners();
    final existingIndex = owners.indexWhere(
      (o) => o.ownerName == info.ownerName && o.phoneNumber == info.phoneNumber,
    );
    if (existingIndex != -1) {
      owners[existingIndex] = info;
      await _saveOwners(owners);
      await setActiveOwner(existingIndex);
    } else {
      owners.add(info);
      await _saveOwners(owners);
      await setActiveOwner(owners.length - 1);
    }
  }

  static Future<void> removeOwner(int index) async {
    final owners = await getAllOwners();
    if (index >= 0 && index < owners.length) {
      owners.removeAt(index);
      await _saveOwners(owners);
      final currentActive = int.tryParse(
            await _storage.read(key: _keyActiveOwner) ?? '0',
          ) ??
          0;
      if (currentActive >= owners.length) {
        await setActiveOwner(owners.length - 1);
      } else if (currentActive == index) {
        await setActiveOwner(0);
      }
    }
  }

  static Future<bool> isActivated() async {
    final owners = await getAllOwners();
    return owners.isNotEmpty;
  }

  // ==================== VALIDACIÓN DE CÓDIGO (SIN EXIGIR 'type') ====================

  static LicenseInfo? validateActivationCode(String code) {
    // 1) Intentar decodificar como base64 simple (código sin firma)
    try {
      final payloadBytes = base64Decode(code.trim());
      final payloadString = utf8.decode(payloadBytes);
      final json = jsonDecode(payloadString) as Map<String, dynamic>;
      // No exigimos 'type', simplemente extraemos los campos esperados
      return _parseLicenseInfo(json);
    } catch (_) {}

    // 2) Validación con RSA (formato payload.firma) → el que genera LicGenerator
    try {
      final parts = code.split('.');
      if (parts.length != 2) return null;
      final payloadBase64 = parts[0];
      final signatureBase64 = parts[1];

      final payloadBytes = base64Decode(payloadBase64);
      final payloadString = utf8.decode(payloadBytes);
      final signatureBytes = Uint8List.fromList(base64Decode(signatureBase64));

      final signer = RSASigner(SHA256Digest(), '0609608648016503040201');
      signer.init(false, PublicKeyParameter<RSAPublicKey>(_publicKey));
      final valid = signer.verifySignature(
          Uint8List.fromList(utf8.encode(payloadString)),
          RSASignature(signatureBytes));
      if (!valid) return null;

      final json = jsonDecode(payloadString) as Map<String, dynamic>;
      return _parseLicenseInfo(json);
    } catch (_) {}

    return null;
  }

  /// Extrae los campos comunes de una licencia, ignorando el tipo.
  static LicenseInfo? _parseLicenseInfo(Map<String, dynamic> json) {
    try {
      return LicenseInfo(
        ownerName: json['owner_name'] as String,
        phoneNumber: json['phone'] as String,
        maxSellers: json['max_sellers'] as int? ?? 1,
        expiryDate: DateTime.parse(json['expiry_date'] as String),
        planType: json['plan'] as String? ?? '',
        deviceId: json['device_id'] as String? ?? '',
      );
    } catch (_) {
      return null;
    }
  }

  // ==================== COMPATIBILIDAD ====================
  static Future<LicenseInfo?> getStoredInfo() async => getActiveOwner();

  static Future<void> saveActivation(String code) async {
    final info = validateActivationCode(code);
    if (info != null) {
      await addLicense(info);
    }
  }

  static Future<void> deactivate() async {
    await _storage.delete(key: _keyLicenseList);
    await _storage.delete(key: _keyActiveOwner);
  }
}
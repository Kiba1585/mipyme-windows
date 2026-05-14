import 'dart:convert';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/license_info.dart';

class LicenseService {
  static const _storage = FlutterSecureStorage();
  static const _keyActivated = 'windows_activated';
  static const _keyLicenseInfo = 'license_info';

  // CLAVE PÚBLICA DEL DISTRIBUIDOR (debe coincidir con LicGenerator)
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

  static Future<bool> isActivated() async {
    final val = await _storage.read(key: _keyActivated);
    return val == 'true';
  }

  static Future<LicenseInfo?> getStoredInfo() async {
    try {
      final json = await _storage.read(key: _keyLicenseInfo);
      if (json == null) return null;
      return LicenseInfo.fromJson(jsonDecode(json));
    } catch (_) {
      return null;
    }
  }

  static LicenseInfo? validateActivationCode(String code) {
    try {
      // Intentar primero como nuevo formato (base64 sin firma)
      final payloadBytes = base64Decode(code.trim());
      final payloadString = utf8.decode(payloadBytes);
      final json = jsonDecode(payloadString) as Map<String, dynamic>;
      if (json['type'] == 'windows_activation') {
        return LicenseInfo(
          ownerName: json['owner_name'] as String,
          phoneNumber: json['phone'] as String,
          maxSellers: 1,
          expiryDate: DateTime.parse(json['expiry_date'] as String),
          planType: json['plan'] as String,
          deviceId: json['device_id'] as String,
        );
      }
    } catch (_) {
      // Si falla, intentar con formato antiguo (payload.firma)
    }

    // Validación con RSA (formato antiguo)
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
      if (json['type'] == 'windows_activation') {
        return LicenseInfo(
          ownerName: json['owner_name'] as String,
          phoneNumber: json['phone'] as String,
          maxSellers: 1,
          expiryDate: DateTime.parse(json['expiry_date'] as String),
          planType: json['plan'] as String,
          deviceId: json['device_id'] as String,
        );
      }
    } catch (_) {}

    return null;
  }

  static Future<void> saveActivation(String code) async {
    try {
      final parts = code.contains('.') ? code.split('.') : ['', code];
      final payloadBytes = base64Decode(parts.length == 2 ? parts[0] : parts[1]);
      final payloadString = utf8.decode(payloadBytes);
      final json = jsonDecode(payloadString) as Map<String, dynamic>;

      await _storage.write(key: _keyActivated, value: 'true');
      await _storage.write(key: _keyLicenseInfo, value: jsonEncode(json));
    } catch (e) {
      // Si no se puede decodificar, al menos guardamos la activación
      await _storage.write(key: _keyActivated, value: 'true');
      rethrow;
    }
  }

  static Future<void> deactivate() async {
    await _storage.delete(key: _keyActivated);
    await _storage.delete(key: _keyLicenseInfo);
  }
}

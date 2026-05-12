import 'dart:convert';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import 'package:crypto/crypto.dart';

class LicenseService {
  // Reemplaza esto con tu clave pública real del LicGenerator
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

  /// Valida un código de activación generado por la app móvil.
  /// El código contiene la firma del dueño y los datos de la licencia.
  static bool validateActivationCode(String code) {
    try {
      final parts = code.split('.');
      if (parts.length != 2) return false;
      final payloadBase64 = parts[0];
      final signatureBase64 = parts[1];

      final payloadBytes = base64Decode(payloadBase64);
      final payloadString = utf8.decode(payloadBytes);
      final signatureBytes = Uint8List.fromList(base64Decode(signatureBase64));

      final signer = RSASigner(SHA256Digest(), '0609608648016503040201');
      signer.init(false, PublicKeyParameter<RSAPublicKey>(_publicKey));
      return signer.verifySignature(
          Uint8List.fromList(utf8.encode(payloadString)),
          RSASignature(signatureBytes));
    } catch (_) {
      return false;
    }
  }
}
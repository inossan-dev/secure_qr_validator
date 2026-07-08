import 'dart:convert';
import 'dart:typed_data';
import 'package:cbor/cbor.dart';
import 'package:base45/base45.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

import 'config.dart';
import 'validation_result.dart';
import 'validation_error.dart';
import 'validation_rule.dart';

/// Main validator for secure QR codes.
/// This class implements the full validation pipeline, mirroring the
/// generator's format: Base45 decoding, signature verification,
/// decryption, CBOR decoding, and business rules application.
///
/// Payload layout produced by the generator (and expected here):
/// `Base45( IV(16) + AES-CBC(CBOR(payload)) + HMAC-SHA256(IV+ciphertext)[32] )`
/// The trailing 32-byte HMAC tag is only present when `enableSignature` is on.
class SecureQRValidator {
  /// Validator configuration. Must mirror the generator's configuration
  /// (same secret key, same encryption/signature flags) or validation
  /// will systematically fail.
  final ValidatorConfig config;

  /// Business rules applied to the decoded data after all
  /// cryptographic and structural checks have passed.
  final List<ValidationRule> _businessRules;

  /// AES decrypter instance (null if encryption is disabled).
  final Encrypter? _encrypter;

  /// Creates a new validator with the specified configuration and
  /// an optional list of business rules to apply to decoded data.
  SecureQRValidator(
      this.config, {
        List<ValidationRule> businessRules = const [],
      })  : _businessRules = businessRules,
        _encrypter = config.enableEncryption && config.secretKey != null
            ? Encrypter(AES(Key.fromUtf8(config.secretKey!.padRight(32))))
            : null;

  /// Validates a QR code payload and extracts its data if valid.
  ///
  /// Runs, in order: Base45 decoding, signature verification (on the
  /// still-encrypted body, so a forged/corrupted QR is rejected before
  /// paying the cost of decryption), decryption, CBOR decoding,
  /// version check, expiration check, then business rules.
  ValidationResult validateQRPayload(String encodedPayload) {
    try {
      // Step 1: Base45 decoding
      final Uint8List finalBytes;
      try {
        finalBytes = Uint8List.fromList(Base45.decode(encodedPayload));
      } catch (e) {
        return ValidationResult.invalid(const ValidationError(
          type: ValidationErrorType.decoding,
          message: 'Invalid Base45 encoding',
        ));
      }

      // Step 2: Signature verification, BEFORE decryption.
      // The tag (32 raw bytes) was computed by the generator over
      // IV+ciphertext, so we can reject a tampered/forged QR code
      // without attempting to decrypt it.
      Uint8List body = finalBytes;
      if (config.enableSignature) {
        if (config.secretKey == null || finalBytes.length < 32) {
          return ValidationResult.invalid(const ValidationError(
            type: ValidationErrorType.signature,
            message: 'Payload too short to contain a signature',
          ));
        }
        final splitIndex = finalBytes.length - 32;
        body = finalBytes.sublist(0, splitIndex);
        final receivedTag = finalBytes.sublist(splitIndex);
        final expectedTag = _hmac(body);
        if (!_constantTimeEquals(receivedTag, expectedTag)) {
          return ValidationResult.invalid(const ValidationError(
            type: ValidationErrorType.signature,
            message: 'Invalid signature',
          ));
        }
      }

      // Step 3: Decryption
      final Uint8List plainBytes;
      if (config.enableEncryption && _encrypter != null) {
        try {
          if (body.length < 16) throw const FormatException('body too short');
          // First 16 bytes are the IV, the rest is the ciphertext.
          final iv = IV(Uint8List.fromList(body.sublist(0, 16)));
          final cipherBytes = Uint8List.fromList(body.sublist(16));
          plainBytes = Uint8List.fromList(
            _encrypter!.decryptBytes(Encrypted(cipherBytes), iv: iv),
          );
        } catch (e) {
          return ValidationResult.invalid(const ValidationError(
            type: ValidationErrorType.decryption,
            message: 'Decryption failed',
          ));
        }
      } else {
        plainBytes = body;
      }

      // Step 4: CBOR decoding
      final CborValue decoded;
      try {
        decoded = cbor.decode(plainBytes);
      } catch (e) {
        return ValidationResult.invalid(const ValidationError(
          type: ValidationErrorType.format,
          message: 'Invalid CBOR payload',
        ));
      }

      if (decoded is! CborMap) {
        return ValidationResult.invalid(const ValidationError(
          type: ValidationErrorType.format,
          message: 'Unexpected payload structure',
        ));
      }

      // Compact integer keys, matching the generator:
      // 0 = id (bytes), 1 = timestamp (seconds), 2 = version, 3 = data
      final idValue = decoded[const CborSmallInt(0)];
      final tsValue = decoded[const CborSmallInt(1)];
      final versionValue = decoded[const CborSmallInt(2)];
      final dataValue = decoded[const CborSmallInt(3)];

      if (idValue is! CborBytes ||
          tsValue is! CborSmallInt ||
          versionValue is! CborSmallInt ||
          dataValue == null) {
        return ValidationResult.invalid(const ValidationError(
          type: ValidationErrorType.format,
          message: 'Missing or invalid payload fields',
        ));
      }

      // ⚠️ .bytes / .toInt() : double-check these accessors against the
      // installed cbor package version (the API has shifted across
      // major versions) — your IDE's autocomplete will tell you if the
      // name differs.
      final idBytes = Uint8List.fromList(idValue.bytes);
      final tsSeconds = tsValue.toInt();
      final version = versionValue.toInt();
      final data = _fromCbor(dataValue);

      if (data is! Map<String, dynamic>) {
        return ValidationResult.invalid(const ValidationError(
          type: ValidationErrorType.format,
          message: 'The data field is invalid',
        ));
      }

      // Step 5: Version verification
      if (version > config.maxSupportedVersion) {
        return ValidationResult.invalid(ValidationError(
          type: ValidationErrorType.version,
          message: 'Unsupported version: $version',
        ));
      }

      final generatedAt = DateTime.fromMillisecondsSinceEpoch(tsSeconds * 1000);
      final id = _bytesToHex(idBytes);

      // Step 6: Expiration verification
      if (config.enableExpirationCheck && _isExpired(generatedAt)) {
        // Return an invalid result but with the decoded data, so the
        // caller can still inspect what an expired QR code contained.
        return ValidationResult.expiredWithData(
          error: const ValidationError(
            type: ValidationErrorType.expired,
            message: 'QR code expired',
          ),
          data: data,
          generatedAt: generatedAt,
          id: id,
        );
      }

      // Step 7: Business rules application
      final businessError = _applyBusinessRules(data);
      if (businessError != null) {
        return ValidationResult.invalid(businessError);
      }

      // All valid!
      return ValidationResult.valid(data: data, generatedAt: generatedAt, id: id);
    } catch (e) {
      return ValidationResult.invalid(ValidationError(
        type: ValidationErrorType.unknown,
        message: 'Unexpected error: ${e.toString()}',
      ));
    }
  }

  /// Computes an HMAC-SHA256 tag (32 raw bytes) over [body], using the
  /// configured secret key. Mirrors the generator's signature step,
  /// which signs the already-encrypted IV+ciphertext (encrypt-then-MAC).
  Uint8List _hmac(List<int> body) {
    final hmac = Hmac(sha256, utf8.encode(config.secretKey!));
    return Uint8List.fromList(hmac.convert(body).bytes);
  }

  /// Compares two byte sequences in constant time, to avoid leaking
  /// information about the expected tag through response-time
  /// differences (timing attack mitigation).
  bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }

  /// Converts raw id bytes back into a lowercase hex string, for
  /// display/logging purposes (this is what ends up in
  /// [ValidationResult.id]).
  String _bytesToHex(Uint8List b) =>
      b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();

  /// Recursively converts a decoded [CborValue] tree back into plain
  /// Dart objects (Map, List, String, int, double, bool, null),
  /// mirroring the generator's `_toCbor` conversion in reverse.
  dynamic _fromCbor(CborValue v) {
    if (v is CborMap) {
      return {
        for (final e in v.entries) _fromCbor(e.key).toString(): _fromCbor(e.value),
      };
    }
    if (v is CborList) return v.map(_fromCbor).toList();
    if (v is CborSmallInt) return v.toInt();
    if (v is CborFloat) return v.value;
    if (v is CborBool) return v.value;
    if (v is CborString) return v.toString();
    if (v is CborNull) return null;
    return null;
  }

  /// Checks if a QR code generated at [generatedAt] has exceeded the
  /// configured validity duration.
  bool _isExpired(DateTime generatedAt) {
    return DateTime.now().difference(generatedAt) > config.validityDuration;
  }

  /// Runs all configured business rules against [data] and returns
  /// the first validation error encountered, or null if all rules pass.
  ValidationError? _applyBusinessRules(Map<String, dynamic> data) {
    for (final rule in _businessRules) {
      final error = rule(data);
      if (error != null) {
        return ValidationError(type: ValidationErrorType.businessRule, message: error);
      }
    }
    return null;
  }
}
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

import 'config.dart';
import 'validation_result.dart';
import 'validation_error.dart';
import 'validation_rule.dart';

/// Main validator for secure QR codes.
/// This class implements all validation logic, including:
/// - Data decryption
/// - Signature verification
/// - Temporal validation
/// - Business rules application
class SecureQRValidator {
  final ValidatorConfig config;
  final List<ValidationRule> _businessRules;

  /// AES encrypter instance (null if encryption is disabled)
  final Encrypter? _encrypter;

  SecureQRValidator(
      this.config, {
        List<ValidationRule> businessRules = const [],
      }) : _businessRules = businessRules,
        _encrypter = config.enableEncryption && config.secretKey != null
            ? Encrypter(AES(Key.fromUtf8(config.secretKey!.padRight(32))))
            : null;

  /// Validates a QR code payload and extracts data if valid
  ValidationResult validateQRPayload(String encodedPayload) {
    try {
      // Step 1: Decryption or decoding
      final jsonPayload = _decryptOrDecode(encodedPayload);
      if (jsonPayload == null) {
        return ValidationResult.invalid(const ValidationError(
          type: ValidationErrorType.decryption,
          message: 'Decryption or decoding failed',
        ));
      }

      // Step 2: Parsing and basic validation
      final payload = _parseAndValidateBasics(jsonPayload);
      if (payload == null) {
        return ValidationResult.invalid(const ValidationError(
          type: ValidationErrorType.format,
          message: 'Invalid payload format',
        ));
      }

      // Step 3: Version verification
      final version = payload['version'] as int;
      if (version > config.maxSupportedVersion) {
        return ValidationResult.invalid(ValidationError(
          type: ValidationErrorType.version,
          message: 'Unsupported version: $version',
        ));
      }

      // Step 4: Signature verification
      if (config.enableSignature && !_verifySignature(payload)) {
        return ValidationResult.invalid(const ValidationError(
          type: ValidationErrorType.signature,
          message: 'Invalid signature',
        ));
      }

      // Step 5: Expiration verification
      final generatedAt = DateTime.fromMillisecondsSinceEpoch(
          payload['timestamp'] as int
      );
      if (_isExpired(generatedAt)) {
        return ValidationResult.invalid(const ValidationError(
          type: ValidationErrorType.expired,
          message: 'QR code expired',
        ));
      }

      // Step 6: Business rules application
      final businessError = _applyBusinessRules(payload['data']);
      if (businessError != null) {
        return ValidationResult.invalid(businessError);
      }

      // All valid!
      return ValidationResult.valid(
        data: payload['data'],
        generatedAt: generatedAt,
        id: payload['id'],
      );
    } catch (e) {
      return ValidationResult.invalid(ValidationError(
        type: ValidationErrorType.unknown,
        message: 'Unexpected error: ${e.toString()}',
      ));
    }
  }

  String? _decryptOrDecode(String encodedPayload) {
    try {
      if (config.enableEncryption && _encrypter != null) {
        final bytes = base64Decode(encodedPayload);
        // Extract IV (first 16 bytes) and encrypted data
        final iv = IV(bytes.sublist(0, 16));
        final encryptedBytes = bytes.sublist(16);
        final encrypted = Encrypted(encryptedBytes);
        return _encrypter!.decrypt(encrypted, iv: iv);
      } else {
        return utf8.decode(base64Decode(encodedPayload));
      }
    } catch (e) {
      return null;
    }
  }

  Map<String, dynamic>? _parseAndValidateBasics(String jsonPayload) {
    try {
      final payload = jsonDecode(jsonPayload);
      if (payload is! Map<String, dynamic>) return null;

      // Required fields verification
      final requiredFields = ['data', 'timestamp', 'version', 'id'];
      if (!requiredFields.every(payload.containsKey)) return null;

      // Type verification
      if (payload['data'] is! Map<String, dynamic>) return null;
      if (payload['timestamp'] is! int) return null;
      if (payload['version'] is! int) return null;
      if (payload['id'] is! String) return null;

      return payload;
    } catch (e) {
      return null;
    }
  }

  bool _verifySignature(Map<String, dynamic> payload) {
    if (!config.enableSignature || config.secretKey == null) return true;

    final originalSignature = payload.remove('signature');
    if (originalSignature == null) return false;

    final calculatedSignature = _generateSignature(payload);
    return originalSignature == calculatedSignature;
  }

  String _generateSignature(Map<String, dynamic> payload) {
    if (!config.enableSignature || config.secretKey == null) return '';

    final data = jsonEncode(payload);
    final key = utf8.encode(config.secretKey!);
    final bytes = utf8.encode(data);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(bytes);
    return digest.toString();
  }

  bool _isExpired(DateTime generatedAt) {
    final now = DateTime.now();
    return now.difference(generatedAt) > config.validityDuration;
  }

  ValidationError? _applyBusinessRules(Map<String, dynamic> data) {
    for (final rule in _businessRules) {
      final error = rule(data);
      if (error != null) {
        return ValidationError(
          type: ValidationErrorType.businessRule,
          message: error,
        );
      }
    }
    return null;
  }
}
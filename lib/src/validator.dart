import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

import 'config.dart';
import 'validation_result.dart';
import 'validation_error.dart';
import 'validation_rule.dart';

/// Validateur principal pour les QR codes sécurisés.
/// Cette classe implémente toute la logique de validation, incluant :
/// - Décryptage des données
/// - Vérification de signature
/// - Validation temporelle
/// - Application des règles métier
class SecureQRValidator {
  final ValidatorConfig config;
  final List<ValidationRule> _businessRules;

  /// Instance de l'encrypteur AES (null si cryptage désactivé)
  final Encrypter? _encrypter;

  /// Vecteur d'initialisation pour AES
  final IV? _iv;

  SecureQRValidator(
      this.config, {
        List<ValidationRule> businessRules = const [],
      }) : _businessRules = businessRules,
        _encrypter = config.enableEncryption && config.secretKey != null
            ? Encrypter(AES(Key.fromUtf8(config.secretKey!.padRight(32))))
            : null,
        _iv = config.enableEncryption ? IV.fromLength(16) : null;

  /// Valide un payload de QR code et extrait les données si valides
  ValidationResult validateQRPayload(String encodedPayload) {
    try {
      // Étape 1: Décryptage ou décodage
      final jsonPayload = _decryptOrDecode(encodedPayload);
      if (jsonPayload == null) {
        return ValidationResult.invalid(const ValidationError(
          type: ValidationErrorType.decryption,
          message: 'Échec du décryptage ou décodage',
        ));
      }

      // Étape 2: Parsing et validation de base
      final payload = _parseAndValidateBasics(jsonPayload);
      if (payload == null) {
        return ValidationResult.invalid(const ValidationError(
          type: ValidationErrorType.format,
          message: 'Format de payload invalide',
        ));
      }

      // Étape 3: Vérification de version
      final version = payload['version'] as int;
      if (version > config.maxSupportedVersion) {
        return ValidationResult.invalid(ValidationError(
          type: ValidationErrorType.version,
          message: 'Version non supportée: $version',
        ));
      }

      // Étape 4: Vérification de signature
      if (config.enableSignature && !_verifySignature(payload)) {
        return ValidationResult.invalid(const ValidationError(
          type: ValidationErrorType.signature,
          message: 'Signature invalide',
        ));
      }

      // Étape 5: Vérification de l'expiration
      final generatedAt = DateTime.fromMillisecondsSinceEpoch(
          payload['timestamp'] as int
      );
      if (_isExpired(generatedAt)) {
        return ValidationResult.invalid(const ValidationError(
          type: ValidationErrorType.expired,
          message: 'QR code expiré',
        ));
      }

      // Étape 6: Application des règles métier
      final businessError = _applyBusinessRules(payload['data']);
      if (businessError != null) {
        return ValidationResult.invalid(businessError);
      }

      // Tout est valide !
      return ValidationResult.valid(
        data: payload['data'],
        generatedAt: generatedAt,
        id: payload['id'],
      );
    } catch (e) {
      return ValidationResult.invalid(ValidationError(
        type: ValidationErrorType.unknown,
        message: 'Erreur inattendue: ${e.toString()}',
      ));
    }
  }

  String? _decryptOrDecode(String encodedPayload) {
    try {
      if (config.enableEncryption && _encrypter != null && _iv != null) {
        final encrypted = Encrypted(base64Decode(encodedPayload));
        return _encrypter!.decrypt(encrypted, iv: _iv!);
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

      // Vérification des champs requis
      final requiredFields = ['data', 'timestamp', 'version', 'id'];
      if (!requiredFields.every(payload.containsKey)) return null;

      // Vérification des types
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
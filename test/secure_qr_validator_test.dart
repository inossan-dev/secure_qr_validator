import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secure_qr_validator/secure_qr_validator.dart';

void main() {
// Clé de test constante pour la reproductibilité des tests
  const testKey = '2024#@#qrcod#orange@##perform#==';

  // Fonction utilitaire pour générer une signature de test
  String generateTestSignature(Map<String, dynamic> payload, String key) {
    final data = jsonEncode(payload);
    final keyBytes = utf8.encode(key);
    final bytes = utf8.encode(data);
    final hmac = Hmac(sha256, keyBytes);
    final digest = hmac.convert(bytes);
    return digest.toString();
  }

  // Fonction utilitaire pour créer un payload de test
  String createTestPayload({
    required Map<String, dynamic> data,
    bool encrypted = false,
    bool signed = false,
    DateTime? timestamp,
    int version = 1,
  }) {
    final now = timestamp ?? DateTime.now();
    final payload = {
      'data': data,
      'timestamp': now.millisecondsSinceEpoch,
      'id': 'test-id-123',
      'version': version,
    };

    if (signed) {
      final signature = generateTestSignature(payload, testKey);
      payload['signature'] = signature;
    }

    final jsonPayload = jsonEncode(payload);

    if (encrypted) {
      final encrypter = Encrypter(AES(Key.fromUtf8(testKey.padRight(32))));
      final iv = IV.fromLength(16);
      final encrypted = encrypter.encrypt(jsonPayload, iv: iv);
      return base64Encode(encrypted.bytes);
    }

    return base64Encode(utf8.encode(jsonPayload));
  }

  group('Configuration du validateur', () {
    test('devrait accepter une configuration valide', () {
      expect(
            () => ValidatorConfig(
          secretKey: testKey,
          validityDuration: const Duration(minutes: 5),
          enableEncryption: true,
          enableSignature: true,
        ),
        returnsNormally,
      );
    });

    test('devrait rejeter une clé trop courte avec encryption activée', () {
      expect(
            () => ValidatorConfig(
          secretKey: 'court',
          enableEncryption: true,
        ),
        throwsArgumentError,
      );
    });

    test('devrait exiger une clé si encryption ou signature activée', () {
      expect(
            () => ValidatorConfig(enableEncryption: true),
        throwsArgumentError,
      );
      expect(
            () => ValidatorConfig(enableSignature: true),
        throwsArgumentError,
      );
    });
  });

  group('Validation basique', () {
    late SecureQRValidator validator;

    setUp(() {
      validator = SecureQRValidator(ValidatorConfig(
        validityDuration: const Duration(minutes: 5),
      ));
    });

    test('devrait valider un payload simple valide', () {
      final payload = createTestPayload(data: {'test': 'value'});
      final result = validator.validateQRPayload(payload);

      expect(result.isValid, isTrue);
      expect(result.data?['test'], equals('value'));
    });

    test('devrait rejeter un payload mal formaté', () {
      final result = validator.validateQRPayload('invalid_base64');

      expect(result.isValid, isFalse);
      expect(result.error?.type, equals(ValidationErrorType.decoding));
    });

    test('devrait rejeter un payload avec version non supportée', () {
      final payload = createTestPayload(
        data: {'test': 'value'},
        version: 999,
      );
      final result = validator.validateQRPayload(payload);

      expect(result.isValid, isFalse);
      expect(result.error?.type, equals(ValidationErrorType.version));
    });
  });

  group('Validation avec encryption', () {
    late SecureQRValidator validator;

    setUp(() {
      validator = SecureQRValidator(ValidatorConfig(
        secretKey: testKey,
        enableEncryption: true,
        validityDuration: const Duration(minutes: 5),
      ));
    });

    test('devrait décrypter et valider un payload crypté', () {
      final payload = createTestPayload(
        data: {'test': 'encrypted'},
        encrypted: true,
      );
      final result = validator.validateQRPayload(payload);

      expect(result.isValid, isTrue);
      expect(result.data?['test'], equals('encrypted'));
    });

    test('devrait rejeter un payload non crypté quand encryption requise', () {
      final payload = createTestPayload(
        data: {'test': 'value'},
        encrypted: false,
      );
      final result = validator.validateQRPayload(payload);

      expect(result.isValid, isFalse);
      expect(result.error?.type, equals(ValidationErrorType.decryption));
    });
  });

  group('Validation avec signature', () {
    late SecureQRValidator validator;

    setUp(() {
      validator = SecureQRValidator(ValidatorConfig(
        secretKey: testKey,
        enableSignature: true,
        validityDuration: const Duration(minutes: 5),
      ));
    });

    test('devrait accepter un payload correctement signé', () {
      final payload = createTestPayload(
        data: {'test': 'signed'},
        signed: true,
      );
      final result = validator.validateQRPayload(payload);

      expect(result.isValid, isTrue);
      expect(result.data?['test'], equals('signed'));
    });

    test('devrait rejeter un payload avec signature invalide', () {
      final payload = createTestPayload(
        data: {'test': 'bad_signature'},
        signed: false,  // Pas de signature
      );
      final result = validator.validateQRPayload(payload);

      expect(result.isValid, isFalse);
      expect(result.error?.type, equals(ValidationErrorType.signature));
    });
  });

  group('Validation temporelle', () {
    late SecureQRValidator validator;

    setUp(() {
      validator = SecureQRValidator(ValidatorConfig(
        validityDuration: const Duration(minutes: 5),
      ));
    });

    test('devrait accepter un payload non expiré', () {
      final payload = createTestPayload(
        data: {'test': 'value'},
        timestamp: DateTime.now(),
      );
      final result = validator.validateQRPayload(payload);

      expect(result.isValid, isTrue);
    });

    test('devrait rejeter un payload expiré', () {
      final oldTimestamp = DateTime.now().subtract(const Duration(minutes: 10));
      final payload = createTestPayload(
        data: {'test': 'value'},
        timestamp: oldTimestamp,
      );
      final result = validator.validateQRPayload(payload);

      expect(result.isValid, isFalse);
      expect(result.isExpired, isTrue);
    });
  });

  group('Règles de validation métier', () {
    late SecureQRValidator validator;

    setUp(() {
      // Création du validateur avec des règles métier personnalisées
      final rules = [
        CommonValidationRules.required('userId'),
        CommonValidationRules.numberInRange('age', 18, 100),
            (data) {
          if (data['role'] == 'admin' && data['level'] < 5) {
            return 'Un admin doit avoir un niveau >= 5';
          }
          return null;
        },
      ];

      validator = SecureQRValidator(
        ValidatorConfig(validityDuration: const Duration(minutes: 5)),
        businessRules: rules,
      );
    });

    test('devrait valider des données respectant toutes les règles', () {
      final payload = createTestPayload(data: {
        'userId': 'user123',
        'age': 25,
        'role': 'admin',
        'level': 5,
      });
      final result = validator.validateQRPayload(payload);

      expect(result.isValid, isTrue);
    });

    test('devrait rejeter des données violant une règle required', () {
      final payload = createTestPayload(data: {
        'age': 25,
      });
      final result = validator.validateQRPayload(payload);

      expect(result.isValid, isFalse);
      expect(result.error?.type, equals(ValidationErrorType.businessRule));
    });

    test('devrait rejeter des données hors limites', () {
      final payload = createTestPayload(data: {
        'userId': 'user123',
        'age': 15,
      });
      final result = validator.validateQRPayload(payload);

      expect(result.isValid, isFalse);
      expect(result.error?.type, equals(ValidationErrorType.businessRule));
    });

    test('devrait rejeter des données violant une règle personnalisée', () {
      final payload = createTestPayload(data: {
        'userId': 'user123',
        'age': 25,
        'role': 'admin',
        'level': 3,
      });
      final result = validator.validateQRPayload(payload);

      expect(result.isValid, isFalse);
      expect(result.error?.type, equals(ValidationErrorType.businessRule));
    });
  });

  group('Extensions ValidationResult', () {
    test('getData devrait retourner la valeur typée correcte', () {
      final result = ValidationResult.valid(
        data: {'age': 25, 'name': 'Test'},
        generatedAt: DateTime.now(),
        id: 'test-id',
      );

      expect(result.getData<int>('age'), equals(25));
      expect(result.getData<String>('name'), equals('Test'));
      expect(result.getData<bool>('missing', defaultValue: true), isTrue);
    });

    test('hasData devrait correctement vérifier la présence des données', () {
      final result = ValidationResult.valid(
        data: {'key1': 'value1'},
        generatedAt: DateTime.now(),
        id: 'test-id',
      );

      expect(result.hasData('key1'), isTrue);
      expect(result.hasData('missing'), isFalse);
    });
  });
}
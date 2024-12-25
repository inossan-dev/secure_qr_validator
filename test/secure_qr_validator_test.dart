import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secure_qr_validator/secure_qr_validator.dart';

void main() {
  // Constant test key for test reproducibility
  const testKey = '2024#@#qrcod#orange@##perform#==';

  // Utility function to generate a test signature
  String generateTestSignature(Map<String, dynamic> payload, String key) {
    final data = jsonEncode(payload);
    final keyBytes = utf8.encode(key);
    final bytes = utf8.encode(data);
    final hmac = Hmac(sha256, keyBytes);
    final digest = hmac.convert(bytes);
    return digest.toString();
  }

  // Utility function to create a test payload
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
      // Combine IV and encrypted data
      final combined = iv.bytes + encrypted.bytes;
      return base64Encode(combined);
    }

    return base64Encode(utf8.encode(jsonPayload));
  }

  group('Validator Configuration', () {
    test('should accept valid configuration', () {
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

    test('should reject too short key with encryption enabled', () {
      expect(
        () => ValidatorConfig(
          secretKey: 'short',
          enableEncryption: true,
        ),
        throwsArgumentError,
      );
    });

    test('should require key if encryption or signature enabled', () {
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

  group('Basic Validation', () {
    late SecureQRValidator validator;

    setUp(() {
      validator = SecureQRValidator(ValidatorConfig(
        validityDuration: const Duration(minutes: 5),
      ));
    });

    test('should validate a simple valid payload', () {
      final payload = createTestPayload(data: {'test': 'value'});
      final result = validator.validateQRPayload(payload);

      expect(result.isValid, isTrue);
      expect(result.data?['test'], equals('value'));
    });

    test('should reject malformed payload', () {
      final result = validator.validateQRPayload('invalid_base64');

      expect(result.isValid, isFalse);
      expect(result.error?.type, equals(ValidationErrorType.decryption));
    });

    test('should reject payload with unsupported version', () {
      final payload = createTestPayload(
        data: {'test': 'value'},
        version: 999,
      );
      final result = validator.validateQRPayload(payload);

      expect(result.isValid, isFalse);
      expect(result.error?.type, equals(ValidationErrorType.version));
    });
  });

  group('Validation with Encryption', () {
    late SecureQRValidator validator;

    setUp(() {
      validator = SecureQRValidator(ValidatorConfig(
        secretKey: testKey,
        enableEncryption: true,
        validityDuration: const Duration(minutes: 5),
      ));
    });

    test('should decrypt and validate encrypted payload', () {
      final payload = createTestPayload(
        data: {'test': 'encrypted'},
        encrypted: true,
      );
      final result = validator.validateQRPayload(payload);

      expect(result.isValid, isTrue);
      expect(result.data?['test'], equals('encrypted'));
    });

    test('should reject non-encrypted payload when encryption required', () {
      final payload = createTestPayload(
        data: {'test': 'value'},
        encrypted: false,
      );
      final result = validator.validateQRPayload(payload);

      expect(result.isValid, isFalse);
      expect(result.error?.type, equals(ValidationErrorType.decryption));
    });
  });

  group('Validation with Signature', () {
    late SecureQRValidator validator;

    setUp(() {
      validator = SecureQRValidator(ValidatorConfig(
        secretKey: testKey,
        enableSignature: true,
        validityDuration: const Duration(minutes: 5),
      ));
    });

    test('should accept correctly signed payload', () {
      final payload = createTestPayload(
        data: {'test': 'signed'},
        signed: true,
      );
      final result = validator.validateQRPayload(payload);

      expect(result.isValid, isTrue);
      expect(result.data?['test'], equals('signed'));
    });

    test('should reject payload with invalid signature', () {
      final payload = createTestPayload(
        data: {'test': 'bad_signature'},
        signed: false, // No signature
      );
      final result = validator.validateQRPayload(payload);

      expect(result.isValid, isFalse);
      expect(result.error?.type, equals(ValidationErrorType.signature));
    });
  });

  group('Temporal Validation', () {
    late SecureQRValidator validator;

    setUp(() {
      validator = SecureQRValidator(ValidatorConfig(
        validityDuration: const Duration(minutes: 5),
      ));
    });

    test('should accept non-expired payload', () {
      final payload = createTestPayload(
        data: {'test': 'value'},
        timestamp: DateTime.now(),
      );
      final result = validator.validateQRPayload(payload);

      expect(result.isValid, isTrue);
    });

    test('should reject expired payload', () {
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

  group('Business Rule Validation', () {
    late SecureQRValidator validator;

    setUp(() {
      // Create validator with custom business rules
      final rules = [
        CommonValidationRules.required('userId'),
        CommonValidationRules.numberInRange('age', 18, 100),
        (data) {
          if (data['role'] == 'admin' && data['level'] < 5) {
            return 'An admin must have level >= 5';
          }
          return null;
        },
      ];

      validator = SecureQRValidator(
        ValidatorConfig(validityDuration: const Duration(minutes: 5)),
        businessRules: rules,
      );
    });

    test('should validate data respecting all rules', () {
      final payload = createTestPayload(data: {
        'userId': 'user123',
        'age': 25,
        'role': 'admin',
        'level': 5,
      });
      final result = validator.validateQRPayload(payload);

      expect(result.isValid, isTrue);
    });

    test('should reject data violating required rule', () {
      final payload = createTestPayload(data: {
        'age': 25,
      });
      final result = validator.validateQRPayload(payload);

      expect(result.isValid, isFalse);
      expect(result.error?.type, equals(ValidationErrorType.businessRule));
    });

    test('should reject out-of-bounds data', () {
      final payload = createTestPayload(data: {
        'userId': 'user123',
        'age': 15,
      });
      final result = validator.validateQRPayload(payload);

      expect(result.isValid, isFalse);
      expect(result.error?.type, equals(ValidationErrorType.businessRule));
    });

    test('should reject data violating custom rule', () {
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

  group('ValidationResult Extensions', () {
    test('getData should return correct typed value', () {
      final result = ValidationResult.valid(
        data: {'age': 25, 'name': 'Test'},
        generatedAt: DateTime.now(),
        id: 'test-id',
      );

      expect(result.getData<int>('age'), equals(25));
      expect(result.getData<String>('name'), equals('Test'));
      expect(result.getData<bool>('missing', defaultValue: true), isTrue);
    });

    test('hasData should correctly verify data presence', () {
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

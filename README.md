# Secure QR Validator

A robust Flutter package for validating secure QR codes with battle-tested encryption, digital signatures, and customizable business rules. Perfect for access control, ticketing, and secure document verification.

> 🔐 Compatible with [Secure QR Generator](https://pub.dev/packages/secure_qr_generator) package

## Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Advanced Usage](#advanced-usage)
- [Business Rules](#business-rules)
- [Status Visualization](#status-visualization)
- [Best Practices](#best-practices)
- [Error Handling](#error-handling)
- [License](#license)

## Features

### 🔒 Secure Validation
- **AES Encryption**: Industry-standard AES-256 encryption support
- **Digital Signatures**: HMAC-SHA256 signature verification
- **Temporal Validation**: Time-based validation with expiration
- **Replay Protection**: Built-in mechanisms against replay attacks
- **Tampering Detection**: Automatic detection of modified QR codes

### 🎯 Business Rules
- **Flexible Rules Engine**: Define custom validation logic
- **Pre-built Validations**: Common validation rules ready to use
- **Rule Composition**: Combine rules using builder pattern
- **Type-Safe**: Generic type support for data validation
- **Extensible**: Easy to add new validation rules

### 🎨 Flutter Integration
- **Ready-to-Use Widgets**: Drop-in validation status displays
- **Customizable UI**: Full control over styling and animations
- **Responsive**: Adapts to different screen sizes
- **Platform Support**: Works on iOS, Android, and Web
- **Dark Mode**: Automatic theme adaptation

## Installation

1. Add dependency to your `pubspec.yaml`:

```yaml
dependencies:
  secure_qr_validator: ^1.0.3
```

2. Install packages:

```bash
flutter pub get
```

3. Import the package:

```dart
import 'package:secure_qr_validator/secure_qr_validator.dart';
```

## Quick Start

### Basic Validation

```dart
// Initialize validator
final validator = SecureQRValidator(
  ValidatorConfig(
    secretKey: 'your-secure-key-min-32-chars-long!!!',
    validityDuration: Duration(minutes: 5),
    enableEncryption: true,
    enableSignature: true,
  ),
);

// Perform validation
try {
  final result = await validator.validateQRPayload(qrCodeContent);
  
  if (result.isValid) {
    // Access validated data safely
    final userId = result.getData<String>('userId');
    final accessLevel = result.getData<int>('accessLevel');
    
    // Continue with business logic
    handleValidAccess(userId, accessLevel);
  } else {
    handleInvalidAccess(result.error);
  }
} catch (e) {
  handleError(e);
}
```

### With Business Rules

```dart
final validator = SecureQRValidator(
  ValidatorConfig(
    secretKey: 'your-secure-key-min-32-chars-long!!!',
    validityDuration: Duration(minutes: 5),
  ),
  businessRules: [
    // Required fields
    CommonValidationRules.required(['userId', 'accessLevel']),
    
    // Access level range check
    CommonValidationRules.numberInRange('accessLevel', 1, 5),
    
    // Custom business logic
    (data) {
      final accessLevel = data['accessLevel'] as int;
      final role = data['role'] as String?;
      
      if (role == 'admin' && accessLevel < 3) {
        return 'Admin users must have access level 3 or higher';
      }
      return null;  // Validation passed
    },
  ],
);
```

## Advanced Usage

### Type-Safe Data Access

```dart
final result = await validator.validateQRPayload(qrContent);

// Safe data access with type checking
final UserProfile profile = result.getDataModel<UserProfile>(
  'profile',
  (json) => UserProfile.fromJson(json),
);

// With default values
final age = result.getData<int>('age', defaultValue: 0);
final name = result.getData<String>('name', defaultValue: 'Unknown');

// Presence checking
if (result.hasAllData(['email', 'phone'])) {
  final contacts = Contacts(
    email: result.getData<String>('email'),
    phone: result.getData<String>('phone'),
  );
}
```

### Custom Validation Rules

```dart
class DateRangeRule implements ValidationRule {
  final String startField;
  final String endField;
  
  DateRangeRule(this.startField, this.endField);
  
  @override
  String? validate(Map<String, dynamic> data) {
    final start = DateTime.parse(data[startField] as String);
    final end = DateTime.parse(data[endField] as String);
    
    if (end.isBefore(start)) {
      return 'End date must be after start date';
    }
    return null;
  }
}

// Usage
validator.addRule(DateRangeRule('startDate', 'endDate'));
```

## UI Integration

### Status Indicator

```dart
ValidityIndicatorView(
  result: validationResult,
  builder: (context, status, child) => Container(
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: status.color,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        Icon(status.icon),
        SizedBox(width: 8),
        Text(status.message),
      ],
    ),
  ),
)
```

## Error Handling

```dart
try {
  final result = await validator.validateQRPayload(qrContent);
  handleValidationResult(result);
} on ValidationException catch (e) {
  // Handle validation errors (invalid format, expired, etc.)
  showError('Validation Error', e.message);
} on SecurityException catch (e) {
  // Handle security errors (invalid signature, decryption failed, etc.)
  showError('Security Error', e.message);
} on BusinessRuleException catch (e) {
  // Handle business rule violations
  showError('Business Rule Violation', e.message);
} catch (e) {
  // Handle unexpected errors
  reportError(e);
}
```

## Best Practices

### Security

- Use strong encryption keys (32+ characters)
- Enable both encryption and signature verification
- Use short validity durations for sensitive operations
- Implement proper key management and rotation
- Add rate limiting for validation attempts

### Performance

- Use appropriate validity durations
- Implement proper error handling
- Profile memory usage in production

### Integration

- Use dependency injection for validator instances
- Add logging for security events
- Use type-safe data access
- Write comprehensive tests

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
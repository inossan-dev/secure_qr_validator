# Secure QR Validator

A robust Flutter package for validating secure QR codes with support for encryption, digital signatures, and customizable business rules.

## Features

- 🔒 **Secure Validation**
    - AES encryption support
    - Digital signature verification
    - Temporal validation
    - Protection against replay attacks

- 🎯 **Business Rules**
    - Flexible validation rules
    - Pre-built common validations
    - Custom rule support
    - Rule composition

- 🎨 **Flutter Integration**
    - Ready-to-use validation status widget
    - Customizable styling
    - Responsive design

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  secure_qr_validator: ^1.0.0
```

## Quick Start

### Basic Usage

```dart
// Create a validator with basic configuration
final validator = SecureQRValidator(
  ValidatorConfig(
    validityDuration: Duration(minutes: 5),
  ),
);

// Validate a QR code
final result = validator.validateQRPayload(qrCodeContent);

if (result.isValid) {
  print('Valid QR Code!');
  print('Data: ${result.data}');
} else {
  print('Invalid QR Code: ${result.error?.message}');
}
```

### Secure Configuration

```dart
// Create a validator with encryption and signature
final validator = SecureQRValidator(
  ValidatorConfig(
    secretKey: 'your-secure-key-min-32-chars-long!!!',
    enableEncryption: true,
    enableSignature: true,
    validityDuration: Duration(minutes: 5),
  ),
);
```

## Business Rules

```dart
// Define validation rules
final rules = [
  CommonValidationRules.required('userId'),
  CommonValidationRules.numberInRange('age', 18, 100), (data) {
    if (data['role'] == 'admin' && data['level'] < 5) {
      return 'Admin must have level >= 5';
    }
    return null;
  },
];

// Create validator with rules
final validator = SecureQRValidator(
  ValidatorConfig(validityDuration: Duration(minutes: 5)),
  businessRules: rules,
);
```

## Status Visualization

```dart
// Using the widget directly
ValidityIndicatorView(
  result: validationResult,
  validColor: Colors.green,
  expiredColor: Colors.orange,
  invalidColor: Colors.red,
)

// Or use the extension method
validationResult.toIndicator()
```

## Advanced Features

### Type-Safe Data Access

Access validated data safely with type checking and default values:

```dart
final result = validator.validateQRPayload(qrContent);

// Type-safe data access with defaults
final age = result.getData<int>('age', defaultValue: 0);
final name = result.getData<String>('name', defaultValue: 'Unknown');
final isAdmin = result.getData<bool>('isAdmin', defaultValue: false);

// Check for data presence
if (result.hasData('email')) {
final email = result.getData<String>('email');
}

// Check for multiple fields
if (result.hasAllData(['name', 'email', 'age'])) {
// All fields present
}
```

### Validation Rules

#### Pre-built Rules

```dart
// Required field
CommonValidationRules.required('email')

// Numeric range
CommonValidationRules.numberInRange('age', 0, 120)

// Future date
CommonValidationRules.dateMustBeFuture('eventDate')

// Pattern matching
CommonValidationRules.matchesPattern('email', r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')

// List length
CommonValidationRules.listLength('items', min: 1, max: 10)

// Mutually exclusive fields
CommonValidationRules.mutuallyExclusive(['phone', 'email'])
```

#### Composing Rules

Use the builder pattern to combine multiple rules:

```dart
final validator = ValidationRuleBuilder()
        .addRule(CommonValidationRules.required('email'))
        .addRule(CommonValidationRules.matchesPattern('email', r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
).build();
```

## Security Best Practices

Use the builder pattern to combine multiple rules:

- Use a strong secret key (minimum 32 characters) when enabling encryption
- Enable both encryption and signature for maximum security
- Set appropriate validity duration to prevent replay attacks

## Security Best Practices

Use the builder pattern to combine multiple rules:

- Use a strong secret key (minimum 32 characters) when enabling encryption
- Enable both encryption and signature for maximum security
- Set appropriate validity duration to prevent replay attacks

## Error Handling

```dart
try {
  final result = await validator.validateQRPayload(qrContent);
  // Handle validation result
} on ValidationException catch (e) {
  print('Validation error: ${e.message}');
} on SecurityException catch (e) {
  print('Security error: ${e.message}');
} catch (e) {
    print('Unexpected error: $e');
}
```

## License
This project is licensed under the MIT License - see the LICENSE file for details.

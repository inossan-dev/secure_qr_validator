import 'package:secure_qr_validator/secure_qr_validator.dart';

/// Represents the complete result of a QR code validation.
/// This class encapsulates all necessary information regarding
/// the validity of a QR code, including extracted data and potential
/// errors.
class ValidationResult {
  /// Indicates if the QR code is valid
  final bool isValid;

  /// Data extracted from the QR code (null if invalid)
  final Map<String, dynamic>? data;

  /// Validation error (null if valid)
  final ValidationError? error;

  /// Generation timestamp of the QR code
  final DateTime? generatedAt;

  /// Unique identifier of the QR code
  final String? id;

  /// Private constructor to ensure data integrity
  const ValidationResult._({
    required this.isValid,
    this.data,
    this.error,
    this.generatedAt,
    this.id,
  });

  /// Creates a result for a valid QR code
  factory ValidationResult.valid({
    required Map<String, dynamic> data,
    required DateTime generatedAt,
    required String id,
  }) {
    return ValidationResult._(
      isValid: true,
      data: data,
      generatedAt: generatedAt,
      id: id,
    );
  }

  /// Creates a result for an invalid QR code
  factory ValidationResult.invalid(ValidationError error) {
    return ValidationResult._(
      isValid: false,
      error: error,
    );
  }

  /// Creates a result for an expired QR code, but with data included
  factory ValidationResult.expiredWithData({
    required ValidationError error,
    required Map<String, dynamic> data,
    required DateTime generatedAt,
    required String id,
  }) {
    return ValidationResult._(
      isValid: false,
      error: error,
      data: data,
      generatedAt: generatedAt,
      id: id,
    );
  }

  /// Checks if the error is of a specific type
  bool hasError(ValidationErrorType type) {
    return error?.type == type;
  }

  /// Indicates if the QR code is expired
  bool get isExpired => hasError(ValidationErrorType.expired);

  /// Checks for the presence of a specific key in the data
  ///
  /// This method verifies if:
  /// 1. The data exists (even if QR code is invalid)
  /// 2. The specified key exists in the data
  ///
  /// [key]: The key to search for in the data
  ///
  /// Returns true if the key exists in the data
  bool hasData(String key) {
    return data != null && data!.containsKey(key);
  }

  /// Retrieves a typed value with default value handling
  ///
  /// This method provides a safe and typed way to access data,
  /// with integrated handling of error cases and type conversions.
  ///
  /// Usage example:
  /// ```dart
  /// final age = result.getData<int>('age', defaultValue: 0);
  /// final name = result.getData<String>('name', defaultValue: 'Unknown');
  /// ```
  ///
  /// [T]: The expected data type
  /// [key]: The data key
  /// [defaultValue]: Value returned in case of absence or error
  ///
  /// Returns the typed value or the default value
  T? getData<T>(String key, {T? defaultValue}) {
    if (!isValid || data == null) return defaultValue;

    final value = data![key];
    if (value == null) return defaultValue;
    if (value is T) return value;

    // Attempt conversion for common types
    if (T == String) return value.toString() as T;
    if (T == int && value is num) return value.toInt() as T;
    if (T == double && value is num) return value.toDouble() as T;

    return defaultValue;
  }

  /// Checks if all specified keys exist in the data
  ///
  /// [keys]: List of keys to check
  ///
  /// Returns true if all keys exist
  bool hasAllData(List<String> keys) {
    return keys.every(hasData);
  }

  /// Checks if at least one of the specified keys exists in the data
  ///
  /// [keys]: List of keys to check
  ///
  /// Returns true if at least one key exists
  bool hasAnyData(List<String> keys) {
    return keys.any(hasData);
  }
}

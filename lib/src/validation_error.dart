/// Represents the different possible error types during validation
enum ValidationErrorType {
  /// Decryption error (incorrect key or corrupted data)
  decryption,

  /// Base64 decoding error
  decoding,

  /// Invalid JSON format
  format,

  /// Unsupported QR code version
  version,

  /// Invalid signature
  signature,

  /// Expired QR code
  expired,

  /// Business rule validation error
  businessRule,

  /// Unexpected error
  unknown,
}

/// Encapsulates detailed information about a validation error
class ValidationError {
  final ValidationErrorType type;
  final String message;
  final dynamic details;

  const ValidationError({
    required this.type,
    required this.message,
    this.details,
  });

  @override
  String toString() => message;
}

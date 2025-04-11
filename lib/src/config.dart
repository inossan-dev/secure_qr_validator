/// Configuration for secure QR code validation.
/// This class groups all necessary parameters to validate
/// QR codes according to different security levels.
class ValidatorConfig {
  /// Secret key used for decryption and signature verification.
  /// Must be identical to the one used for generation.
  final String? secretKey;

  /// Duration for which a QR code is considered valid
  /// after its generation.
  final Duration validityDuration;

  /// Indicates if the QR code content must be decrypted.
  /// Must match the generation parameter.
  final bool enableEncryption;

  /// Indicates if the QR code signature must be verified.
  /// Must match the generation parameter.
  final bool enableSignature;

  /// Maximum QR code format version supported by this validator.
  /// Allows future format evolution while maintaining compatibility.
  final int maxSupportedVersion;

  /// Whether to validate the expiration date
  final bool enableExpirationCheck;

  ValidatorConfig({
    this.secretKey,
    this.validityDuration = const Duration(minutes: 5),
    this.enableEncryption = false,
    this.enableSignature = false,
    this.maxSupportedVersion = 1,
    this.enableExpirationCheck = true,
  }) {
    // Parameter validation
    if ((enableEncryption || enableSignature) && secretKey == null) {
      throw ArgumentError(
        'Secret key is required when encryption or signature is enabled',
      );
    }

    if (enableEncryption && secretKey != null && secretKey!.length < 32) {
      throw ArgumentError(
        'Secret key must be at least 32 characters when encryption is enabled',
      );
    }

    if (maxSupportedVersion < 1) {
      throw ArgumentError(
        'Maximum supported version must be at least 1',
      );
    }
  }
}

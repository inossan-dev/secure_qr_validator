/// Représente les différents types d'erreurs possibles lors de la validation
enum ValidationErrorType {
  /// Erreur de décryptage (clé incorrecte ou données corrompues)
  decryption,

  /// Erreur lors du décodage base64
  decoding,

  /// Format JSON invalide
  format,

  /// Version non supportée du QR code
  version,

  /// Signature invalide
  signature,

  /// QR code expiré
  expired,

  /// Erreur lors de la validation des règles métier
  businessRule,

  /// Erreur inattendue
  unknown,
}

/// Encapsule les informations détaillées d'une erreur de validation
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

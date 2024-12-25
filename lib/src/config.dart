/// Configuration pour la validation des QR codes sécurisés.
/// Cette classe regroupe tous les paramètres nécessaires pour valider
/// les QR codes selon différents niveaux de sécurité.
class ValidatorConfig {
  /// Clé secrète utilisée pour le décryptage et la vérification de signature.
  /// Doit être identique à celle utilisée pour la génération.
  final String? secretKey;

  /// Durée pendant laquelle un QR code est considéré comme valide
  /// après sa génération.
  final Duration validityDuration;

  /// Indique si le contenu du QR code doit être décrypté.
  /// Doit correspondre au paramètre de génération.
  final bool enableEncryption;

  /// Indique si la signature du QR code doit être vérifiée.
  /// Doit correspondre au paramètre de génération.
  final bool enableSignature;

  /// Version maximale du format de QR code supportée par ce validateur.
  /// Permet une évolution future du format tout en gardant la compatibilité.
  final int maxSupportedVersion;

  ValidatorConfig({
    this.secretKey,
    this.validityDuration = const Duration(minutes: 5),
    this.enableEncryption = false,
    this.enableSignature = false,
    this.maxSupportedVersion = 1,
  }) {
    // Validation des paramètres
    if ((enableEncryption || enableSignature) && secretKey == null) {
      throw ArgumentError(
        'La clé secrète est requise quand le cryptage ou la signature est activé',
      );
    }

    if (enableEncryption && secretKey != null && secretKey!.length < 32) {
      throw ArgumentError(
        'La clé secrète doit faire au moins 32 caractères quand le cryptage est activé',
      );
    }

    if (maxSupportedVersion < 1) {
      throw ArgumentError(
        'La version maximale supportée doit être au moins 1',
      );
    }
  }
}
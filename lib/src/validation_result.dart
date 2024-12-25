import 'package:secure_qr_validator/secure_qr_validator.dart';

/// Représente le résultat complet d'une validation de QR code.
/// Cette classe encapsule toutes les informations nécessaires concernant
/// la validité d'un QR code, y compris les données extraites et les erreurs
/// éventuelles.
class ValidationResult {
  /// Indique si le QR code est valide
  final bool isValid;

  /// Données extraites du QR code (null si non valide)
  final Map<String, dynamic>? data;

  /// Erreur de validation (null si valide)
  final ValidationError? error;

  /// Timestamp de génération du QR code
  final DateTime? generatedAt;

  /// Identifiant unique du QR code
  final String? id;

  /// Constructeur privé pour assurer l'intégrité des données
  const ValidationResult._({
    required this.isValid,
    this.data,
    this.error,
    this.generatedAt,
    this.id,
  });

  /// Crée un résultat pour un QR code valide
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

  /// Crée un résultat pour un QR code invalide
  factory ValidationResult.invalid(ValidationError error) {
    return ValidationResult._(
      isValid: false,
      error: error,
    );
  }

  /// Vérifie si l'erreur est d'un type spécifique
  bool hasError(ValidationErrorType type) {
    return error?.type == type;
  }

  /// Indique si le QR code est expiré
  bool get isExpired => hasError(ValidationErrorType.expired);

  /// Vérifie la présence d'une clé spécifique dans les données
  ///
  /// Cette méthode vérifie si :
  /// 1. Le QR code est valide
  /// 2. Les données existent
  /// 3. La clé spécifiée existe dans les données
  ///
  /// [key] : La clé à rechercher dans les données
  ///
  /// Retourne true si la clé existe dans les données d'un QR code valide
  bool hasData(String key) {
    return isValid && data != null && data!.containsKey(key);
  }

  /// Récupère une valeur typée avec gestion de valeur par défaut
  ///
  /// Cette méthode offre une façon sûre et typée d'accéder aux données,
  /// avec une gestion intégrée des cas d'erreur et des conversions de type.
  ///
  /// Exemple d'utilisation :
  /// ```dart
  /// final age = result.getData<int>('age', defaultValue: 0);
  /// final name = result.getData<String>('name', defaultValue: 'Inconnu');
  /// ```
  ///
  /// [T] : Le type de donnée attendu
  /// [key] : La clé de la donnée
  /// [defaultValue] : Valeur retournée en cas d'absence ou d'erreur
  ///
  /// Retourne la valeur typée ou la valeur par défaut
  T? getData<T>(String key, {T? defaultValue}) {
    if (!isValid || data == null) return defaultValue;

    final value = data![key];
    if (value == null) return defaultValue;
    if (value is T) return value;

    // Tentative de conversion pour certains types courants
    if (T == String) return value.toString() as T;
    if (T == int && value is num) return value.toInt() as T;
    if (T == double && value is num) return value.toDouble() as T;

    return defaultValue;
  }

  /// Vérifie si toutes les clés spécifiées existent dans les données
  ///
  /// [keys] : Liste des clés à vérifier
  ///
  /// Retourne true si toutes les clés existent
  bool hasAllData(List<String> keys) {
    return keys.every(hasData);
  }

  /// Vérifie si au moins une des clés spécifiées existe dans les données
  ///
  /// [keys] : Liste des clés à vérifier
  ///
  /// Retourne true si au moins une clé existe
  bool hasAnyData(List<String> keys) {
    return keys.any(hasData);
  }
}
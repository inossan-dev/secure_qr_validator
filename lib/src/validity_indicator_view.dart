import 'package:flutter/material.dart';
import 'package:secure_qr_validator/secure_qr_validator.dart';

/// Widget affichant le statut de validation d'un QR code
/// avec une mise en forme adaptative et personnalisable
class ValidityIndicatorView extends StatelessWidget {
  /// Résultat de la validation à afficher
  final ValidationResult result;

  /// Style du texte pour les messages
  final TextStyle? textStyle;

  /// Couleur pour les QR codes valides
  final Color validColor;

  /// Couleur pour les QR codes expirés
  final Color expiredColor;

  /// Couleur pour les QR codes invalides
  final Color invalidColor;

  /// Constructeur avec options de personnalisation
  const ValidityIndicatorView({
    super.key,
    required this.result,
    this.textStyle,
    this.validColor = Colors.green,
    this.expiredColor = Colors.orange,
    this.invalidColor = Colors.red,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultStyle = theme.textTheme.bodyMedium;
    final finalStyle = textStyle ?? defaultStyle;

    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: _getStatusColor(),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(),
            color: _getStatusColor(),
          ),
          const SizedBox(width: 8.0),
          Flexible(
            child: Text(
              _getStatusMessage(),
              style: finalStyle?.copyWith(
                color: _getStatusColor(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    if (result.isValid) return validColor;
    if (result.isExpired) return expiredColor;
    return invalidColor;
  }

  IconData _getStatusIcon() {
    if (result.isValid) return Icons.check_circle;
    if (result.isExpired) return Icons.timer_off;
    return Icons.error;
  }

  String _getStatusMessage() {
    if (result.isValid) {
      return 'QR code valide';
    } else if (result.isExpired) {
      return 'QR code expiré';
    } else if (result.error != null) {
      switch (result.error!.type) {
        case ValidationErrorType.decryption:
          return 'Erreur de décryptage';
        case ValidationErrorType.decoding:
          return 'Format invalide';
        case ValidationErrorType.format:
          return 'Contenu mal formaté';
        case ValidationErrorType.version:
          return 'Version non supportée';
        case ValidationErrorType.signature:
          return 'Signature invalide';
        case ValidationErrorType.businessRule:
          return 'Règle métier non respectée:\n${result.error!.message}';
        case ValidationErrorType.unknown:
        default:
          return 'Erreur de validation:\n${result.error!.message}';
      }
    }
    return 'État inconnu';
  }
}

/// Extension permettant de simplifier l'utilisation du validateur
/// dans un contexte Flutter
extension ValidityIndicatorExtension on ValidationResult {
  /// Crée un indicateur de validité avec les paramètres par défaut
  Widget toIndicator() => ValidityIndicatorView(result: this);
}
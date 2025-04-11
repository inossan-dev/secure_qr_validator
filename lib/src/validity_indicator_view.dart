import 'package:flutter/material.dart';
import 'package:secure_qr_validator/secure_qr_validator.dart';

/// Widget displaying the validation status of a QR code
/// with adaptive and customizable formatting
class ValidityIndicatorView extends StatelessWidget {
  /// Validation result to display
  final ValidationResult result;

  /// Text style for messages
  final TextStyle? textStyle;

  /// Color for valid QR codes
  final Color validColor;

  /// Color for expired QR codes
  final Color expiredColor;

  /// Color for invalid QR codes
  final Color invalidColor;

  /// Constructor with customization options
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
        color: _getStatusColor().withValues(alpha: 0.1),
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
      return 'Valid QR code';
    } else if (result.isExpired) {
      return 'Expired QR code';
    } else if (result.error != null) {
      switch (result.error!.type) {
        case ValidationErrorType.decryption:
          return 'Decryption error';
        case ValidationErrorType.decoding:
          return 'Invalid format';
        case ValidationErrorType.format:
          return 'Malformed content';
        case ValidationErrorType.version:
          return 'Unsupported version';
        case ValidationErrorType.signature:
          return 'Invalid signature';
        case ValidationErrorType.businessRule:
          return 'Business rule violation:\n${result.error!.message}';
        case ValidationErrorType.unknown:
        default:
          return 'Validation error:\n${result.error!.message}';
      }
    }
    return 'Unknown state';
  }
}

/// Extension to simplify validator usage
/// in a Flutter context
extension ValidityIndicatorExtension on ValidationResult {
  /// Creates a validity indicator with default parameters
  Widget toIndicator() => ValidityIndicatorView(result: this);
}

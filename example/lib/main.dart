import 'package:flutter/material.dart';
import 'package:secure_qr_validator/secure_qr_validator.dart';

void main() {
  // Validator configuration
  final config = ValidatorConfig(
    validityDuration: const Duration(minutes: 5),
  );

  // Create validator
  final validator = SecureQRValidator(config);

  // QR code validation
  void validateQRCode(String qrContent) {
    final result = validator.validateQRPayload(qrContent);

    if (result.isValid) {
      print('Valid QR Code!');
      print('User ID: ${result.getData<String>('userId')}');
      print('Access Level: ${result.getData<int>('accessLevel')}');
    } else if (result.isExpired) {
      print('QR Code expired');
    } else {
      print('Invalid QR Code: ${result.error?.message}');
    }
  }
}

// Example usage in a Flutter widget
class QRValidationScreen extends StatelessWidget {
  final SecureQRValidator validator;

  const QRValidationScreen({super.key, required this.validator});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR Validation')),
      body: Center(
        child: FutureBuilder<String>(
          //future: scanQRCode(), // Hypothetical scan function
          future: Future.delayed(const Duration(seconds: 5)), // Hypothetical scan function
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const CircularProgressIndicator();
            }

            final result = validator.validateQRPayload(snapshot.data!);

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Using the ValidityIndicator widget
                ValidityIndicatorView(result: result),

                if (result.isValid) ...[
                  const SizedBox(height: 16),
                  Text('ID: ${result.getData<String>('userId')}'),
                  Text('Level: ${result.getData<int>('accessLevel')}'),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
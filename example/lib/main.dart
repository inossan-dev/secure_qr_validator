import 'package:flutter/material.dart';
import 'package:secure_qr_validator/secure_qr_validator.dart';

void main() {
  // Configuration du validateur
  final config = ValidatorConfig(
    validityDuration: const Duration(minutes: 5),
  );

  // Création du validateur
  final validator = SecureQRValidator(config);

  // Validation d'un QR code
  void validateQRCode(String qrContent) {
    final result = validator.validateQRPayload(qrContent);

    if (result.isValid) {
      print('QR Code valide !');
      print('ID Utilisateur: ${result.getData<String>('userId')}');
      print('Niveau d\'accès: ${result.getData<int>('accessLevel')}');
    } else if (result.isExpired) {
      print('QR Code expiré');
    } else {
      print('QR Code invalide: ${result.error?.message}');
    }
  }
}

// Exemple d'utilisation dans un widget Flutter
class QRValidationScreen extends StatelessWidget {
  final SecureQRValidator validator;

  const QRValidationScreen({super.key, required this.validator});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Validation QR')),
      body: Center(
        child: FutureBuilder<String>(
          //future: scanQRCode(), // Fonction hypothétique de scan
          future: Future.delayed(const Duration(seconds: 5)), // Fonction hypothétique de scan
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const CircularProgressIndicator();
            }

            final result = validator.validateQRPayload(snapshot.data!);

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Utilisation du widget ValidityIndicator
                ValidityIndicator(result: result),

                if (result.isValid) ...[
                  const SizedBox(height: 16),
                  Text('ID: ${result.getData<String>('userId')}'),
                  Text('Niveau: ${result.getData<int>('accessLevel')}'),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
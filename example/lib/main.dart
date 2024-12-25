import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:secure_qr_validator/secure_qr_validator.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Secure QR Validator Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Secure QR Validator Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  QRViewController? controller;
  String scanResultEncoded = '';
  String scanResultDecoded = '';

  // Configuration state
  late TextEditingController secretKeyController;
  bool enableEncryption = true;
  bool enableSignature = true;
  int validityDuration = 60;

  // Configuration
  late ValidatorConfig validatorConfig;
  late SecureQRValidator validator;

  @override
  void initState() {
    secretKeyController =
        TextEditingController(text: '2024#@#qrcod#orange@##perform#==');
    updateValidator();
    super.initState();
  }

  void updateValidator() {
    validatorConfig = ValidatorConfig(
      secretKey: secretKeyController.text,
      enableEncryption: enableEncryption,
      enableSignature: enableSignature,
      validityDuration: Duration(seconds: validityDuration),
    );
    validator = SecureQRValidator(validatorConfig);
  }

  @override
  Widget build(BuildContext context) {
    var scanArea = MediaQuery.of(context).size.width / 1.4;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: secretKeyController,
                    decoration: const InputDecoration(
                        labelText: 'Clé secrète AES-256 (optionnel)'),
                    onChanged: (_) => updateValidator(),
                  ),
                  SwitchListTile(
                    title: const Text('Chiffrement (optionnel)'),
                    value: enableEncryption,
                    onChanged: (value) {
                      setState(() {
                        enableEncryption = value;
                        updateValidator();
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Signature (optionnel)'),
                    value: enableSignature,
                    onChanged: (value) {
                      setState(() {
                        enableSignature = value;
                        updateValidator();
                      });
                    },
                  ),
                  Text('Durée de validité ($validityDuration sécondes)'),
                  Slider(
                    value: validityDuration.toDouble(),
                    min: 10,
                    max: 300,
                    divisions: 29,
                    label: '$validityDuration secondes',
                    onChanged: (value) {
                      setState(() {
                        validityDuration = value.toInt();
                        updateValidator();
                      });
                    },
                  ),
                ],
              ),
            ),

            // Scanner
            SizedBox(
              height: 250,
              child: QRView(
                key: GlobalKey(debugLabel: 'QR'),
                onQRViewCreated: onQRViewCreated,
                formatsAllowed: const [BarcodeFormat.qrcode],
                overlay: QrScannerOverlayShape(
                  borderColor: Colors.deepOrangeAccent,
                  borderRadius: 20,
                  borderLength: 40,
                  borderWidth: 20,
                  overlayColor: Colors.grey,
                  cutOutSize: scanArea,
                ),
                onPermissionSet: (ctrl, p) => onPermissionSet(context, ctrl, p),
              ),
            ),

            // Résultats
            Container(
              width: double.maxFinite,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text('QrCode read value : '),
                  Text(scanResultEncoded),
                  const SizedBox(height: 16),
                  const Text('QrCode decoded value : '),
                  Text(scanResultDecoded),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    log('${DateTime.now().toIso8601String()}_onPermissionSet $p');
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('no Permission')),
      );
    }
  }

  onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    bool scanned = false;
    controller.scannedDataStream.listen((scanData) {
      if (!scanned) {
        scanned = true;
        if (!mounted) return;
        setState(() {
          scanResultEncoded = scanData.code ?? '';
          final result = validator.validateQRPayload(scanResultEncoded);

          if (result.isValid) {
            scanResultDecoded = result.data.toString();
          } else if (result.isExpired) {
            scanResultDecoded = 'QR Code expired';
          } else {
            scanResultDecoded = 'Invalid QR Code: ${result.error?.message}';
          }
        });
      }
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    secretKeyController.dispose();
    super.dispose();
  }
}

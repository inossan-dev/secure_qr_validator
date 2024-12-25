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

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var scanArea = MediaQuery.of(context).size.width / 1.4;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
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
              onPermissionSet: (ctrl, p) =>
                  onPermissionSet(context, ctrl, p),
            ),
          ),
          Container(
            height: MediaQuery.of(context).size.height * 0.35,
            width: double.maxFinite,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
            child: Column(
              children: [
                const Text('QrCode read value : '),
                Text(scanResultEncoded),
                const SizedBox(height: 16,),
                const Text('QrCode decoded value : '),
                Text(scanResultDecoded),
              ],
            ),
          ),
        ],
      ),
    );
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

          //Decode result

          // 1. Validator configuration
          final config = ValidatorConfig(
            validityDuration: const Duration(seconds: 60),
          );

          // 2. Create validator
          final validator = SecureQRValidator(config);

          // QR code validation
          final result = validator.validateQRPayload(scanResultEncoded);

          if (result.isValid) {
            log('Valid QR Code!');
            scanResultDecoded = result.data.toString();
          } else if (result.isExpired) {
            log('QR Code expired');
            scanResultDecoded = 'QR Code expired';
          } else {
            log('Invalid QR Code: ${result.error?.message}');
            scanResultDecoded = 'Invalid QR Code: ${result.error?.message}';
          }
        });
      }
    });
  }

  onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    log('${DateTime.now().toIso8601String()}_onPermissionSet $p');
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('no Permission')),
      );
    }
  }
}

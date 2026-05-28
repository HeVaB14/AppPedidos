import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

class ScannerScreen extends StatefulWidget {
  final Function(String) onCodeScanned;
  final String? titulo;

  const ScannerScreen({super.key, required this.onCodeScanned, this.titulo});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool hasPermission = false;
  bool isScanning = true;
  String? errorMessage;
  String? lastScannedCode; // Para evitar escaneos repetidos

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.camera.status;

    if (status.isDenied) {
      final result = await Permission.camera.request();
      if (result.isGranted) {
        setState(() {
          hasPermission = true;
        });
      } else {
        setState(() {
          errorMessage = 'Se necesita permiso de cámara para escanear';
        });
      }
    } else if (status.isGranted) {
      setState(() {
        hasPermission = true;
      });
    }
  }

  void _onCodeDetected(String code) async {
    // Evitar escaneos repetidos del mismo código
    if (!isScanning || lastScannedCode == code) return;

    setState(() {
      isScanning = false;
      lastScannedCode = code;
    });

    // Pequeña pausa para evitar múltiples detecciones
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      Navigator.pop(context);
      widget.onCodeScanned(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.titulo ?? 'Escanear Código de Barras'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () {
              cameraController.toggleTorch();
            },
          ),
          IconButton(
            icon: const Icon(Icons.camera_front),
            onPressed: () {
              cameraController.switchCamera();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: hasPermission
                ? MobileScanner(
                    controller: cameraController,
                    onDetect: (capture) {
                      final List<Barcode> barcodes = capture.barcodes;
                      for (final barcode in barcodes) {
                        final rawValue = barcode.rawValue;
                        if (rawValue != null && rawValue.isNotEmpty) {
                          _onCodeDetected(rawValue);
                          break;
                        }
                      }
                    },
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.camera_alt,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          errorMessage ?? 'Solicitando permisos de cámara...',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _checkPermission,
                          child: const Text('Solicitar Permiso'),
                        ),
                      ],
                    ),
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.black87,
            child: const Center(
              child: Text(
                'Centra el código de barras en el cuadro',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                const Text('Manual:', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    onSubmitted: (value) {
                      if (value.isNotEmpty) {
                        Navigator.pop(context);
                        widget.onCodeScanned(value);
                      }
                    },
                    decoration: const InputDecoration(
                      hintText: 'Ingresa código manualmente',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

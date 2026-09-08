import 'package:material_ui/material_ui.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/qr_router_service.dart';
import '../utils/app_logger.dart';
import '../utils/connectivity_guard.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool _screenOpened = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await ConnectivityGuard.ensureOnline(context,
          message:
              'Scanning cloud song/playlist QRs works best online. Offline scans may fail for new content.');
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Song QR'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: colorScheme.onSurface,
      ),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && !_screenOpened) {
                final String? code = barcodes.first.rawValue;
                if (code != null) {
                  _screenOpened = true;
                  AppLogger.d('Scanner', 'QR Detected: $code');

                  // Use the router to handle the URL
                  QRRouterService.instance.handleUrl(context, code).then((_) {
                    // If navigation happened, we don't need to do anything.
                    // If not, we might want to reset the flag after a delay.
                    Future.delayed(const Duration(seconds: 2), () {
                      if (mounted) setState(() => _screenOpened = false);
                    });
                  }).catchError((e) {
                    AppLogger.e('Scanner', 'Error handling QR', e);
                    if (mounted) setState(() => _screenOpened = false);
                  });
                }
              }
            },
          ),
          // Custom Overlay
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.primary, width: 4),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          const Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Align the QR code within the frame',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

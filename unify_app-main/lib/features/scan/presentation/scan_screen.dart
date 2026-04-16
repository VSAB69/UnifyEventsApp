import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:convert';

import 'scan_controller.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> with TickerProviderStateMixin {
  late MobileScannerController cameraController;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
    );
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _scaleAnimation =
        Tween<double>(begin: 0.8, end: 1.1).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.fastOutSlowIn,
    ));
    
    // Reset animation on add listener
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.reverse();
      }
    });
  }

  @override
  void dispose() {
    cameraController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleDetect(BarcodeCapture capture) {
    if (capture.barcodes.isEmpty) return;
    
    final String? raw = capture.barcodes.first.rawValue;
    if (raw == null) return;

    final controller = ref.read(scanControllerProvider.notifier);
    final state = ref.read(scanControllerProvider);

    if (state.isProcessing || state.isSuccess || state.errorMessage != null) return;

    try {
      final data = jsonDecode(raw);
      if (data["type"] != "event_checkin") {
        controller.processQR("invalid_token"); // fake to force error
        return;
      }
      HapticFeedback.mediumImpact();
      controller.processQR(data["token"]);
    } catch (e) {
      controller.processQR("invalid_json"); // fake to force error
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scanControllerProvider);

    ref.listen<ScanState>(scanControllerProvider, (previous, next) {
      if (next.isSuccess || next.errorMessage != null) {
        _animationController.forward();
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) ref.read(scanControllerProvider.notifier).reset();
        });
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: _handleDetect,
          ),
          
          // Custom Overlay
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomPaint(
                  painter: QRScannerBorderPainter(
                    color: state.isSuccess 
                        ? Colors.green 
                        : state.errorMessage != null 
                            ? Colors.red 
                            : const Color(0xFFFF1C7C),
                  ),
                  child: const SizedBox(width: 250, height: 250),
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    "Scan the QR ticket to mark attendance of participant",
                    style: GoogleFonts.manrope(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          
          // Result Overlay
          if (state.isSuccess || state.errorMessage != null)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        color: state.isSuccess ? Colors.green.withOpacity(0.9) : Colors.red.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            state.isSuccess ? Icons.check_circle : Icons.error,
                            color: Colors.white,
                            size: 64,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            state.isSuccess
                                ? "Checked In Successfully"
                                : state.errorMessage ?? "Error",
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          if (state.isSuccess && state.participantName != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              state.participantName!,
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
          // Processing overlay
          if (state.isProcessing && !state.isSuccess && state.errorMessage == null)
            Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}

class QRScannerBorderPainter extends CustomPainter {
  final Color color;

  QRScannerBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const double cornerLength = 40.0;
    const double radius = 24.0;

    // Top-Left
    var path = Path()
      ..moveTo(0, cornerLength)
      ..lineTo(0, radius)
      ..quadraticBezierTo(0, 0, radius, 0)
      ..lineTo(cornerLength, 0);
    canvas.drawPath(path, paint);

    // Top-Right
    path = Path()
      ..moveTo(size.width - cornerLength, 0)
      ..lineTo(size.width - radius, 0)
      ..quadraticBezierTo(size.width, 0, size.width, radius)
      ..lineTo(size.width, cornerLength);
    canvas.drawPath(path, paint);

    // Bottom-Left
    path = Path()
      ..moveTo(0, size.height - cornerLength)
      ..lineTo(0, size.height - radius)
      ..quadraticBezierTo(0, size.height, radius, size.height)
      ..lineTo(cornerLength, size.height);
    canvas.drawPath(path, paint);

    // Bottom-Right
    path = Path()
      ..moveTo(size.width - cornerLength, size.height)
      ..lineTo(size.width - radius, size.height)
      ..quadraticBezierTo(size.width, size.height, size.width, size.height - radius)
      ..lineTo(size.width, size.height - cornerLength);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant QRScannerBorderPainter oldDelegate) => oldDelegate.color != color;
}

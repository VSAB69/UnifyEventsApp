import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:convert';
import 'package:dio/dio.dart';

import 'scan_controller.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen>
    with TickerProviderStateMixin {
  late MobileScannerController cameraController;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  bool isProcessing = false;
  bool isPreviewOpen = false;
  String? lastScannedToken;

  @override
  void initState() {
    super.initState();
    cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
    );
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.fastOutSlowIn,
      ),
    );

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

  void _handleDetect(BarcodeCapture capture) async {
    final scanState = ref.read(scanControllerProvider);
    if (scanState.isProcessing || isPreviewOpen) return;

    if (capture.barcodes.isEmpty) return;

    final barcode = capture.barcodes.first;
    final String? raw = barcode.rawValue;

    if (raw == null || raw.isEmpty) return;

    String? token;
    try {
      final parsed = jsonDecode(raw);
      if (parsed is Map) {
        // Support JSON with "token" or "qr_token"
        token = (parsed["token"] ?? parsed["qr_token"])?.toString();
      } else {
        // Fallback to raw string if Map but keys missing
        token = raw;
      }
    } catch (_) {
      // Not JSON, treat as raw token
      token = raw;
    }

    if (token == null || token.trim().isEmpty) {
      showInvalidQRModal();
      return;
    }

    if (token == lastScannedToken) return;

    setState(() {
      lastScannedToken = token;
      isProcessing = true;
    });

    // STOP SCANNER IMMEDIATELY
    cameraController.stop();

    try {
      final preview = await ref
          .read(scanControllerProvider.notifier)
          .fetchPreview(token!);

      if (!mounted) return;

      if (preview != null) {
        // 🔴 HANDLE ALREADY CHECKED-IN
        if (preview["already_checked_in"] == true) {
          setState(() => isPreviewOpen = true);
          showAlreadyCheckedInModal(preview);
        } else {
          setState(() => isPreviewOpen = true);
          showPreviewModal(preview);
        }
      } else {
        // If preview is null, reset and let them try again (per requirement 5)
        resetScanner();
      }
    } on DioError catch (e) {
      if (!mounted) return;

      final status = e.response?.statusCode;

      // ✅ ONLY show invalid modal for 404
      if (status == 404) {
        showInvalidQRModal();
      } else if (status == 400) {
        // Handle "Already checked-in"
        final data = e.response?.data;
        if (data != null && data.toString().contains('Already checked-in')) {
          setState(() => isPreviewOpen = true);
          showAlreadyCheckedInModal(data);
        } else {
          resetScanner();
        }
      } else {
        // Other errors → silent reset
        resetScanner();
      }
    } catch (e) {
      if (!mounted) return;
      // Generic error → silent reset
      resetScanner();
    }
  }

  void showInvalidQRModal() {
    cameraController.stop();
    setState(() {
      isPreviewOpen = true;
    });

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              const Text(
                "Invalid QR",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "This QR code is not valid.",
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  resetScanner();
                },
                child: const Text(
                  "Scan Again",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void showPreviewModal(Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Preview Check-in",
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
              const SizedBox(height: 12),
              Text(
                data["participant_name"]?.toString() ?? "Unknown",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                data["event_name"]?.toString() ?? "",
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              Text(
                data["slot"]?.toString() ?? "",
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  await confirmCheckIn(
                    data["qr_token"]?.toString() ??
                        data["token"]?.toString() ??
                        "",
                  );
                },
                child: const Text(
                  "Confirm Check-in",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  resetScanner();
                },
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void showAlreadyCheckedInModal(Map data) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline, color: Colors.orange, size: 64),
            const SizedBox(height: 16),
            const Text(
              "Already Checked In",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              data["participant_name"]?.toString() ?? "",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              data["event_name"]?.toString() ?? "",
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            Text(
              data["slot"]?.toString() ?? "",
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                resetScanner();
              },
              child: const Text(
                "Scan Next",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> confirmCheckIn(String token) async {
    try {
      final res = await ref
          .read(scanControllerProvider.notifier)
          .checkIn(token);

      Navigator.pop(context); // Close preview
      showSuccessModal(res["participant_name"]?.toString() ?? "Participant");
    } on DioError catch (e) {
      Navigator.pop(context);
      if (e.response?.statusCode == 404) {
        showInvalidQRModal();
      } else {
        resetScanner();
      }
    } catch (e) {
      Navigator.pop(context);
      resetScanner();
    }
  }

  void showSuccessModal(String participantName) {
    HapticFeedback.mediumImpact();
    
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            const Text(
              "Check-in Successful",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              participantName,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                resetScanner();
              },
              child: const Text(
                "Scan Next",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void resetScanner() {
    setState(() {
      isPreviewOpen = false;
      isProcessing = false;
      lastScannedToken = null;
    });
    ref.read(scanControllerProvider.notifier).reset();
    cameraController.start();
  }

  void closePreview() {
    Navigator.pop(context);
    resetScanner();
  }

  void showSuccess(String participantName) {
    HapticFeedback.mediumImpact();
    ref.read(scanControllerProvider.notifier).markSuccess(participantName);
  }

  void showError(String msg) {
    HapticFeedback.lightImpact();
    showInvalidQRModal();
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

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;

        context.go('/home');
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text(
            '',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
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

            // New CTA
            Positioned(
              bottom: 90,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF4C1D95)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.purpleAccent, blurRadius: 12),
                  ],
                ),
                child: const Center(
                  child: Text(
                    "Scan to Check-in Participants",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: state.isSuccess
                              ? Colors.green.withOpacity(0.9)
                              : Colors.red.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              state.isSuccess
                                  ? Icons.check_circle
                                  : Icons.error,
                              color: Colors.white,
                              size: 64,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              state.isSuccess
                                  ? "Checked In Successfully"
                                  : state.errorMessage ?? "Error",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (state.isSuccess &&
                                state.participantName != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                state.participantName!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
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
            if (state.isProcessing &&
                !state.isSuccess &&
                state.errorMessage == null)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
                ),
              ),
          ],
        ),
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
      ..quadraticBezierTo(
        size.width,
        size.height,
        size.width,
        size.height - radius,
      )
      ..lineTo(size.width, size.height - cornerLength);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant QRScannerBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}

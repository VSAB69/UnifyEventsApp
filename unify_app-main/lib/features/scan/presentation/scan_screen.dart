import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../../core/sync/sync_service.dart';
import 'scan_controller.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> with TickerProviderStateMixin {
  late MobileScannerController cameraController;
  bool isPreviewOpen = false;
  bool isScanningLocked = false;
  String? lastScannedToken;

  @override
  void initState() {
    super.initState();
    cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _handleDetect(BarcodeCapture capture) async {
    if (isScanningLocked || isPreviewOpen) return;
    if (capture.barcodes.isEmpty) return;

    final barcode = capture.barcodes.first;
    final String? raw = barcode.rawValue;
    if (raw == null || raw.isEmpty) return;

    String? token;
    try {
      final parsed = jsonDecode(raw);
      if (parsed is Map && parsed["type"] == "event_checkin") {
        token = parsed["token"]?.toString();
      }
    } catch (_) {
      token = raw; 
    }

    if (token == null || token.trim().isEmpty) {
      _triggerInvalid();
      return;
    }

    setState(() {
      isScanningLocked = true;
      lastScannedToken = token;
    });
    cameraController.stop();

    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final hasConnection = !connectivityResult.contains(ConnectivityResult.none);

      if (!hasConnection) {
        ref.read(syncServiceProvider).addPendingCheckin(token);
        showOfflineQueueModal();
        return;
      }

      final preview = await ref.read(scanControllerProvider.notifier).fetchPreview(token);

      if (!mounted) return;

      if (preview != null) {
        final status = preview["status"];
        
        if (status == "already_checked_in") {
          showAlreadyCheckedInModal(preview);
        } else if (status == "valid") {
          showPreviewModal(preview, token);
        } else if (status == "forbidden") {
          showAccessDeniedModal();
        } else {
          _resetWithDelay();
        }
      }
    } on DioException catch (e) {
      if (!mounted) return;
      final data = e.response?.data;
      if (e.response?.statusCode == 404 || (data is Map && data["status"] == "invalid")) {
        showInvalidQRModal();
      } else {
        _resetWithDelay();
      }
    }
  }

  void _triggerInvalid() {
    cameraController.stop();
    showInvalidQRModal();
  }

  void _resetWithDelay() {
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) resetScanner();
    });
  }

  // --- UI MODALS ---

  void showInvalidQRModal() {
    _showStatusModal(
      icon: Icons.qr_code_scanner_rounded,
      iconColor: Colors.redAccent,
      title: "Invalid QR",
      subtitle: "This ticket is not recognized or may have been tampered with.",
    );
  }

  void showAccessDeniedModal() {
    _showStatusModal(
      icon: Icons.lock_person_rounded,
      iconColor: Colors.orange,
      title: "Access Denied",
      subtitle: "You are not an assigned organiser for this specific event.",
    );
  }

  void showAlreadyCheckedInModal(Map data) {
    _showStatusModal(
      icon: Icons.person_pin_circle_rounded,
      iconColor: Colors.blueAccent,
      title: "Already Checked In",
      subtitle: "${data["participant_name"]}\n${data["event_name"]}",
      timing: data["slot"],
    );
  }

  void showPreviewModal(Map<String, dynamic> data, String token) {
    setState(() => isPreviewOpen = true);
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor: const Color(0xFF0F0F0F),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (_) => Container(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ✅ Fixed: Changed FontWeight.black to FontWeight.w900
            const Text("PREVIEW CHECK-IN", style: TextStyle(color: Colors.white30, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 10)),
            const SizedBox(height: 16),
            Text(data["participant_name"] ?? "Guest", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: Colors.white)),
            Text(data["event_name"] ?? "Event", style: const TextStyle(color: Color(0xFFF72585), fontWeight: FontWeight.bold)),
            const Divider(height: 32, color: Colors.white10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.calendar_month, color: Colors.white54, size: 16),
                const SizedBox(width: 8),
                Text(data["slot"] ?? "TBA", style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                minimumSize: const Size.fromHeight(55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              onPressed: () => confirmCheckIn(token),
              child: const Text("CONFIRM ENTRY", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            TextButton(
              onPressed: () { Navigator.pop(context); resetScanner(); },
              child: const Text("Cancel", style: TextStyle(color: Colors.white38)),
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusModal({required IconData icon, required Color iconColor, required String title, required String subtitle, String? timing}) {
    setState(() => isPreviewOpen = true);
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor: const Color(0xFF0F0F0F),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (_) => _BaseModal(
        icon: icon,
        iconColor: iconColor,
        title: title,
        subtitle: subtitle,
        timing: timing,
        buttonText: "CONTINUE SCANNING",
        onPressed: () {
          Navigator.pop(context);
          resetScanner();
        },
      ),
    );
  }

  void showOfflineQueueModal() {
    _showStatusModal(icon: Icons.cloud_off, iconColor: Colors.grey, title: "Offline Mode", subtitle: "Check-in saved locally. Syncing later.");
  }

  Future<void> confirmCheckIn(String token) async {
    try {
      final res = await ref.read(scanControllerProvider.notifier).checkIn(token);
      Navigator.pop(context);
      showSuccessModal(res);
    } catch (e) {
      Navigator.pop(context);
      resetScanner();
    }
  }

  void showSuccessModal(Map data) {
    _showStatusModal(
      icon: Icons.check_circle_rounded,
      iconColor: Colors.greenAccent,
      title: "Access Granted",
      subtitle: data["participant_name"] ?? "Participant",
      timing: "Verified at ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}",
    );
  }

  void resetScanner() {
    if (!mounted) return;
    setState(() {
      isPreviewOpen = false;
      isScanningLocked = false;
      lastScannedToken = null;
    });
    ref.read(scanControllerProvider.notifier).reset();
    cameraController.start();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scanControllerProvider);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(controller: cameraController, onDetect: _handleDetect),
          
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const Text(
                  "ENTRY SCANNER",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 4),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(20)),
                  child: const Text(
                    "Scan to check in participants",
                    style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          Center(
            child: CustomPaint(
              painter: QRScannerBorderPainter(
                color: state.isSuccess ? Colors.greenAccent : const Color(0xFFF72585),
              ),
              child: const SizedBox(width: 260, height: 260),
            ),
          ),

          if (state.isProcessing)
            Container(color: Colors.black45, child: const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)))),
        ],
      ),
    );
  }
}

class _BaseModal extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title, subtitle, buttonText;
  final String? timing;
  final VoidCallback onPressed;
  
  const _BaseModal({required this.icon, required this.iconColor, required this.title, required this.subtitle, this.timing, required this.buttonText, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 70),
          const SizedBox(height: 20),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Colors.white, letterSpacing: -0.5)),
          const SizedBox(height: 10),
          Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white60, fontSize: 15)),
          if (timing != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
              child: Text(timing!, style: const TextStyle(color: Color(0xFF4CC9F0), fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ],
          const SizedBox(height: 32),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A1A1A),
              minimumSize: const Size.fromHeight(55),
              side: const BorderSide(color: Colors.white10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            onPressed: onPressed,
            child: Text(buttonText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
    final paint = Paint()..color = color..strokeWidth = 6..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    const double len = 40;
    const double rad = 20;

    var path = Path()..moveTo(0, len)..lineTo(0, rad)..quadraticBezierTo(0, 0, rad, 0)..lineTo(len, 0);
    canvas.drawPath(path, paint);
    path = Path()..moveTo(size.width - len, 0)..lineTo(size.width - rad, 0)..quadraticBezierTo(size.width, 0, size.width, rad)..lineTo(size.width, len);
    canvas.drawPath(path, paint);
    path = Path()..moveTo(0, size.height - len)..lineTo(0, size.height - rad)..quadraticBezierTo(0, size.height, rad, size.height)..lineTo(len, size.height);
    canvas.drawPath(path, paint);
    path = Path()..moveTo(size.width - len, size.height)..lineTo(size.width - rad, size.height)..quadraticBezierTo(size.width, size.height, size.width, size.height - rad)..lineTo(size.width, size.height - len);
    canvas.drawPath(path, paint);
  }

  @override
  // ✅ Fixed: Cast oldDelegate to QRScannerBorderPainter
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is QRScannerBorderPainter) {
      return oldDelegate.color != color;
    }
    return true;
  }
}
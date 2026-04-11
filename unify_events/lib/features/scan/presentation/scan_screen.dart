import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        title: const Text('Scan QR Ticket', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: state.isSuccess
                      ? Colors.green
                      : state.errorMessage != null
                          ? Colors.red
                          : Colors.white54,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: (state.isSuccess || state.errorMessage != null)
                    ? [
                        BoxShadow(
                          color: state.isSuccess ? Colors.green.withOpacity(0.5) : Colors.red.withOpacity(0.5),
                          blurRadius: 30,
                          spreadRadius: 5,
                        )
                      ]
                    : [],
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

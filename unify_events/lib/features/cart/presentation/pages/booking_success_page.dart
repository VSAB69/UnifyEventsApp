import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BookingSuccessPage extends StatefulWidget {
  final String bookingId;

  const BookingSuccessPage({super.key, required this.bookingId});

  @override
  State<BookingSuccessPage> createState() => _BookingSuccessPageState();
}

class _BookingSuccessPageState extends State<BookingSuccessPage> with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    
    _scaleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);

    _scaleController.forward();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7C3AED).withOpacity(0.4 * _pulseController.value + 0.2), 
                              blurRadius: 40 + (20 * _pulseController.value), 
                              spreadRadius: 10 + (5 * _pulseController.value)
                            ),
                            BoxShadow(
                              color: const Color(0xFF38BDF8).withOpacity(0.2 * _pulseController.value), 
                              blurRadius: 60, 
                              spreadRadius: 20
                            ),
                          ],
                          gradient: const LinearGradient(
                            colors: [Color(0xFF7C3AED), Color(0xFF38BDF8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        ),
                        child: const Icon(Icons.check_rounded, size: 100, color: Colors.white),
                      );
                    }
                  ),
                ),
                const SizedBox(height: 50),
                FadeTransition(
                  opacity: _fadeController,
                  child: Column(
                    children: [
                      const Text(
                        '🎉 Booking Confirmed!', 
                        style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 0.5)
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Your events are successfully booked.\nBooking ID: #${widget.bookingId}', 
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.5)
                      ),
                      const SizedBox(height: 48),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF7C3AED)),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              onPressed: () => context.go('/home'),
                              child: const Text('Back to Home', style: TextStyle(color: Colors.white, fontSize: 16)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF7C3AED),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              onPressed: () => context.go('/bookings'),
                              child: const Text('View Bookings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

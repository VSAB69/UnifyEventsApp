import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';

import '../providers/cart_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class PaymentPage extends ConsumerStatefulWidget {
  final num totalAmount;

  const PaymentPage({super.key, required this.totalAmount});

  @override
  ConsumerState<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends ConsumerState<PaymentPage> {
  bool _isProcessing = false;

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: const TextStyle(color: Colors.white)),
      backgroundColor: Colors.redAccent,
    ));
  }

  void _handlePayment() async {
    setState(() => _isProcessing = true);
    
    try {
      final cartState = ref.read(cartDataProvider);
      final cartData = cartState.valueOrNull;

      if (cartData == null || cartData['items'] == null || (cartData['items'] as List).isEmpty) {
        throw "Your cart is empty or could not be loaded.";
      }

      final items = cartData['items'] as List;
      for (final item in items) {
        final itemId = item['id'];
        
        final timeslots = await ref.read(tempTimeslotsProvider(itemId).future);
        if (timeslots.isEmpty) {
          throw "Slot not selected for ${item['event_name'] ?? 'an event'}";
        }

        final tempBookings = await ref.read(tempBookingsProvider(itemId).future);
        final pCount = item['participants_count'] ?? 1;
        
        if (tempBookings.length != pCount) {
          throw "Participants incomplete for ${item['event_name'] ?? 'an event'}";
        }
      }

      // API CALL
      final dio = ref.read(dioProvider);
      final res = await dio.post("/bookings/place/");
      
      final bookingId = res.data["id"];

      // Clear cart
      ref.invalidate(cartDataProvider);

      if (mounted) {
        context.go("/booking-success/$bookingId");
      }
    } catch (e) {
      if (e is DioException) {
        _showError(e.response?.data?.toString() ?? e.message ?? "Network error placing booking");
      } else {
        _showError(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final taxes = widget.totalAmount * 0.18; // Dummy 18% tax
    final convenienceFee = widget.totalAmount > 0 ? 50.0 : 0.0; // Flat fee only if amount exists
    final grandTotal = widget.totalAmount + taxes + convenienceFee;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => _isProcessing ? null : context.pop(),
        ),
        title: const Text('Secure Payment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B1B26),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Price Breakdown', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal', style: TextStyle(color: Colors.white70, fontSize: 16)),
                        Text('₹${widget.totalAmount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Taxes (18%)', style: TextStyle(color: Colors.white70, fontSize: 16)),
                        Text('₹${taxes.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Convenience Fee', style: TextStyle(color: Colors.white70, fontSize: 16)),
                        Text('₹${convenienceFee.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 16)),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(color: Colors.white10, height: 1),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Grand Total', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        Text('₹${grandTotal.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 24, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              
              const Text('Payment Method', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF7C3AED)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_wallet, color: Color(0xFF7C3AED)),
                    const SizedBox(width: 12),
                    const Expanded(child: Text('Simulated Active Gateway', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    Radio(value: true, groupValue: true, onChanged: (_) {}, activeColor: const Color(0xFF7C3AED)),
                  ],
                ),
              ),

              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  disabledBackgroundColor: const Color(0xFF7C3AED).withOpacity(0.5)
                ),
                onPressed: _isProcessing ? null : _handlePayment,
                child: _isProcessing
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Pay Securely', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

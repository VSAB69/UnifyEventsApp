import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref ref;

  RouterNotifier(this.ref) {
    ref.listen<AuthState>(authProvider, (_, __) {
      notifyListeners(); // 🔥 THIS FIXES EVERYTHING
    });
  }
}

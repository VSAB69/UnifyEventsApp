import 'package:google_sign_in/google_sign_in.dart';
import 'dart:developer' as dev;

class GoogleAuthService {
  static const String serverClientId =
      "400488433923-92fe2bnvmiq884s1sh0toguie4id46l6.apps.googleusercontent.com";

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: serverClientId, // 🔥 THIS is the fix
    scopes: ['email', 'profile'],
  );

  Future<String?> signIn() async {
    try {
      await _googleSignIn.signOut(); // force clean login

      dev.log("STEP 1: Starting Google Sign-In");

      final user = await _googleSignIn.signIn();

      if (user == null) {
        dev.log("❌ User cancelled");
        return null;
      }

      dev.log("STEP 2: Selected: ${user.email}");

      final auth = await user.authentication;

      if (auth.idToken == null) {
        throw Exception("ID Token NULL");
      }

      dev.log("STEP 3: ID TOKEN RECEIVED");

      return auth.idToken;
    } catch (e) {
      dev.log("❌ ERROR: $e");
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}
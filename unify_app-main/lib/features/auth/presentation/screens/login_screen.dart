import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(parent: _fadeController, curve: Curves.easeOutQuart),
        );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen(authProvider, (prev, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFFF1C7C),
            content: Text(
              next.error!,
              style: GoogleFonts.spaceMono(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: Colors.transparent, // Uses global CyberGridBackground
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Animated Unify Events Title
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: const [
                              Color(0xFF00E5FF),
                              Color(0xFFFF1C7C),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            stops: [
                              0.0 + (_pulseController.value * 0.2),
                              1.0 - (_pulseController.value * 0.2),
                            ],
                          ).createShader(bounds),
                          child: Text(
                            "UNIFY\nEVENTS",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.bebasNeue(
                              fontSize: 64,
                              height: 0.9,
                              letterSpacing: 6,
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "SYSTEM_ACCESS",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.spaceMono(
                        fontSize: 12,
                        letterSpacing: 4,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF00E5FF).withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Floating Glassmorphism Login Card
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, -5 + (_pulseController.value * 10)),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00E5FF).withOpacity(
                                    0.05 + (_pulseController.value * 0.05),
                                  ),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: 15,
                                  sigmaY: 15,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(32),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF0A0A0F,
                                    ).withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: const Color(
                                        0xFF00E5FF,
                                      ).withOpacity(0.3),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: child,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: usernameController,
                            label: "IDENTIFIER",
                            icon: Icons.person_outline,
                          ),
                          const SizedBox(height: 24),
                          _buildTextField(
                            controller: passwordController,
                            label: "CREDENTIAL",
                            icon: Icons.lock_outline,
                            isPassword: true,
                          ),
                          const SizedBox(height: 40),

                          // Futuristic Login Button
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFF1C7C),
                                      Color(0xFFB026FF),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFF1C7C)
                                          .withOpacity(
                                            0.4 +
                                                (_pulseController.value * 0.2),
                                          ),
                                      blurRadius: 20,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    splashColor: Colors.white.withOpacity(0.2),
                                    onTap: authState.isLoading
                                        ? null
                                        : () {
                                            FocusScope.of(context).unfocus();
                                            ref
                                                .read(authProvider.notifier)
                                                .login(
                                                  usernameController.text,
                                                  passwordController.text,
                                                );
                                          },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 20,
                                      ),
                                      child: Center(
                                        child: authState.isLoading
                                            ? const SizedBox(
                                                height: 24,
                                                width: 24,
                                                child:
                                                    CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 2.5,
                                                    ),
                                              )
                                            : Text(
                                                "INITIATE_SESSION",
                                                style: GoogleFonts.spaceMono(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w900,
                                                  letterSpacing: 2.0,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      style: GoogleFonts.spaceMono(
        color: Colors.white,
        fontSize: 16,
        letterSpacing: 1.2,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.spaceMono(
          color: Colors.cyan.withOpacity(0.6),
          fontSize: 12,
          letterSpacing: 2,
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF00E5FF)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: const Color(0xFF00E5FF).withOpacity(0.15),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF00E5FF), width: 2.5),
        ),
        filled: true,
        fillColor: Colors.black.withOpacity(0.3),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 20,
          horizontal: 16,
        ),
      ),
    );
  }
}

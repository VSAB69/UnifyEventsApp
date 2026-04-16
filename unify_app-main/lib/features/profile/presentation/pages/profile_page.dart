import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/auth_provider.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await ref.read(authProvider.notifier).logout();
    if (mounted) context.go('/login');
  }

  void _showEditProfileModal(BuildContext context, String currentUsername, String currentEmail) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditProfileModal(initialUsername: currentUsername, initialEmail: currentEmail),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    
    final username = user?.username ?? 'Guest User';
    final email = user?.email ?? 'Not provided';
    final initial = username.isNotEmpty ? username[0].toUpperCase() : 'G';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background Gradient
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withOpacity(0.15),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: const Color(0xFF7C3AED).withOpacity(0.2), blurRadius: 100)],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              physics: const BouncingScrollPhysics(),
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Avatar
                      ScaleTransition(
                        scale: CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.5), width: 3),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7C3AED), Color(0xFFE81CFF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [BoxShadow(color: const Color(0xFF7C3AED).withOpacity(0.3), blurRadius: 30, spreadRadius: 5)],
                          ),
                          child: Center(
                            child: Text(
                              initial,
                              style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // User Info
                      FadeTransition(
                        opacity: CurvedAnimation(parent: _animController, curve: const Interval(0.2, 1.0)),
                        child: Column(
                          children: [
                            Text(username, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text(email, style: const TextStyle(color: Colors.white54, fontSize: 16)),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF7C3AED).withOpacity(0.2),
                                    elevation: 0,
                                    side: BorderSide(color: const Color(0xFF7C3AED).withOpacity(0.5)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  ),
                                  onPressed: () => _showEditProfileModal(context, username, email),
                                  icon: const Icon(Icons.edit, size: 18, color: Colors.white),
                                  label: const Text('Edit Profile', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent.withOpacity(0.2),
                                    elevation: 0,
                                    side: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  ),
                                  onPressed: _logout,
                                  icon: const Icon(Icons.logout, size: 18, color: Colors.white),
                                  label: const Text('Logout', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 48),
                      
                      // Actions List
                      FadeTransition(
                        opacity: CurvedAnimation(parent: _animController, curve: const Interval(0.4, 1.0)),
                        child: SlideTransition(
                          position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut)),
                          child: Column(
                            children: [
                              _buildActionItem(Icons.history, 'Booking History', () => context.go('/bookings')),
                              if (user != null && (user.role == 'admin' || user.role == 'organiser'))
                                _buildActionItem(Icons.admin_panel_settings, 'Manage Dashboard', () => context.go('/manage')),
                              _buildActionItem(Icons.help_outline, 'Help & Support', () {
                                showModalBottomSheet(
                                  context: context,
                                  backgroundColor: const Color(0xFF13131D),
                                  isScrollControlled: true,
                                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                                  builder: (context) {
                                    return Padding(
                                      padding: EdgeInsets.only(
                                        top: 32.0, left: 24.0, right: 24.0,
                                        bottom: MediaQuery.of(context).viewInsets.bottom + 80,
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text("HELP & SUPPORT", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 24),
                                          _buildContactRow("Anish", "+91 99999 99999", "[EMAIL_ADDRESS]"),
                                          const SizedBox(height: 16),
                                          _buildContactRow("Anish", "+91 99998 99998", "[EMAIL_ADDRESS]"),
                                          const SizedBox(height: 16),
                                          _buildContactRow("Anitej", "+91 99997 99997", "[EMAIL_ADDRESS]"),
                                          const SizedBox(height: 16),
                                          _buildContactRow("Arushi", "+91 99996 99996", "[EMAIL_ADDRESS]"),
                                          const SizedBox(height: 48),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    final color = isDestructive ? Colors.redAccent : Colors.white;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF13131D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
      ),
    );
  }

  Widget _buildContactRow(String name, String phone, String email) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(phone, style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 14)),
        const SizedBox(height: 4),
        Text(email, style: const TextStyle(color: Colors.white54, fontSize: 13)),
      ],
    );
  }
}

class _EditProfileModal extends ConsumerStatefulWidget {
  final String initialUsername;
  final String initialEmail;

  const _EditProfileModal({required this.initialUsername, required this.initialEmail});

  @override
  ConsumerState<_EditProfileModal> createState() => _EditProfileModalState();
}

class _EditProfileModalState extends ConsumerState<_EditProfileModal> {
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.initialUsername);
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submitParams() async {
    if (_usernameController.text.trim().isEmpty || _emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fields cannot be empty')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dio = ref.read(dioProvider);
      await dio.patch('/auth/user/', data: {
        'username': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
      });
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully!', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
        // Soft refresh auth pipeline to update user cache over network
        ref.invalidate(authProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update profile: $e', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.redAccent));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 24, left: 24, right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 120,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1B1B26),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Edit Profile', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          TextField(
            controller: _usernameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Username',
              labelStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.person, color: Color(0xFF7C3AED)),
              filled: true,
              fillColor: const Color(0xFF0A0A0F),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Email',
              labelStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.email, color: Color(0xFF7C3AED)),
              filled: true,
              fillColor: const Color(0xFF0A0A0F),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _isLoading ? null : _submitParams,
            child: _isLoading 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Save Changes', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

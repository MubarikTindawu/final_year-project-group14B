// ─────────────────────────────────────────────────────────────────────────────
// forgot_password_screen.dart
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _linkSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _showSnackbar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ]),
        backgroundColor:
        isError ? const Color(0xFFD32F2F) : AppTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _handlePasswordReset() async {
    final authProvider =
    Provider.of<AuthProvider>(context, listen: false);

    if (_emailController.text.isEmpty) {
      _showSnackbar("Please enter your email address.", isError: true);
      return;
    }

    try {
      await authProvider
          .sendPasswordReset(_emailController.text.trim());
      if (mounted) {
        setState(() => _linkSent = true);
      }
    } catch (e) {
      if (mounted) _showSnackbar(e.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      _backButton(context),
                      const SizedBox(width: 4),
                      const Text("Reset Password",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 32),
                        // Icon
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.lock_reset_rounded,
                              size: 44, color: Colors.white),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "Forgot your password?",
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.3),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Enter your registered email and we'll send you a secure reset link.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.75),
                              fontSize: 13,
                              height: 1.5),
                        ),
                        const SizedBox(height: 32),

                        // Card
                        ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: BackdropFilter(
                            filter:
                            ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.93),
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                    color:
                                    Colors.white.withOpacity(0.3)),
                                boxShadow: [
                                  BoxShadow(
                                      color:
                                      Colors.black.withOpacity(0.12),
                                      blurRadius: 24,
                                      offset: const Offset(0, 8)),
                                ],
                              ),
                              child: _linkSent
                                  ? _buildSuccessState()
                                  : _buildFormState(authProvider),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormState(AuthProvider authProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _authField(
          controller: _emailController,
          label: "Email Address",
          icon: Icons.email_outlined,
          keyboard: TextInputType.emailAddress,
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              disabledBackgroundColor:
              AppTheme.primaryGreen.withOpacity(0.6),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            onPressed:
            authProvider.isLoading ? null : _handlePasswordReset,
            child: authProvider.isLoading
                ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5))
                : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.send_rounded,
                    color: Colors.white, size: 17),
                SizedBox(width: 8),
                Text("Send Reset Link",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessState() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
              color: Color(0xFFEAF4DE), shape: BoxShape.circle),
          child: const Icon(Icons.mark_email_read_rounded,
              color: AppTheme.primaryGreen, size: 36),
        ),
        const SizedBox(height: 16),
        const Text(
          "Check your inbox!",
          style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 17,
              color: Color(0xFF1A1A1A)),
        ),
        const SizedBox(height: 8),
        Text(
          "A reset link was sent to ${_emailController.text}. Follow the link to set a new password.",
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: Color(0xFF6A6A6A), fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text("Back to Sign In",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// reset_password_screen.dart
// ─────────────────────────────────────────────────────────────────────────────
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isNewVisible = false;
  bool _isConfirmVisible = false;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showSnackbar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ]),
        backgroundColor:
        isError ? const Color(0xFFD32F2F) : AppTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      _backButton(context),
                      const SizedBox(width: 4),
                      const Text("New Password",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.shield_rounded,
                              size: 44, color: Colors.white),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "Create New Password",
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.3),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Choose a strong password to keep your farm data secure.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.75),
                              fontSize: 13,
                              height: 1.5),
                        ),
                        const SizedBox(height: 32),

                        ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: BackdropFilter(
                            filter:
                            ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.93),
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                    color:
                                    Colors.white.withOpacity(0.3)),
                                boxShadow: [
                                  BoxShadow(
                                      color:
                                      Colors.black.withOpacity(0.12),
                                      blurRadius: 24,
                                      offset: const Offset(0, 8)),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  _authField(
                                    controller: _newPasswordController,
                                    label: "New Password",
                                    icon: Icons.lock_outline,
                                    isPassword: true,
                                    isVisible: _isNewVisible,
                                    onToggleVisibility: () => setState(
                                            () => _isNewVisible =
                                        !_isNewVisible),
                                  ),
                                  const SizedBox(height: 14),
                                  _authField(
                                    controller:
                                    _confirmPasswordController,
                                    label: "Confirm Password",
                                    icon: Icons.lock_reset_rounded,
                                    isPassword: true,
                                    isVisible: _isConfirmVisible,
                                    onToggleVisibility: () => setState(
                                            () => _isConfirmVisible =
                                        !_isConfirmVisible),
                                  ),
                                  const SizedBox(height: 10),
                                  // Password hint
                                  Row(
                                    children: [
                                      const Icon(
                                          Icons.info_outline_rounded,
                                          size: 13,
                                          color: Color(0xFFAAAAAA)),
                                      const SizedBox(width: 5),
                                      Text(
                                        "Minimum 6 characters recommended.",
                                        style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 11),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 52,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                        AppTheme.primaryGreen,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                            BorderRadius.circular(
                                                16)),
                                      ),
                                      onPressed: () {
                                        if (_newPasswordController
                                            .text.isEmpty) {
                                          _showSnackbar(
                                              "Please enter a new password.",
                                              isError: true);
                                          return;
                                        }
                                        if (_newPasswordController
                                            .text !=
                                            _confirmPasswordController
                                                .text) {
                                          _showSnackbar(
                                              "Passwords do not match.",
                                              isError: true);
                                          return;
                                        }
                                        _showSnackbar(
                                            "Password updated! Please sign in.",
                                            isError: false);
                                        Navigator.of(context)
                                            .popUntil(
                                                (route) => route.isFirst);
                                      },
                                      child: const Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.check_circle_rounded,
                                              color: Colors.white,
                                              size: 18),
                                          SizedBox(width: 8),
                                          Text("Update Password",
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight:
                                                  FontWeight.w700,
                                                  fontSize: 15)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared helpers used across all auth screens ───────────────────────────────

Widget _buildBackground() {
  return Stack(
    children: [
      Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1B5E20), Color(0xFF2D7A0A), Color(0xFF5AA518)],
          ),
        ),
      ),
      Positioned(
        top: -60,
        left: -60,
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.06),
          ),
        ),
      ),
      Positioned(
        bottom: -80,
        right: -40,
        child: Container(
          width: 260,
          height: 260,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withOpacity(0.05),
          ),
        ),
      ),
    ],
  );
}

Widget _backButton(BuildContext context) {
  return GestureDetector(
    onTap: () => Navigator.pop(context),
    child: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.arrow_back_ios_new_rounded,
          color: Colors.white, size: 16),
    ),
  );
}

Widget _authField({
  required TextEditingController controller,
  required String label,
  required IconData icon,
  bool isPassword = false,
  bool isVisible = false,
  VoidCallback? onToggleVisibility,
  TextInputType keyboard = TextInputType.text,
}) {
  return TextField(
    controller: controller,
    obscureText: isPassword && !isVisible,
    keyboardType: keyboard,
    style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
    decoration: InputDecoration(
      labelText: label,
      labelStyle:
      const TextStyle(color: Color(0xFF9A9A9A), fontSize: 13),
      prefixIcon: Icon(icon, color: AppTheme.primaryGreen, size: 18),
      suffixIcon: isPassword
          ? IconButton(
        icon: Icon(
          isVisible
              ? Icons.visibility_rounded
              : Icons.visibility_off_rounded,
          color: const Color(0xFFAAAAAA),
          size: 18,
        ),
        onPressed: onToggleVisibility,
      )
          : null,
      filled: true,
      fillColor: const Color(0xFFF5F7F2),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE0EDD4), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:
        const BorderSide(color: AppTheme.primaryGreen, width: 1.8),
      ),
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}
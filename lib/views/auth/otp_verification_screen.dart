import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme.dart';

class OTPVerificationScreen extends StatelessWidget {
  final String email;
  const OTPVerificationScreen({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. BRAND BACKGROUND
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.primaryGreen, Color(0xFF2E7D32), AppTheme.accentGreen],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),

                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          const Icon(Icons.mark_email_read_rounded, size: 100, color: Colors.white),
                          const SizedBox(height: 24),
                          const Text(
                            "Check Your Email",
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "We've sent a high-speed recovery link to:\n$email",
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                          const SizedBox(height: 40),

                          // 2. FROSTED INTERACTIVE CARD
                          ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                padding: const EdgeInsets.all(30),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Column(
                                  children: [
                                    const Text(
                                      "Didn't receive the link?",
                                      style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(height: 20),

                                    // RETURN TO LOGIN BUTTON
                                    SizedBox(
                                      width: double.infinity,
                                      height: 55,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.primaryGreen,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                        ),
                                        onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                                        child: const Text(
                                          "BACK TO SIGN IN",
                                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),

                                    TextButton(
                                      onPressed: () {
                                        // Logic to resend if needed
                                      },
                                      child: const Text(
                                        "Resend Email",
                                        style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold),
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'login_page.dart';
import 'sign_up_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Set the status bar icons to be light
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent, // Transparent status bar
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Elevate App',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0A), // Darker background
        fontFamily: 'sans-serif',
      ),
      home: const WelcomeScreen(),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  // Helper method to build one of the logo bars
  Widget _buildLogoBar(double width) {
    return Container(
      width: width,
      height: 14,
      decoration: BoxDecoration(
        color: const Color(0xFF9ABE46),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Define colors matching login/signup
    const Color appGreen = Color(0xFF9ABE46);
    const Color textOnButton = Color(0xFF1A1A1A);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),

              // --- Logo ---
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 40.0),
                    child: _buildLogoBar(90),
                  ),
                  const SizedBox(height: 10),
                  _buildLogoBar(100),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(right: 40.0),
                    child: _buildLogoBar(90),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // --- App Name ---
              const Text(
                'ELEVATE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF9ABE46),
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 16),

              // --- Tagline ---
              const Text(
                'Invest. Grow. Elevate.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF888888),
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
              ),

              const Spacer(flex: 3),

              // --- Register Button ---
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const SignUpPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appGreen,
                    foregroundColor: textOnButton,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: const Text(
                    'REGISTER',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // --- Login Text ---
              Center(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      color: Color(0xFF888888),
                      fontSize: 14,
                    ),
                    children: [
                      const TextSpan(text: 'Already have an account? '),
                      TextSpan(
                        text: 'Login',
                        style: const TextStyle(
                          color: appGreen,
                          fontWeight: FontWeight.w600,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const LoginPage()),
                            );
                          },
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}

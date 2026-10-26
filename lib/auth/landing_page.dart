
import 'package:flutter/material.dart';

import 'design.dart';
import 'login.dart';
import 'register.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  Widget _ring({
    required double size,
    required double thickness,
    required Color color,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: color,
          width: thickness,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final compact = screenSize.height < 700;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE5F4EE),
              Color(0xFFD5EEE6),
              Color(0xFFC8E6DC),
            ],
          ),
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // Decorative circles inspired by the Figma background.
            Positioned(
              right: -135,
              top: screenSize.height * 0.29,
              child: _ring(
                size: 350,
                thickness: 28,
                color: Colors.white.withValues(alpha: 0.42),
              ),
            ),

            Positioned(
              right: -70,
              top: screenSize.height * 0.40,
              child: _ring(
                size: 230,
                thickness: 20,
                color: const Color(0xFFB0DCD0)
                    .withValues(alpha: 0.55),
              ),
            ),

            Positioned(
              left: screenSize.width * 0.20,
              bottom: screenSize.height * 0.12,
              child: _ring(
                size: 250,
                thickness: 17,
                color: Colors.white.withValues(alpha: 0.53),
              ),
            ),

            // Main content.
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        const Expanded(
                          child: CcLogo(
                            size: 39,
                            light: true,
                          ),
                        ),

                        const SizedBox(width: 8),

                        OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginPage(),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: kInk,
                            side: BorderSide.none,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 11,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Log in',
                                style: TextStyle(fontSize: 13),
                              ),
                              SizedBox(width: 5),
                              Icon(Icons.arrow_forward, size: 15),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: compact ? 43 : 58),

                    const Text(
                      'A HEALTHIER CAMPUS STARTS WITH YOU',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 0.6,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF148D7B),
                      ),
                    ),

                    const SizedBox(height: 18),

                    const Text(
                      'Your Health,\n'
                          'Your Campus,\n'
                          'Your Care.',
                      style: TextStyle(
                        fontSize: 42,
                        height: 1.07,
                        fontWeight: FontWeight.w300,
                        letterSpacing: -1.6,
                        color: Color(0xFF102B2E),
                      ),
                    ),

                    const SizedBox(height: 22),

                    const Text(
                      'Your student health information and\n'
                          'campus clinic appointments, together\n'
                          'in one caring space.',
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.55,
                        color: Color(0xFF567B76),
                      ),
                    ),

                    const SizedBox(height: 26),

                    SizedBox(
                      width: 195,
                      child: CcButton(
                        label: 'Get Started',
                        loading: false,
                        color: kTealDark,
                        height: 48,
                        radius: 12,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterPage(),
                            ),
                          );
                        },
                      ),
                    ),

                    const Spacer(),

                    const CcFooterNote(
                      text:
                      'Your health information is private and secure.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

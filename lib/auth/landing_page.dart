import 'package:flutter/material.dart';

import 'design.dart';
import 'login.dart';
import 'register.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  Widget _ring(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(opacity),
          width: 26,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE4F3EE), Color(0xFFC9E4DB)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(right: -110, top: 230, child: _ring(320, 0.45)),
            Positioned(left: 30, bottom: 110, child: _ring(210, 0.35)),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Flexible(child: CcLogo(size: 48, light: true)),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: kInk,
                            side: const BorderSide(color: kBorder),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                          ),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginPage(),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Log in', style: TextStyle(fontSize: 16)),
                              SizedBox(width: 6),
                              Icon(Icons.arrow_forward, size: 18),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),
                    const Text(
                      'A HEALTHIER CAMPUS STARTS WITH YOU',
                      style: TextStyle(
                        fontSize: 12.5,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF0E8A78),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Your Health,\nYour Campus,\nYour Care.',
                      style: TextStyle(
                        fontSize: 44,
                        height: 1.15,
                        fontWeight: FontWeight.w300,
                        letterSpacing: -1,
                        color: Color(0xFF0F2A2A),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Your student health information and campus clinic appointments, together in one caring space.',
                      style: TextStyle(
                        fontSize: 17,
                        height: 1.5,
                        color: Color(0xFF3F5F5B),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: 230,
                      child: CcButton(
                        label: 'Get Started',
                        loading: false,
                        color: kTealDark,
                        height: 58,
                        radius: 16,
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterPage(),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    const CcFooterNote(),
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
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'auth_style.dart';

class OtpScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;
  final int? resendToken;

  const OtpScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
    this.resendToken,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final otpController = TextEditingController();

  bool isLoading = false;
  late String verificationId;

  @override
  void initState() {
    super.initState();
    verificationId = widget.verificationId;
  }

  Future<void> verifyOTP() async {
    final otp = otpController.text.trim();

    if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
      showAuthSnack(context, 'Please enter a valid 6-digit OTP', error: true);
      return;
    }

    setState(() => isLoading = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      if (!mounted) return;
      backToRoot(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message;

      switch (e.code) {
        case 'invalid-verification-code':
          message = 'Incorrect OTP. Please try again.';
          break;
        case 'session-expired':
          message = 'OTP expired. Request a new code.';
          break;
        default:
          message = e.message ?? 'Verification failed';
      }

      showAuthSnack(context, message, error: true);
    } catch (_) {
      if (!mounted) return;
      showAuthSnack(context, 'Something went wrong', error: true);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Verify OTP',
      subtitle: 'Enter the code sent to ${widget.phoneNumber}',
      icon: Icons.verified_user,
      card: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, letterSpacing: 8),
            decoration: authInput('6-digit OTP', Icons.lock_outline)
                .copyWith(counterText: ''),
          ),
          const SizedBox(height: 22),
          AuthButton(label: 'Verify OTP', loading: isLoading, onPressed: verifyOTP),
          const SizedBox(height: 8),
          TextButton(
            onPressed: isLoading ? null : () => Navigator.pop(context),
            child: const Text(
              'Change Phone Number',
              style: TextStyle(color: kGreen),
            ),
          ),
        ],
      ),
    );
  }
}
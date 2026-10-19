import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'auth_style.dart';
import 'otp_screen.dart';

class PhoneNumber extends StatefulWidget {
  const PhoneNumber({super.key});

  @override
  State<PhoneNumber> createState() => _PhoneNumberState();
}

class _PhoneNumberState extends State<PhoneNumber> {
  final phoneController = TextEditingController();
  bool isLoading = false;

  Future<void> sendOTP() async {
    String number = phoneController.text.trim();

    // accept 09..., 63..., +63...
    if (number.startsWith('0')) {
      number = number.substring(1);
    }

    if (number.startsWith('+63')) {
      number = number.substring(3);
    } else if (number.startsWith('63')) {
      number = number.substring(2);
    }

    if (!RegExp(r'^9\d{9}$').hasMatch(number)) {
      showAuthSnack(context, 'Enter a valid Philippine mobile number',
          error: true);
      return;
    }

    final phoneNumber = '+63$number';

    setState(() => isLoading = true);

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          await FirebaseAuth.instance.signInWithCredential(credential);
          if (!mounted) return;
          setState(() => isLoading = false);
          backToRoot(context);
        } on FirebaseAuthException catch (e) {
          if (!mounted) return;
          setState(() => isLoading = false);
          showAuthSnack(context, e.message ?? 'Verification failed',
              error: true);
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        if (!mounted) return;
        setState(() => isLoading = false);
        showAuthSnack(context, e.message ?? 'OTP request failed', error: true);
      },
      codeSent: (String verificationId, int? resendToken) {
        if (!mounted) return;
        setState(() => isLoading = false);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpScreen(
              verificationId: verificationId,
              phoneNumber: phoneNumber,
              resendToken: resendToken,
            ),
          ),
        );
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Phone Login',
      subtitle: "We'll text you a one-time code",
      icon: Icons.phone_android,
      card: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            decoration: authInput(
              'Mobile Number',
              Icons.phone_outlined,
              hint: '09171234567',
            ),
          ),
          const SizedBox(height: 22),
          AuthButton(label: 'Send OTP', loading: isLoading, onPressed: sendOTP),
        ],
      ),
    );
  }
}
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'design.dart';
import 'register.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;
  bool rememberMe = true;

  // LOGIN USING EMAIL AND PASSWORD
  Future<void> loginUser() async {
    final email = emailController.text.trim();
    final password = passController.text;

    if (email.isEmpty || password.isEmpty) {
      ccSnack(context, 'Please enter your email and password', error: true);
      return;
    }

    setState(() => isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;
      ccBackToRoot(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message;

      switch (e.code) {
        case 'invalid-email':
          message = 'Invalid email address';
          break;
        case 'invalid-credential':
        case 'wrong-password':
        case 'user-not-found':
          message = 'Incorrect email or password';
          break;
        case 'user-disabled':
          message = 'This account has been disabled';
          break;
        case 'too-many-requests':
          message = 'Too many attempts. Try again later.';
          break;
        case 'network-request-failed':
          message = 'Check your internet connection';
          break;
        default:
          message = e.message ?? 'Login failed';
      }

      ccSnack(context, message, error: true);
    } catch (_) {
      if (!mounted) return;
      ccSnack(context, 'Something went wrong. Please try again.', error: true);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // PASSWORD RESET
  Future<void> resetPassword() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      ccSnack(context, 'Please enter your email first', error: true);
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;
      ccSnack(
        context,
        'If an account exists, password reset instructions will be sent to your email.',
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ccSnack(context, e.message ?? 'Unable to send reset email', error: true);
    }
  }

  void openRegister() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const RegisterPage()),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CcFormScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CcBackLink(onTap: () => Navigator.maybePop(context)),
          const SizedBox(height: 16),
          const CcLogo(),
          const SizedBox(height: 32),
          const Text(
            'Welcome back.',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              height: 1.1,
              color: kInk,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Let's take care of you. Log in to your student account.",
            style: TextStyle(fontSize: 16, color: kSlate, height: 1.4),
          ),
          const SizedBox(height: 28),
          const CcLabel('Student Email'),
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            style: const TextStyle(fontSize: 16, color: kInk),
            decoration: ccInput('you@university.edu'),
          ),
          const SizedBox(height: 18),
          const CcLabel('Password'),
          TextField(
            controller: passController,
            obscureText: obscurePassword,
            style: const TextStyle(fontSize: 16, color: kInk),
            onSubmitted: (_) => loginUser(),
            decoration: ccInput(
              'Enter your password',
              suffix: ccEye(
                obscurePassword,
                    () => setState(() => obscurePassword = !obscurePassword),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: rememberMe,
                  activeColor: kTeal,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  onChanged: (v) => setState(() => rememberMe = v ?? true),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Remember me',
                style: TextStyle(fontSize: 15, color: kInk),
              ),
              const Spacer(),
              TextButton(
                onPressed: isLoading ? null : resetPassword,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Forgot password?',
                  style: TextStyle(
                    color: kTeal,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          CcButton(label: 'Log in', loading: isLoading, onPressed: loginUser),
          const SizedBox(height: 16),
          CcSwitchRow(
            prefix: 'New to CampusCare?',
            link: 'Create an account',
            onTap: isLoading ? null : openRegister,
          ),
        ],
      ),
    );
  }
}
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import 'design.dart';
import 'login.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passController = TextEditingController();
  final confirmController = TextEditingController();

  bool isLoading = false;
  bool hidePassword = true;
  bool hideConfirm = true;

  int _strength(String p) {
    var score = 0;
    if (p.length >= 8) score++;
    if (RegExp(r'[0-9]').hasMatch(p)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(p)) score++;
    if (RegExp(r'[a-z]').hasMatch(p) && RegExp(r'[A-Z]').hasMatch(p)) score++;
    return score;
  }

  Color _strengthColor(int score) {
    switch (score) {
      case 1:
        return const Color(0xFFEF4444);
      case 2:
        return const Color(0xFFF59E0B);
      case 3:
        return const Color(0xFF34A898);
      default:
        return kTeal;
    }
  }

  Widget _strengthBar() {
    final score = passController.text.isEmpty ? 0 : _strength(passController.text);
    return Row(
      children: List.generate(4, (i) {
        return Expanded(
          child: Container(
            height: 5,
            margin: EdgeInsets.only(right: i < 3 ? 8 : 0),
            decoration: BoxDecoration(
              color: i < score ? _strengthColor(score) : kBorder,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }

  Future<void> registerUser() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ccSnack(context, 'Please fill in all fields', error: true);
      return;
    }

    if (password.length < 8) {
      ccSnack(context, 'Password must be at least 8 characters', error: true);
      return;
    }

    if (password != confirmController.text) {
      ccSnack(context, "Passwords don't match", error: true);
      return;
    }

    setState(() => isLoading = true);

    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save the name so it shows up in the student's profile.
      final user = cred.user;
      if (user != null) {
        try {
          await user.updateDisplayName(name);
          await FirebaseDatabase.instance.ref('students/${user.uid}').update({
            'uid': user.uid,
            'name': name,
            'email': email,
          });
        } catch (_) {
          // Account is created either way; the name can be edited in Profile.
        }
      }

      if (!mounted) return;
      ccSnack(context, 'Account created!');
      ccBackToRoot(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message;

      switch (e.code) {
        case 'weak-password':
          message = 'Password is too weak';
          break;
        case 'email-already-in-use':
          message = 'Email is already registered';
          break;
        case 'invalid-email':
          message = 'Invalid email address';
          break;
        case 'network-request-failed':
          message = 'Check your internet connection';
          break;
        default:
          message = e.message ?? 'Registration failed';
      }

      ccSnack(context, message, error: true);
    } catch (_) {
      if (!mounted) return;
      ccSnack(context, 'Something went wrong', error: true);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void openLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passController.dispose();
    confirmController.dispose();
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
            'Join CampusCare',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              height: 1.1,
              color: kInk,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'A healthier student life starts here.',
            style: TextStyle(fontSize: 16, color: kSlate, height: 1.4),
          ),
          const SizedBox(height: 28),
          const CcLabel('Full Name'),
          TextField(
            controller: nameController,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            style: const TextStyle(fontSize: 16, color: kInk),
            decoration: ccInput('Your full name'),
          ),
          const SizedBox(height: 18),
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
            obscureText: hidePassword,
            style: const TextStyle(fontSize: 16, color: kInk),
            onChanged: (_) => setState(() {}),
            decoration: ccInput(
              'Enter your password',
              suffix: ccEye(
                hidePassword,
                    () => setState(() => hidePassword = !hidePassword),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _strengthBar(),
          const SizedBox(height: 8),
          const Text(
            'At least 8 characters. Add numbers and symbols for strength.',
            style: TextStyle(fontSize: 13, color: kSlate),
          ),
          const SizedBox(height: 18),
          const CcLabel('Confirm Password'),
          TextField(
            controller: confirmController,
            obscureText: hideConfirm,
            style: const TextStyle(fontSize: 16, color: kInk),
            onSubmitted: (_) => registerUser(),
            decoration: ccInput(
              'Re-enter your password',
              suffix: ccEye(
                hideConfirm,
                    () => setState(() => hideConfirm = !hideConfirm),
              ),
            ),
          ),
          const SizedBox(height: 24),
          CcButton(
            label: 'Create student account',
            loading: isLoading,
            onPressed: registerUser,
          ),
          const SizedBox(height: 16),
          CcSwitchRow(
            prefix: 'Already have an account?',
            link: 'Log in',
            onTap: isLoading ? null : openLogin,
          ),
        ],
      ),
    );
  }
}
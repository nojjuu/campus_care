
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
  String? nameError;
  String? emailError;
  String? passwordError;
  String? confirmError;

  // Password strength calculation
  int _strength(String password) {
    var score = 0;

    if (password.length >= 8) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) score++;
    if (RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'[A-Z]').hasMatch(password)) {
      score++;
    }

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
    final password = passController.text;
    final score = password.isEmpty ? 0 : _strength(password);

    return Row(
      children: List.generate(4, (index) {
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(
              right: index < 3 ? 7 : 0,
            ),
            decoration: BoxDecoration(
              color: index < score
                  ? _strengthColor(score)
                  : kBorder,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }

  // Firebase registration

  Future<void> registerUser() async {
    if (isLoading) return;

    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passController.text;
    final confirmation = confirmController.text;

    setState(() {
      nameError = name.isEmpty ? 'Full name is required' : null;

      if (email.isEmpty) {
        emailError = 'Student email is required';
      } else if (!RegExp(
        r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
      ).hasMatch(email)) {
        emailError = 'Enter a valid email address';
      } else {
        emailError = null;
      }

      if (password.isEmpty) {
        passwordError = 'Password is required';
      } else if (password.length < 8) {
        passwordError = 'Password must be at least 8 characters';
      } else {
        passwordError = null;
      }

      if (confirmation.isEmpty) {
        confirmError = 'Please confirm your password';
      } else if (confirmation != password) {
        confirmError = 'Passwords do not match';
      } else {
        confirmError = null;
      }
    });

    if (nameError != null ||
        emailError != null ||
        passwordError != null ||
        confirmError != null) {
      ccSnack(
        context,
        'Please check the highlighted fields',
        error: true,
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final credential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;

      if (user != null) {
        try {
          await user.updateDisplayName(name);

          await FirebaseDatabase.instance
              .ref('students/${user.uid}')
              .update({
            'uid': user.uid,
            'name': name,
            'email': email,
          });
        } catch (_) {
          // Account is created even if profile saving fails.
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
          setState(() => passwordError = message);
          break;

        case 'email-already-in-use':
          message = 'Email is already registered';
          setState(() => emailError = message);
          break;

        case 'invalid-email':
          message = 'Invalid email address';
          setState(() => emailError = message);
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
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void openLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),
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

  // Input styling for this screen only

  InputDecoration _fieldDecoration(
      String hint, {
        Widget? suffix,
        String? error,
      }) {
    OutlineInputBorder border(Color color, double width) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: BorderSide(
          color: color,
          width: width,
        ),
      );
    }

    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: kHint,
        fontSize: 13,
      ),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      errorText: error,
      errorStyle: const TextStyle(
        color: Color(0xFFEF4444),
        fontSize: 12,
      ),
      border: border(kBorder, 1),
      enabledBorder: border(kBorder, 1),
      focusedBorder: border(kTeal, 1.5),
      errorBorder: border(
        const Color(0xFFEF4444),
        1.5,
      ),
      focusedErrorBorder: border(
        const Color(0xFFEF4444),
        2,
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      26, 18, 26, 25,
                    ),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        // Back button
                        CcBackLink(
                          onTap: () =>
                              Navigator.maybePop(context),
                        ),

                        const SizedBox(height: 15),

                        // CampusCare logo
                        const CcLogo(size: 43),

                        const SizedBox(height: 30),

                        // Heading
                        const Text(
                          'Join CampusCare',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                            letterSpacing: -1.1,
                            color: kInk,
                          ),
                        ),

                        const SizedBox(height: 9),

                        const Text(
                          'A healthier student life starts here.',
                          style: TextStyle(
                            fontSize: 14,
                            color: kSlate,
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 26),

                        // Full Name
                        const CcLabel('Full Name'),

                        TextField(
                          controller: nameController,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          style: const TextStyle(
                            fontSize: 14,
                            color: kInk,
                          ),
                          onChanged: (_) {
                            if (nameError != null) {
                              setState(() {
                                nameError = null;
                              });
                            }
                          },
                          decoration: _fieldDecoration(
                            'Your full name',
                            error: nameError,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Student Email
                        const CcLabel('Student Email'),

                        TextField(
                          controller: emailController,
                          keyboardType:
                          TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          style: const TextStyle(
                            fontSize: 14,
                            color: kInk,
                          ),
                          onChanged: (_) {
                            if (emailError != null) {
                              setState(() => emailError = null);
                            }
                          },
                          decoration: _fieldDecoration(
                            'you@university.edu',
                            error: emailError,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Password
                        const CcLabel('Password'),

                        TextField(
                          controller: passController,
                          obscureText: hidePassword,
                          textInputAction: TextInputAction.next,
                          style: const TextStyle(
                            fontSize: 14,
                            color: kInk,
                          ),
                          onChanged: (_) {
                            setState(() {
                              passwordError = null;

                              if (confirmController.text.isNotEmpty) {
                                confirmError = null;
                              }
                            });
                          },
                          decoration: _fieldDecoration(
                            'Enter your password',
                            error: passwordError,
                            suffix: ccEye(
                              hidePassword,
                                  () => setState(() => hidePassword = !hidePassword),
                            ),
                          ),
                        ),

                        const SizedBox(height: 11),

                        // Password strength
                        _strengthBar(),

                        const SizedBox(height: 8),

                        const Text(
                          'At least 8 characters. Add numbers '
                              'and symbols for strength.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: kSlate,
                            height: 1.4,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Confirm Password
                        const CcLabel('Confirm Password'),

                        TextField(
                          controller: confirmController,
                          obscureText: hideConfirm,
                          textInputAction: TextInputAction.done,
                          style: const TextStyle(
                            fontSize: 14,
                            color: kInk,
                          ),
                          onSubmitted: (_) => registerUser(),
                          onChanged: (_) {
                            if (confirmError != null) {
                              setState(() => confirmError = null);
                            }
                          },
                          decoration: _fieldDecoration(
                            'Re-enter your password',
                            error: confirmError,
                            suffix: ccEye(
                              hideConfirm,
                                  () => setState(() => hideConfirm = !hideConfirm),
                            ),
                          ),
                        ),

                        const SizedBox(height: 22),

                        // Register button
                        SizedBox(
                          width: double.infinity,
                          child: CcButton(
                            label: 'Create student account',
                            loading: isLoading,
                            onPressed: registerUser,
                            color: kTeal,
                            height: 49,
                            radius: 9,
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Login navigation
                        CcSwitchRow(
                          prefix: 'Already have an account?',
                          link: 'Log in',
                          onTap: isLoading
                              ? null
                              : openLogin,
                        ),

                        const Spacer(),

                        const SizedBox(height: 24),

                        const CcFooterNote(
                          text:
                          'Your health information is private '
                              'and secure.',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

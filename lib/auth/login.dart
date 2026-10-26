

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

String? emailError;
String? passwordError;


Future<void> loginUser() async {
if (isLoading) return;

final email = emailController.text.trim();
final password = passController.text;

setState(() {
emailError = null;
passwordError = null;

if (email.isEmpty) {
emailError = 'Student email is required';
} else if (!RegExp(
r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
).hasMatch(email)) {
emailError = 'Enter a valid email address';
}

if (password.isEmpty) {
passwordError = 'Password is required';
}
});

if (emailError != null || passwordError != null) {
ccSnack(
context,
'Please check the highlighted fields',
error: true,
);
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
setState(() {
emailError = message;
});
break;

case 'invalid-credential':
case 'wrong-password':
case 'user-not-found':
message = 'Incorrect email or password';
setState(() {
emailError = 'Check your email or password';
passwordError = 'Check your email or password';
});
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

ccSnack(
context,
'Something went wrong. Please try again.',
error: true,
);

} finally {
if (mounted) {
setState(() => isLoading = false);
}
}
}


Future<void> resetPassword() async {
final email = emailController.text.trim();

if (email.isEmpty) {
ccSnack(
context,
'Please enter your email first',
error: true,
);
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
ccSnack(
context,
e.message ?? 'Unable to send reset email',
error: true,
);
}
}

void openRegister() {
Navigator.pushReplacement(
context,
MaterialPageRoute(
builder: (_) => const RegisterPage(),
),
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
return Scaffold(
backgroundColor: Colors.white,
body: SafeArea(
child: LayoutBuilder(
builder: (context, constraints) {
return SingleChildScrollView(
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
crossAxisAlignment: CrossAxisAlignment.start,
children: [
// Back navigation
CcBackLink(
onTap: () => Navigator.maybePop(context),
),

const SizedBox(height: 17),

// CampusCare logo
const CcLogo(size: 43),

const SizedBox(height: 37),

// Welcome heading
const Text(
'Welcome back.',
style: TextStyle(
fontSize: 30,
fontWeight: FontWeight.w800,
height: 1.1,
letterSpacing: -1.1,
color: kInk,
),
),

const SizedBox(height: 10),

const Text(
"Let's take care of you. Log in to your "
"student account.",
style: TextStyle(
fontSize: 14,
color: kSlate,
height: 1.5,
),
),

const SizedBox(height: 30),

// Student email
const CcLabel('Student Email'),


TextField(
controller: emailController,
keyboardType: TextInputType.emailAddress,
textInputAction: TextInputAction.next,
style: const TextStyle(
fontSize: 14,
color: kInk,
),
onChanged: (_) {
if (emailError != null) {
setState(() {
emailError = null;
});
}
},
decoration: _inputDecoration(
'you@university.edu',
error: emailError,
),
),

const SizedBox(height: 19),

// Password
const CcLabel('Password'),

TextField(
controller: passController,
obscureText: obscurePassword,
textInputAction: TextInputAction.done,
style: const TextStyle(
fontSize: 14,
color: kInk,
),
onChanged: (_) {
if (passwordError != null) {
setState(() {
passwordError = null;
});
}
},
onSubmitted: (_) => loginUser(),
decoration: _inputDecoration(
'Enter your password',
error: passwordError,
suffix: ccEye(
obscurePassword,
() {
setState(() {
obscurePassword = !obscurePassword;
});
},
),
),
),


const SizedBox(height: 17),

// Remember me and Forgot password
Row(
children: [
SizedBox(
width: 20,
height: 20,
child: Checkbox(
value: rememberMe,
activeColor: kTeal,
side: const BorderSide(
color: kBorder,
),
materialTapTargetSize:
MaterialTapTargetSize.shrinkWrap,
shape: RoundedRectangleBorder(
borderRadius:
BorderRadius.circular(4),
),
onChanged: (value) {
setState(() {
rememberMe = value ?? false;
});
},
),
),

const SizedBox(width: 8),

const Text(
'Remember me',
style: TextStyle(
fontSize: 13,
color: kSlate,
),
),

const Spacer(),

TextButton(
onPressed:
isLoading ? null : resetPassword,
style: TextButton.styleFrom(
padding: EdgeInsets.zero,
minimumSize: const Size(0, 32),
tapTargetSize:
MaterialTapTargetSize.shrinkWrap,
),
child: const Text(
'Forgot password?',
style: TextStyle(
fontSize: 13,
fontWeight: FontWeight.w600,
color: kTeal,
),
),
),
],
),

const SizedBox(height: 20),

// Login button
SizedBox(
width: double.infinity,
child: CcButton(
label: 'Log in',
loading: isLoading,
onPressed: loginUser,
color: kTeal,
height: 49,
radius: 9,
),
),

const SizedBox(height: 16),

// Registration navigation
CcSwitchRow(
prefix: 'New to CampusCare?',
link: 'Create an account',
onTap:
isLoading ? null : openRegister,
),

const Spacer(),

const SizedBox(height: 25),

// Footer
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


InputDecoration _inputDecoration(
String hint, {
Widget? suffix,
String? error,
}) {
OutlineInputBorder border(Color color, double width) {
return OutlineInputBorder(
borderRadius: BorderRadius.circular(8),
borderSide: BorderSide(
color: color,
width: width,
),
);
}

final hasError = error != null;

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
vertical: 15,
),

// Display field-specific validation errors.
errorText: error,
errorStyle: const TextStyle(
color: Color(0xFFEF4444),
fontSize: 12,
),

border: border(
hasError ? const Color(0xFFEF4444) : kBorder,
1,
),

enabledBorder: border(
hasError ? const Color(0xFFEF4444) : kBorder,
hasError ? 1.5 : 1,
),

focusedBorder: border(
hasError ? const Color(0xFFEF4444) : kTeal,
1.5,
),

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
}

import 'package:flutter/material.dart';

const kTeal = Color(0xFF00846F);
const kTealDark = Color(0xFF0E6F65);
const kInk = Color(0xFF0F172A);
const kSlate = Color(0xFF64748B);
const kBorder = Color(0xFFE2E8F0);
const kHint = Color(0xFF94A3B8);
const kRequired = Color(0xFFF43F5E);

void ccSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: error ? Colors.red : kTeal,
    ),
  );
}

/// After a successful sign-in, close the screens pushed on top of the root.
void ccBackToRoot(BuildContext context) {
  Navigator.of(context).popUntil((route) => route.isFirst);
}

InputDecoration ccInput(String hint, {Widget? suffix}) {
  OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: color, width: width),
  );

  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: kHint, fontSize: 16),
    suffixIcon: suffix,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: border(kBorder, 1),
    enabledBorder: border(kBorder, 1),
    focusedBorder: border(kTeal, 1.5),
  );
}

Widget ccEye(bool hidden, VoidCallback onTap) {
  return IconButton(
    icon: Icon(
      hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
      color: kSlate,
    ),
    onPressed: onTap,
  );
}

/// Teal rounded square with a plus, then "CampusCare" and the tagline.
class CcLogo extends StatelessWidget {
  final double size;
  final bool light;

  const CcLogo({super.key, this.size = 48, this.light = false});

  @override
  Widget build(BuildContext context) {
    final weight = light ? FontWeight.w400 : FontWeight.w800;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: light ? kTealDark : kTeal,
            borderRadius: BorderRadius.circular(size * 0.28),
          ),
          child: Icon(Icons.add, color: Colors.white, size: size * 0.6),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Campus',
                      style: TextStyle(color: kInk, fontWeight: weight),
                    ),
                    TextSpan(
                      text: 'Care',
                      style: TextStyle(color: kTeal, fontWeight: weight),
                    ),
                  ],
                ),
                style: TextStyle(fontSize: size * 0.5, height: 1.1),
              ),
              const SizedBox(height: 2),
              Text(
                'STUDENT HEALTH & WELLNESS',
                style: TextStyle(
                  fontSize: size * 0.2,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w600,
                  color: kSlate,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Field label with a red asterisk.
class CcLabel extends StatelessWidget {
  final String text;

  const CcLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: text),
            const TextSpan(text: ' *', style: TextStyle(color: kRequired)),
          ],
        ),
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: kInk,
        ),
      ),
    );
  }
}

class CcBackLink extends StatelessWidget {
  final VoidCallback onTap;

  const CcBackLink({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: onTap,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: const Size(0, 40),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        icon: const Icon(Icons.arrow_back, size: 18, color: kTeal),
        label: const Text(
          'Back to CampusCare',
          style: TextStyle(
            color: kTeal,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

class CcButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onPressed;
  final Color color;
  final double height;
  final double radius;

  const CcButton({
    super.key,
    required this.label,
    required this.loading,
    required this.onPressed,
    this.color = kTeal,
    this.height = 54,
    this.radius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: color,
        disabledBackgroundColor: color.withOpacity(0.6),
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: Size.fromHeight(height),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
      onPressed: loading ? null : onPressed,
      child: loading
          ? const SizedBox(
        height: 22,
        width: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: Colors.white,
        ),
      )
          : Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward, size: 20),
        ],
      ),
    );
  }
}

/// "New to CampusCare? Create an account" style line.
class CcSwitchRow extends StatelessWidget {
  final String prefix;
  final String link;
  final VoidCallback? onTap;

  const CcSwitchRow({
    super.key,
    required this.prefix,
    required this.link,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(prefix, style: const TextStyle(color: kSlate, fontSize: 15)),
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              link,
              style: const TextStyle(
                color: kTeal,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CcFooterNote extends StatelessWidget {
  final String text;

  const CcFooterNote({
    super.key,
    this.text = 'Your health information is private and secure.',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.shield_outlined, size: 18, color: kSlate),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: kSlate, height: 1.4),
          ),
        ),
      ],
    );
  }
}

/// White page with the footer note pinned to the bottom.
class CcFormScaffold extends StatelessWidget {
  final Widget child;

  const CcFormScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    child,
                    const Spacer(),
                    const SizedBox(height: 24),
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
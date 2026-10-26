import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CampusCareSettingsPage extends StatefulWidget {
  const CampusCareSettingsPage({super.key});

  @override
  State<CampusCareSettingsPage> createState() => _CampusCareSettingsPageState();
}

class _CampusCareSettingsPageState extends State<CampusCareSettingsPage> {
  static const teal = Color(0xFF00846F);
  static const ink = Color(0xFF0F172A);
  static const muted = Color(0xFF64748B);
  static const pageColor = Color(0xFFF7F9FA);
  static const borderColor = Color(0xFFE2E8F0);

  bool remindersEnabled = true;
  bool statusUpdatesEnabled = true;
  String reminderTiming = '1 hour';
  bool signingOut = false;

  void _message(String text, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: error ? Colors.red : teal),
    );
  }

  Future<void> _changePassword() async {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool busy = false;
    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, updateDialog) => AlertDialog(
            title: const Text('Change password'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: currentController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Current password'),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Enter your current password'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: newController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'New password'),
                    validator: (value) => value == null || value.length < 8
                        ? 'Use at least 8 characters'
                        : null,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: busy ? null : () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: busy
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        final user = FirebaseAuth.instance.currentUser;
                        final email = user?.email;
                        if (user == null || email == null) {
                          _message('No signed-in email account found', error: true);
                          return;
                        }
                        updateDialog(() => busy = true);
                        try {
                          final credential = EmailAuthProvider.credential(
                            email: email,
                            password: currentController.text,
                          );
                          await user.reauthenticateWithCredential(credential);
                          await user.updatePassword(newController.text);
                          if (!dialogContext.mounted) return;
                          Navigator.pop(dialogContext);
                          _message('Password updated successfully');
                        } on FirebaseAuthException catch (e) {
                          _message(e.message ?? 'Could not change password', error: true);
                        } catch (_) {
                          _message('Could not change password', error: true);
                        } finally {
                          if (dialogContext.mounted) updateDialog(() => busy = false);
                        }
                      },
                style: FilledButton.styleFrom(backgroundColor: teal),
                child: busy
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Update'),
              ),
            ],
          ),
        ),
      );
    } finally {
      currentController.dispose();
      newController.dispose();
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You can sign in again with your student account.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: teal),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => signingOut = true);
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      // AuthGate at the root reacts to the sign-out event.
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (_) {
      _message('Unable to log out. Please try again.', error: true);
    } finally {
      if (mounted) setState(() => signingOut = false);
    }
  }

  Future<void> _info(String title, String body) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: teal),
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: ink)),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }

  Widget _settingRow({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: teal, size: 23),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ink)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, height: 1.4, color: muted)),
      trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right, color: teal) : null),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text('Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const Text('A space that works for you.',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: ink)),
            const SizedBox(height: 6),
            const Text('Your preferences, privacy, and account.',
                style: TextStyle(fontSize: 13, color: muted)),
            const SizedBox(height: 22),
            _section('Notifications & Reminders', [
              _settingRow(
                icon: Icons.notifications_active_outlined,
                title: 'Appointment reminders',
                subtitle: 'Reminder preference (not connected to scheduling yet).',
                trailing: Switch(
                  value: remindersEnabled,
                  activeTrackColor: teal,
                  onChanged: (value) => setState(() => remindersEnabled = value),
                ),
              ),
              const Divider(),
              _settingRow(
                icon: Icons.schedule_outlined,
                title: 'Remind me',
                subtitle: 'Choose when you would like a reminder.',
                trailing: DropdownButton<String>(
                  value: reminderTiming,
                  underline: const SizedBox.shrink(),
                  items: ['30 minutes', '1 hour', '1 day']
                      .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                      .toList(),
                  onChanged: remindersEnabled
                      ? (value) {
                          if (value != null) setState(() => reminderTiming = value);
                        }
                      : null,
                ),
              ),
              const Divider(),
              _settingRow(
                icon: Icons.event_available_outlined,
                title: 'Status notifications',
                subtitle: 'Preference for appointment status updates.',
                trailing: Switch(
                  value: statusUpdatesEnabled,
                  activeTrackColor: teal,
                  onChanged: (value) => setState(() => statusUpdatesEnabled = value),
                ),
              ),
            ]),
            const SizedBox(height: 16),
            _section('Privacy & Security', [
              _settingRow(
                icon: Icons.lock_outline,
                title: 'Change password',
                subtitle: 'Update your Firebase email account password.',
                onTap: _changePassword,
              ),
              const Divider(),
              _settingRow(
                icon: Icons.shield_outlined,
                title: 'Privacy information',
                subtitle: 'How CampusCare handles student information.',
                onTap: () => _info(
                  'Privacy information',
                  'CampusCare uses Firebase Authentication for accounts and Firebase services for student records. '
                  'Only use sample health data until database security rules and access permissions have been reviewed. '
                  'This application is for student clinic appointment management, not medical diagnosis.',
                ),
              ),
              const Divider(),
              _settingRow(
                icon: Icons.camera_alt_outlined,
                title: 'Camera & gallery permissions',
                subtitle: 'Manage photo permissions in your device settings.',
                onTap: () => _info(
                  'Camera & gallery permissions',
                  'Open Android Settings → Apps → CampusCare → Permissions to review camera and photo access. '
                  'This page does not change device permissions automatically.',
                ),
              ),
            ]),
            const SizedBox(height: 16),
            _section('Application & Account', [
              _settingRow(
                icon: Icons.info_outline,
                title: 'About CampusCare',
                subtitle: 'Student Health and Appointment Management.',
                onTap: () => _info(
                  'About CampusCare',
                  'CampusCare is a student-side university project for managing student profiles, '
                  'health information, clinic appointments, and reminders.',
                ),
              ),
              const Divider(),
              _settingRow(
                icon: Icons.logout,
                title: signingOut ? 'Logging out...' : 'Log out',
                subtitle: 'Sign out of your student account.',
                onTap: signingOut ? null : _logout,
              ),
            ]),
            const SizedBox(height: 18),
            const Text(
              'Notification preferences are temporary in this prototype and are not yet connected to scheduled reminders.',
              textAlign: TextAlign.center,
              style: TextStyle(color: muted, fontSize: 11),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'health_logic.dart';

class HealthPage extends StatefulWidget {
  const HealthPage({super.key});

  @override
  State<HealthPage> createState() => _HealthPageState();
}

class _HealthPageState extends State<HealthPage> {
  static const green = Color(0xFF1B8A5A);
  static const greenDark = Color(0xFF146B47);
  static const mint = Color(0xFFF1F8F4);
  static const background = Color(0xFFF3F9F5);

  final _logic = HealthLogic();
  final _formKey = GlobalKey<FormState>();
  final _allergies = TextEditingController();
  final _conditions = TextEditingController();

  String? _bloodType;
  String _studentId = 'Loading...';
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _allergies.dispose();
    _conditions.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final id = await _logic.getStudentId();
      final h = await _logic.load();
      if (!mounted) return;

      _studentId = id;
      if (h != null) {
        _bloodType =
        HealthLogic.bloodTypes.contains(h.bloodType) ? h.bloodType : null;
        _allergies.text = h.allergies;
        _conditions.text = h.existingConditions;
      }
    } catch (_) {
      if (mounted) _message('Could not load health information', true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _message(String text, [bool error = false]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: error ? Colors.red : green,
      ),
    );
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      await _logic.save(
        bloodType: _bloodType!,
        allergies: _allergies.text,
        existingConditions: _conditions.text,
      );
      if (mounted) _message('Health information saved!');
    } catch (_) {
      if (mounted) _message('Failed to save health information', true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _decoration(String label, IconData icon, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: green),
      filled: true,
      fillColor: mint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: green, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text(
          'Health Information',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: green,
        foregroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: green))
          : !_logic.isLoggedIn
          ? const Center(
        child: Text('Please log in to view your health information.'),
      )
          : Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const Text(
              'Your Health Record',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: greenDark,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Keep these details up to date so the clinic can help you faster.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  TextFormField(
                    key: ValueKey(_studentId),
                    initialValue: _studentId,
                    readOnly: true,
                    decoration: _decoration(
                      'Student ID',
                      Icons.badge_outlined,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _bloodType,
                    decoration: _decoration(
                      'Blood Type',
                      Icons.water_drop_outlined,
                    ),
                    hint: const Text('Select your blood type'),
                    items: HealthLogic.bloodTypes
                        .map((b) => DropdownMenuItem(
                      value: b,
                      child: Text(b),
                    ))
                        .toList(),
                    onChanged: (v) => setState(() => _bloodType = v),
                    validator: (v) => v == null
                        ? 'Please select your blood type'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _allergies,
                    maxLines: 3,
                    decoration: _decoration(
                      'Allergies',
                      Icons.warning_amber_rounded,
                      hint: "e.g. Peanuts, Penicillin (or 'None')",
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? "Enter your allergies, or write 'None'"
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _conditions,
                    maxLines: 3,
                    decoration: _decoration(
                      'Existing Conditions',
                      Icons.medical_information_outlined,
                      hint: "e.g. Asthma (or 'None')",
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? "Enter your conditions, or write 'None'"
                        : null,
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Icon(Icons.save_outlined),
                      label: Text(
                        _saving ? 'Saving...' : 'Save Health Info',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lock_outline, size: 16, color: Colors.grey),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Your health information is private and only visible to you.',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
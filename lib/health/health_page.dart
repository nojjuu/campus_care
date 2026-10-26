import 'package:flutter/material.dart';
import 'health_logic.dart';
import '../main.dart' show CampusCareMenuButton, CampusCareNotificationButton;

class HealthPage extends StatefulWidget {
  final VoidCallback? onProfile;
  const HealthPage({super.key, this.onProfile});

  @override
  State<HealthPage> createState() => _HealthPageState();
}

class _HealthPageState extends State<HealthPage> {
  static const green = Color(0xFF1B8A5A);
  static const greenDark = Color(0xFF146B47);
  static const mint = Color(0xFFF1F8F4);
  static const background = Color(0xFFF3F9F5);
  bool _editing = false;

  final _logic = HealthLogic();
  final _formKey = GlobalKey<FormState>();
  final _allergies = TextEditingController();
  final _conditions = TextEditingController();

  String? _bloodType;
  String _studentId = 'Loading...';
  String _emergencyName = '';
  String _emergencyRelationship = '';
  String _emergencyNumber = '';
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
      final emergency = await _logic.getEmergencyDetails();
      if (!mounted) return;

      _studentId = id;
      _emergencyName = emergency['name'] ?? '';
      _emergencyRelationship = emergency['relationship'] ?? '';
      _emergencyNumber = emergency['number'] ?? '';
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
      if (mounted) {
        setState(() => _editing = false);
        _message('Health information saved!');
      }
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

  
Widget _infoCard({
  required IconData icon,
  required String label,
  required String value,
  Color iconColor = const Color(0xFF008F89),
}) {
  return Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 15,
    ),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: const Color(0xFFE5E8EB)),
    ),
    child: Row(
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(width: 17),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF697386),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF17243B),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _sectionTitle(String title) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10, top: 5),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Color(0xFF183B3B),
      ),
    ),
  );
}

Widget _contactDetail(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 13),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF697386),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF17243B),
          ),
        ),
      ],
    ),
  );
}


Widget _buildEditForm() {
  return Form(
    key: _formKey,
    autovalidateMode: AutovalidateMode.onUserInteraction,
    child: ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Edit health information',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF17243B),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                FocusScope.of(context).unfocus();
                setState(() => _editing = false);
              },
              child: const Text('Cancel'),
            ),
          ],
        ),
        const SizedBox(height: 20),

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
              .map(
                (b) => DropdownMenuItem(
                  value: b,
                  child: Text(b),
                ),
              )
              .toList(),
          onChanged: (value) {
            setState(() => _bloodType = value);
          },
          validator: (value) => value == null
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
            hint: "Enter allergies or 'None'",
          ),
          validator: (value) =>
              value == null || value.trim().isEmpty
                  ? "Enter allergies or 'None'"
                  : null,
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _conditions,
          maxLines: 3,
          decoration: _decoration(
            'Existing Conditions',
            Icons.medical_information_outlined,
            hint: "Enter conditions or 'None'",
          ),
          validator: (value) =>
              value == null || value.trim().isEmpty
                  ? "Enter conditions or 'None'"
                  : null,
        ),
        const SizedBox(height: 24),

        SizedBox(
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
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF008F89),
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    ),
  );
}

  
  @override
  Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFFFCFDFD),

    appBar: AppBar(
      leading: const CampusCareMenuButton(),
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF17243B),
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      title: const Row(
        children: [
          SizedBox(width: 12),
          Text(
            'Health',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      actions: [
        const CampusCareNotificationButton(),
        Padding(
          padding: const EdgeInsets.only(right: 14),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: widget.onProfile,
            child: CircleAvatar(
              radius: 15,
              backgroundColor: const Color(0xFFE7F5F3),
              child: const Icon(
                Icons.person_outline,
                size: 19,
                color: Color(0xFF008F89),
              ),
            ),
          ),
        ),
      ],
    ),

    body: _loading
        ? const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF008F89),
            ),
          )
        : !_logic.isLoggedIn
            ? const Center(
                child: Text(
                  'Please log in to view your health information.',
                ),
              )
            : _editing
                ? _buildEditForm()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(
                      14, 18, 14, 24,
                    ),
                    children: [
                      Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Expanded(
                            child: Text(
                              'Your health, in\none place.',
                              style: TextStyle(
                                fontSize: 22,
                                height: 1.12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                color: Color(0xFF17243B),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () {
                              setState(() => _editing = true);
                            },
                            icon: const Icon(
                              Icons.edit_outlined,
                              size: 13,
                            ),
                            label: const Text(
                              'Edit information',
                              style: TextStyle(fontSize: 10),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor:
                                  const Color(0xFF17243B),
                              side: const BorderSide(
                                color: Color(0xFFD9DEE5),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'The important details that help you\n'
                        'feel prepared for every visit.',
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.5,
                          color: Color(0xFF7A8495),
                        ),
                      ),

                      const SizedBox(height: 17),

                      _infoCard(
                        icon: Icons.water_drop_outlined,
                        label: 'Blood type',
                        value: _bloodType ?? 'Not provided',
                      ),

                      const SizedBox(height: 9),

                      _infoCard(
                        icon: Icons.health_and_safety_outlined,
                        label: 'Known allergies',
                        value: _allergies.text.trim().isEmpty
                            ? 'Not provided'
                            : _allergies.text.trim(),
                      ),

                      const SizedBox(height: 9),

                      _infoCard(
                        icon: Icons.favorite_border,
                        label: 'Existing medical conditions',
                        value: _conditions.text.trim().isEmpty
                            ? 'Not provided'
                            : _conditions.text.trim(),
                      ),

                      const SizedBox(height: 9),

                      Container(
                        padding: const EdgeInsets.fromLTRB(
                          15, 16, 15, 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(
                            color: const Color(0xFFE5E8EB),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.call_outlined,
                                  color: Color(0xFF008F89),
                                  size: 19,
                                ),
                                SizedBox(width: 9),
                                Text(
                                  'Emergency contact',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF183B3B),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 19),

                            // Replace these values with the
                            // actual saved emergency contact.
                            _contactDetail('Contact person',
                                _emergencyName.isEmpty ? 'Not provided' : _emergencyName),
                            _contactDetail('Relationship',
                                _emergencyRelationship.isEmpty ? 'Not provided' : _emergencyRelationship),
                            _contactDetail('Contact number',
                                _emergencyNumber.isEmpty ? 'Not provided' : _emergencyNumber),
                          ],
                        ),
                      ),
                    ],
                  ),
  );
}
}
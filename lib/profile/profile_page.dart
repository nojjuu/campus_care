import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'profile_logic.dart';

class StudentProfilePage extends StatefulWidget {
  const StudentProfilePage({super.key});

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
static const green = Color(0xFF1B8A5A);
static const greenDark = Color(0xFF146B47);
static const mint = Color(0xFFF1F8F4);
static const background = Color(0xFFF3F9F5);

final _logic = ProfileLogic();
final _formKey = GlobalKey<FormState>();

final _name = TextEditingController();
final _studentId = TextEditingController();
final _contact = TextEditingController();
final _emergency = TextEditingController();

String? _program;
bool _loading = true;
bool _saving = false;

@override
void initState() {
super.initState();
_loadProfile();
}

@override
void dispose() {
_name.dispose();
_studentId.dispose();
_contact.dispose();
_emergency.dispose();
super.dispose();
}

Future<void> _loadProfile() async {
try {
final p = await _logic.load();
if (!mounted) return;

if (p != null) {
_name.text = p.name;
_studentId.text = p.studentId;
_contact.text = p.contactNumber;
_emergency.text = p.emergencyContact;
_program = ['BSIT', 'BSIS', 'BLIS'].contains(p.program)
? p.program
: null;
}
} catch (_) {
if (mounted) _message('Could not load profile', true);
} finally {
if (mounted) setState(() => _loading = false);
}
}

void _message(String text, [bool error = false]) {
ScaffoldMessenger.of(context).showSnackBar(      SnackBar(
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
      name: _name.text.trim(),
      studentId: _studentId.text.trim(),
      program: _program!,
      contactNumber: _contact.text.trim(),
      emergencyContact: _emergency.text.trim(),
    );
    if (mounted) _message('Profile saved successfully!');
  } catch (_) {
    if (mounted) _message('Failed to save profile', true);
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

Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
      String? hint,
      TextInputType keyboard = TextInputType.text,
      int? maxLength,
      String? Function(String?)? validator,
    }) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      controller: controller,
      keyboardType: keyboard,
      maxLength: maxLength,
      inputFormatters:
      keyboard == TextInputType.phone || keyboard == TextInputType.number
          ? [
        FilteringTextInputFormatter.digitsOnly,
        if (maxLength != null)
          LengthLimitingTextInputFormatter(maxLength),
      ]
          : null,
      validator: validator ??
              (v) => v == null || v.trim().isEmpty ? '$label is required' : null,
      style: const TextStyle(
        color: Color(0xFF202124),
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: _decoration(label, icon, hint: hint),
    ),
  );
}

Widget _sectionTitle(String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: greenDark,
      ),
    ),
  );
}

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: background,
    appBar: AppBar(
      title: const Text(
        'Student Profile',
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
        ? const Center(child: Text('Please log in to view your profile.'))
        : Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text(
            'Your Profile',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
              color: greenDark,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Manage your student information.',
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('Personal Information'),
                _field(_name, 'Full Name', Icons.person_outline),
                _field(
                  _studentId,
                  'Student ID',
                  Icons.badge_outlined,
                  hint: 'e.g. 2024100755',
                  keyboard: TextInputType.number,
                  maxLength: 10,
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Student ID is required';
                    }
                    if (v.length != 10) {
                      return 'Student ID must be 10 digits';
                    }
                    return null;
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: DropdownButtonFormField<String>(
                    value: _program,
                    decoration: _decoration(
                      'Program / Course',
                      Icons.school_outlined,
                    ),
                    hint: const Text('Select your program'),
                    items: ['BSIT', 'BSIS', 'BLIS']
                        .map((p) => DropdownMenuItem(
                      value: p,
                      child: Text(p),
                    ))
                        .toList(),
                    onChanged: (v) => setState(() => _program = v),
                    validator: (v) => v == null
                        ? 'Please select your program'
                        : null,
                  ),
                ),
                const SizedBox(height: 6),
                _sectionTitle('Contact Information'),
                _field(
                  _contact,
                  'Contact Number',
                  Icons.phone_outlined,
                  keyboard: TextInputType.phone,
                  maxLength: 11,
                  validator: (v) =>
                      ProfileValidators.phone(v, 'contact number'),
                ),
                _field(
                  _emergency,
                  'Emergency Contact',
                  Icons.emergency_outlined,
                  keyboard: TextInputType.phone,
                  maxLength: 11,
                  validator: (v) => ProfileValidators.phone(
                    v,
                    'emergency contact number',
                  ),
                ),
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
                      _saving ? 'Saving...' : 'Save Profile',
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
        ],
      ),
    ),
  );
}
}
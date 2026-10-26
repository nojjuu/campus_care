import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'profile_logic.dart';
import '../main.dart' show CampusCareMenuButton, CampusCareNotificationButton;

class StudentProfilePage extends StatefulWidget {
  final VoidCallback? onHealth;
  final VoidCallback? onSetting;

  const StudentProfilePage({super.key, this.onHealth, this.onSetting});

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
static const green = Color(0xFF1B8A5A);
static const greenDark = Color(0xFF146B47);
static const mint = Color(0xFFF1F8F4);
static const background = Color(0xFFF3F9F5);
bool _editing = false;


final _logic = ProfileLogic();
final _formKey = GlobalKey<FormState>();

final _name = TextEditingController();
final _studentId = TextEditingController();
final _contact = TextEditingController();
final _emergency = TextEditingController();
final _emergencyName = TextEditingController();
final _emergencyRelationship = TextEditingController();

String? _program;
bool _loading = true;
bool _saving = false;
String _photoBase64 = '';
bool _photoBusy = false;


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
_emergencyName.dispose();
_emergencyRelationship.dispose();
super.dispose();
}


Future<void> _changePhoto(ImageSource source) async {
  if (_photoBusy) return;

  setState(() => _photoBusy = true);

  try {
    final photo = await _logic.pickAndSavePhoto(source);

    if (!mounted) return;

    if (photo != null) {
      setState(() => _photoBase64 = photo);
      _message('Profile picture updated successfully!');
    }
  } catch (e) {
    if (mounted) {
      _message('Failed to update profile picture: $e', true);
    }
  } finally {
    if (mounted) {
      setState(() => _photoBusy = false);
    }
  }
}

Future<void> _removePhoto() async {
  if (_photoBusy || _photoBase64.isEmpty) return;

  setState(() => _photoBusy = true);

  try {
    await _logic.removePhoto();

    if (!mounted) return;

    setState(() => _photoBase64 = '');
    _message('Profile picture removed.');
  } catch (e) {
    if (mounted) {
      _message('Failed to remove profile picture: $e', true);
    }
  } finally {
    if (mounted) {
      setState(() => _photoBusy = false);
    }
  }
}

void _showPhotoOptions() {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Wrap(
        children: [
          const ListTile(
            title: Text(
              'Profile Picture',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Choose how to update your photo'),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choose from gallery'),
            onTap: () {
              Navigator.pop(sheetContext);
              _changePhoto(ImageSource.gallery);
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined),
            title: const Text('Take a photo'),
            onTap: () {
              Navigator.pop(sheetContext);
              _changePhoto(ImageSource.camera);
            },
          ),
          if (_photoBase64.isNotEmpty)
            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: Colors.red,
              ),
              title: const Text(
                'Remove photo',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                _removePhoto();
              },
            ),
          const SizedBox(height: 12),
        ],
      ),
    ),
  );
}

Widget _profileAvatar({required double radius}) {
  final photoBytes = PhotoService.decode(_photoBase64);

  return Center(
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: const Color(0xFFDDF5EF),
          backgroundImage:
              photoBytes != null ? MemoryImage(photoBytes) : null,
          child: photoBytes == null
              ? Icon(
                  Icons.person_outline,
                  size: radius * 1.05,
                  color: const Color(0xFF008F89),
                )
              : null,
        ),
        Positioned(
          right: -3,
          bottom: -3,
          child: Material(
            color: green,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: _photoBusy ? null : _showPhotoOptions,
              customBorder: const CircleBorder(),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: _photoBusy
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.camera_alt,
                        size: 14,
                        color: Colors.white,
                      ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
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
_emergencyName.text = p.emergencyName;
_emergencyRelationship.text = p.emergencyRelationship;
_photoBase64 = p.photoBase64;
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
      emergencyName: _emergencyName.text.trim(),
      emergencyRelationship: _emergencyRelationship.text.trim(),
    );
    if (mounted) {
      setState(() => _editing = false);
      _message('Profile saved successfully!');
    }
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


Widget _profileDetail(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF8A9AB2),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value.isEmpty ? 'Not provided' : value,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF26364D),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

Widget _profileCard({
  required Widget child,
}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: const Color(0xFFEAF0F5),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.025),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: child,
  );
}

Widget _cardHeading(String title) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Color(0xFF17243B),
      ),
    ),
  );
}

Widget _accountRow(
  IconData icon,
  String title,
  VoidCallback onTap,
) {
  return InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: const Color(0xFF009C91),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF26364D),
              ),
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: Color(0xFF009C91),
            size: 22,
          ),
        ],
      ),
    ),
  );
}


Widget _buildProfileView() {
  final displayName = _name.text.trim().isEmpty
      ? 'Student'
      : _name.text.trim();

  final program = _program ?? 'Program not provided';

  return ListView(
    padding: const EdgeInsets.fromLTRB(14, 20, 14, 24),
    children: [
      // Heading and edit button
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My profile',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: Color(0xFF17243B),
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'Your student identity, with a personal touch.',
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.5,
                    color: Color(0xFF71819A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () {
              setState(() => _editing = true);
            },
            icon: const Icon(
              Icons.edit_outlined,
              size: 14,
            ),
            label: const Text(
              'Edit Profile',
              style: TextStyle(fontSize: 10),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF17243B),
              side: const BorderSide(
                color: Color(0xFFE0E7EF),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 10,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),

      const SizedBox(height: 18),

      // Student identity card
      _profileCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _profileAvatar(radius: 28),
            const SizedBox(height: 19),
            Text(
              displayName,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: Color(0xFF17243B),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              '${_studentId.text.trim()} · $program',
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF71819A),
              ),
            ),
            const SizedBox(height: 13),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFDDF5EF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_user_outlined,
                      size: 13,
                      color: Color(0xFF008F89),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'CampusCare student',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF087F75),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      const SizedBox(height: 15),

      // Personal information
      _profileCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cardHeading('Personal information'),
            _profileDetail(
              'Full name',
              _name.text.trim(),
            ),
            _profileDetail(
              'Student ID',
              _studentId.text.trim(),
            ),
            _profileDetail(
              'Program / Course',
              program,
            ),
            _profileDetail(
              'Contact number',
              _contact.text.trim(),
            ),
          ],
        ),
      ),

      const SizedBox(height: 15),

      // Emergency contact
      _profileCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cardHeading('Emergency contact'),
            _profileDetail('Contact person', _emergencyName.text.trim()),
            _profileDetail('Relationship', _emergencyRelationship.text.trim()),
            _profileDetail('Emergency contact number', _emergency.text.trim()),
          ],
        ),
      ),

      const SizedBox(height: 15),

      // Account menu
      _profileCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cardHeading('Your account'),

            _accountRow(
              Icons.person_outline,
              'Edit personal information',
              () => setState(() => _editing = true),
            ),

            const Divider(
              height: 1,
              color: Color(0xFFF0F3F7),
            ),

            _accountRow(
              Icons.favorite_border,
              'Manage health information',
                  () => widget.onHealth?.call(),
            ),

            const Divider(
              height: 1,
              color: Color(0xFFF0F3F7),
            ),

            const Divider(
              height: 1,
              color: Color(0xFFF0F3F7),
            ),

            _accountRow(
              Icons.settings_outlined,
              'Settings',
              () => widget.onSetting?.call(),
            ),

            const SizedBox(height: 20),

            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  size: 17,
                  color: Color(0xFF009C91),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Your health information is private and '
                    'saved only on this device for this prototype. '
                    'Keep your information accurate. CampusCare '
                    'does not replace professional medical advice.',
                    style: TextStyle(
                      fontSize: 10,
                      height: 1.6,
                      color: Color(0xFF71819A),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ],
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
                'Edit Personal Information',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: greenDark,
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

        const SizedBox(height: 5),

        const Text(
          'Update your student and contact details below.',
          style: TextStyle(color: Colors.black54),
        ),

        const SizedBox(height: 20),

        // Personal Information
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

              _field(
                _name,
                'Full Name',
                Icons.person_outline,
              ),

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
                      .map(
                        (p) => DropdownMenuItem(
                          value: p,
                          child: Text(p),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    setState(() => _program = v);
                  },
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
                    ProfileValidators.phone(
                  v,
                  'contact number',
                ),
              ),

              _field(
                _emergency,
                'Emergency Contact Number',
                Icons.emergency_outlined,
                keyboard: TextInputType.phone,
                maxLength: 11,
                validator: (v) =>
                    ProfileValidators.phone(
                  v,
                  'emergency contact number',
                ),
              ),

              _field(
                _emergencyName,
                'Emergency Contact Person',
                Icons.person_outline,
              ),

              _field(
                _emergencyRelationship,
                'Relationship',
                Icons.family_restroom_outlined,
                hint: 'e.g. Mother, Father, Guardian',
              ),

              const SizedBox(height: 8),

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
                    _saving
                        ? 'Saving...'
                        : 'Save Profile',
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
  );
}



@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFFF7F9FC),

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
            'Profile',
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
          padding: const EdgeInsets.only(right: 15),
          child: Container(
            width: 29,
            height: 29,
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color(0xFF71819A),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: PhotoService.decode(_photoBase64) == null
                  ? const Icon(
                Icons.person_outline,
                size: 19,
                color: Color(0xFF008F89),
              )
                  : Image.memory(
                PhotoService.decode(_photoBase64)!,
                width: 29,
                height: 29,
                fit: BoxFit.cover,
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
                  'Please log in to view your profile.',
                ),
              )
            : _editing
                ? _buildEditForm()
                : _buildProfileView(),
  );
}

}
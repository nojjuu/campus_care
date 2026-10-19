import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class StudentProfile {
  final String uid;
  final String name;
  final String studentId;
  final String program;
  final String contactNumber;
  final String emergencyContact;

  const StudentProfile({
    required this.uid,
    required this.name,
    required this.studentId,
    required this.program,
    required this.contactNumber,
    required this.emergencyContact,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'studentId': studentId,
      'program': program,
      'contactNumber': contactNumber,
      'emergencyContact': emergencyContact,
      'updatedAt': ServerValue.timestamp,
    };
  }

  factory StudentProfile.fromMap(Map<dynamic, dynamic> map) {
    return StudentProfile(
      uid: map['uid']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      studentId: map['studentId']?.toString() ?? '',
      program: map['program']?.toString() ?? '',
      contactNumber: map['contactNumber']?.toString() ?? '',
      emergencyContact: map['emergencyContact']?.toString() ?? '',
    );
  }
}

/// Profile path (Realtime Database): students/{uid}
class ProfileService {
  DatabaseReference _ref(String uid) =>
      FirebaseDatabase.instance.ref('students/$uid');

  Future<StudentProfile?> getProfile(String uid) async {
    final snapshot = await _ref(uid).get();
    final data = snapshot.value;
    if (data == null) return null;
    return StudentProfile.fromMap(Map<dynamic, dynamic>.from(data as Map));
  }

  Future<void> saveProfile(StudentProfile profile) {
    return _ref(profile.uid).update(profile.toMap());
  }
}

class ProfileValidators {
  static String? required(String? value, String message) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  static String? phone(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your $label';
    }
    if (!RegExp(r'^[0-9]{11}$').hasMatch(value.trim())) {
      return '$label must be exactly 11 digits';
    }
    return null;
  }
}

class ProfileLogic {
  final ProfileService _service = ProfileService();

  String? get uid => FirebaseAuth.instance.currentUser?.uid;

  bool get isLoggedIn => uid != null;

  Future<StudentProfile?> load() async {
    final id = uid;
    if (id == null) return null;
    return _service.getProfile(id);
  }

  Future<void> save({
    required String name,
    required String studentId,
    required String program,
    required String contactNumber,
    required String emergencyContact,
  }) async {
    final id = uid;
    if (id == null) {
      throw StateError('No logged-in user.');
    }

    await _service.saveProfile(
      StudentProfile(
        uid: id,
        name: name.trim(),
        studentId: studentId.trim(),
        program: program.trim(),
        contactNumber: contactNumber.trim(),
        emergencyContact: emergencyContact.trim(),
      ),
    );
  }
}
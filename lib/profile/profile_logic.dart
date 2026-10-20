import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';

class StudentProfile {
  final String uid;
  final String name;
  final String studentId;
  final String program;
  final String contactNumber;
  final String emergencyContact;
  final String photoBase64;

  const StudentProfile({
    required this.uid,
    required this.name,
    required this.studentId,
    required this.program,
    required this.contactNumber,
    required this.emergencyContact,
    this.photoBase64 = '',
  });

  /// photoBase64 is intentionally NOT included here, so saving the form
  /// never touches the photo. The photo is saved separately via savePhoto().
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
      photoBase64: map['photoBase64']?.toString() ?? '',
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

  Future<void> savePhoto(String uid, String photoBase64) {
    return _ref(uid).update({
      'photoBase64': photoBase64,
      'updatedAt': ServerValue.timestamp,
    });
  }
}

class PhotoService {
  final ImagePicker _picker = ImagePicker();

  /// Picks an image, shrinks it (max 512x512, quality 60) and returns base64.
  Future<String?> pickAsBase64(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 60,
    );
    if (picked == null) return null;

    final Uint8List bytes = await picked.readAsBytes();
    return base64Encode(bytes);
  }

  static Uint8List? decode(String base64String) {
    if (base64String.isEmpty) return null;
    try {
      return base64Decode(base64String);
    } catch (_) {
      return null;
    }
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
  final PhotoService _photos = PhotoService();

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

  /// Returns the new base64 photo, or null if the user cancelled.
  Future<String?> pickAndSavePhoto(ImageSource source) async {
    final id = uid;
    if (id == null) {
      throw StateError('No logged-in user.');
    }

    final photo = await _photos.pickAsBase64(source);
    if (photo == null) return null;

    await _service.savePhoto(id, photo);
    return photo;
  }

  Future<void> removePhoto() async {
    final id = uid;
    if (id == null) {
      throw StateError('No logged-in user.');
    }
    await _service.savePhoto(id, '');
  }
}
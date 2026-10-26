import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class HealthInfo {
  final String uid;
  final String studentId;
  final String bloodType;
  final String allergies;
  final String existingConditions;

  const HealthInfo({
    required this.uid,
    required this.studentId,
    required this.bloodType,
    required this.allergies,
    required this.existingConditions,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'studentId': studentId,
      'bloodType': bloodType,
      'allergies': allergies,
      'existingConditions': existingConditions,
      'updatedAt': ServerValue.timestamp,
    };
  }

  factory HealthInfo.fromMap(Map<dynamic, dynamic> map) {
    return HealthInfo(
      uid: map['uid']?.toString() ?? '',
      studentId: map['studentId']?.toString() ?? '',
      bloodType: map['bloodType']?.toString() ?? '',
      allergies: map['allergies']?.toString() ?? '',
      existingConditions: map['existingConditions']?.toString() ?? '',
    );
  }
}

/// Health path (Realtime Database): health/{uid}
class HealthService {
  DatabaseReference _ref(String uid) =>
      FirebaseDatabase.instance.ref('health/$uid');

  Future<HealthInfo?> get(String uid) async {
    final snapshot = await _ref(uid).get();
    final data = snapshot.value;
    if (data == null) return null;
    return HealthInfo.fromMap(Map<dynamic, dynamic>.from(data as Map));
  }

  Future<void> save(HealthInfo info) {
    return _ref(info.uid).update(info.toMap());
  }
}

class HealthLogic {
  static const bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  final HealthService _service = HealthService();

  String? get uid => FirebaseAuth.instance.currentUser?.uid;

  bool get isLoggedIn => uid != null;

  /// Student ID from the profile (students/{uid}/studentId).
  /// Falls back to the login uid if the profile has no Student ID yet.
  Future<String> getStudentId() async {
    final id = uid;
    if (id == null) return '';
    try {
      final snap =
      await FirebaseDatabase.instance.ref('students/$id/studentId').get();
      if (snap.exists && snap.value != null) return snap.value.toString();
    } catch (_) {}
    return id;
  }

  Future<Map<String, String>> getEmergencyDetails() async {
    final id = uid;
    final empty = {'name': '', 'relationship': '', 'number': ''};
    if (id == null) return empty;
    try {
      final snap = await FirebaseDatabase.instance.ref('students/$id').get();
      if (snap.exists && snap.value is Map) {
        final m = Map<dynamic, dynamic>.from(snap.value as Map);
        return {
          'name': m['emergencyName']?.toString() ?? '',
          'relationship': m['emergencyRelationship']?.toString() ?? '',
          'number': m['emergencyContact']?.toString() ?? '',
        };
      }
    } catch (_) {}
    return empty;
  }

  Future<HealthInfo?> load() async {
    final id = uid;
    if (id == null) return null;
    return _service.get(id);
  }

  Future<void> save({
    required String bloodType,
    required String allergies,
    required String existingConditions,
  }) async {
    final id = uid;
    if (id == null) {
      throw StateError('No logged-in user.');
    }

    await _service.save(
      HealthInfo(
        uid: id,
        studentId: await getStudentId(),
        bloodType: bloodType,
        allergies: allergies.trim(),
        existingConditions: existingConditions.trim(),
      ),
    );
  }
}
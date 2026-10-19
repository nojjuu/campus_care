import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'appointment_model.dart';
import 'notification_service.dart';

/// Appointments: appointments/{uid}/{appointmentId}
/// Student ID is read from the profile: students/{uid}/studentId
class AppointmentService {
  String get uid => FirebaseAuth.instance.currentUser!.uid;
  DatabaseReference get _ref =>
      FirebaseDatabase.instance.ref('appointments/$uid');

  /// Reads the Student ID from the student's profile.
  /// Falls back to the login uid if the profile has no Student ID yet.
  Future<String> getStudentId() async {
    try {
      final snap = await FirebaseDatabase.instance
          .ref('students/$uid/studentId')
          .get();
      if (snap.exists && snap.value != null) return snap.value.toString();
    } catch (_) {}
    return uid;
  }

  /// Live list of ALL appointments of the logged-in student.
  Stream<List<Appointment>> stream() => _ref.onValue.map((event) {
    final v = event.snapshot.value;
    if (v == null) return <Appointment>[];
    final map = Map<dynamic, dynamic>.from(v as Map);
    final list = map.entries
        .map((e) => Appointment.fromMap(
        e.key as String, Map<dynamic, dynamic>.from(e.value as Map)))
        .toList();
    list.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return list;
  });

  Future<void> add(Appointment a) async {
    final r = _ref.push();
    await r.set(a.toMap());
    await NotificationService.scheduleReminder(r.key!, a.dateTime, a.reason);
  }

  Future<void> update(Appointment a) async {
    await _ref.child(a.id).update(a.toMap());
    await NotificationService.cancelReminder(a.id);
    if (a.isActive) {
      await NotificationService.scheduleReminder(a.id, a.dateTime, a.reason);
    }
  }

  /// Used for manual status simulation (Pending/Approved/Completed/Cancelled).
  Future<void> setStatus(Appointment a, String status) async {
    await _ref.child(a.id).update({'status': status});
    if (status == Appointment.completed || status == Appointment.cancelled) {
      await NotificationService.cancelReminder(a.id);
    }
  }

  Future<void> cancel(Appointment a) => setStatus(a, Appointment.cancelled);
}
class Appointment {
  static const pending = 'Pending';
  static const approved = 'Approved';
  static const completed = 'Completed';
  static const cancelled = 'Cancelled';

  final String id;
  final String studentId; // Firebase Auth uid, links appointment to the student
  final DateTime dateTime; // date + time combined
  final String reason;
  final String notes;
  final String status;

  Appointment({
    this.id = '',
    required this.studentId,
    required this.dateTime,
    required this.reason,
    this.notes = '',
    this.status = pending,
  });

  bool get isActive => status == pending || status == approved;

  Map<String, dynamic> toMap() => {
        'studentId': studentId,
        'dateTime': dateTime.millisecondsSinceEpoch,
        'reason': reason,
        'notes': notes,
        'status': status,
      };

  factory Appointment.fromMap(String id, Map<dynamic, dynamic> m) => Appointment(
        id: id,
        studentId: m['studentId'] ?? '',
        dateTime: DateTime.fromMillisecondsSinceEpoch(m['dateTime'] ?? 0),
        reason: m['reason'] ?? '',
        notes: m['notes'] ?? '',
        status: m['status'] ?? pending,
      );
}

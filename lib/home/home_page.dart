import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../appointments/appointment_model.dart';
import '../appointments/appointment_service.dart';
import '../profile/profile_logic.dart';
import '../main.dart' show CampusCareMenuButton;

class HomePage extends StatefulWidget {
  final VoidCallback onAppointments;
  final VoidCallback onBook;
  final VoidCallback onHealth;
  final VoidCallback onProfile;
  final VoidCallback onAccount;

  const HomePage({
    super.key,
    required this.onAppointments,
    required this.onBook,
    required this.onHealth,
    required this.onProfile,
    required this.onAccount,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const Color teal = Color(0xFF00846F);
  static const Color darkTeal = Color(0xFF0E6F65);
  static const Color ink = Color(0xFF173532);
  static const Color muted = Color(0xFF6C817C);
  static const Color background = Color(0xFFF5FAF7);

  final ProfileLogic _profileLogic = ProfileLogic();
  final AppointmentService _appointments = AppointmentService();
  late Future<StudentProfile?> _profileFuture;
  late Stream<List<Appointment>> _appointmentStream;

  @override
  void initState() {
    super.initState();
    _profileFuture = _profileLogic.load();
    _appointmentStream = _appointments.stream();
  }

  Future<void> _refresh() async {
    setState(() {
      _profileFuture = _profileLogic.load();
    });
    await _profileFuture;
  }

  String _firstName(StudentProfile? profile) {
    final name = (profile?.name.isNotEmpty == true
            ? profile!.name
            : FirebaseAuth.instance.currentUser?.displayName ?? '')
        .trim();
    return name.isEmpty ? 'Student' : name.split(RegExp(r'\s+')).first;
  }

  String _statusText(String status) => status;

  Color _statusColor(String status) {
    switch (status) {
      case Appointment.approved:
        return const Color(0xFF2563EB);
      case Appointment.completed:
        return const Color(0xFF15803D);
      case Appointment.cancelled:
        return const Color(0xFF64748B);
      default:
        return const Color(0xFFB7791F);
    }
  }

  Widget _card({required Widget child, EdgeInsets? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFFE5F0EA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A183D31),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _heading(String title, {VoidCallback? onViewAll}) {
    return Row(
      children: [
        Expanded(
          child: Text(title,
              style: const TextStyle(
                  color: ink, fontSize: 18, fontWeight: FontWeight.w800)),
        ),
        if (onViewAll != null)
          TextButton(
            onPressed: onViewAll,
            child: const Text('View all', style: TextStyle(color: teal)),
          ),
      ],
    );
  }

  Widget _quickAction(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE3EFE9)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5F5EF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: teal, size: 24),
              ),
              const SizedBox(height: 9),
              Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: ink,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileSummary(StudentProfile? profile) {
    final completed = [
      profile?.name ?? '',
      profile?.studentId ?? '',
      profile?.program ?? '',
      profile?.contactNumber ?? '',
      profile?.emergencyContact ?? '',
    ].where((s) => s.trim().isNotEmpty).length;
    final progress = completed / 5;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.person_outline, color: teal),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Your Student Profile',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: ink,
                  )),
            ),
            TextButton(onPressed: widget.onProfile, child: const Text('Edit')),
          ]),
          const SizedBox(height: 8),
          Text(profile?.name.isNotEmpty == true ? profile!.name : 'Not provided',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            'Student ID: ${profile?.studentId.isNotEmpty == true ? profile!.studentId : 'Not added'}',
            style: const TextStyle(color: muted, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            'Program: ${profile?.program.isNotEmpty == true ? profile!.program : 'Not added'}',
            style: const TextStyle(color: muted, fontSize: 13),
          ),
          const SizedBox(height: 14),
          Row(children: [
            const Expanded(child: Text('Profile completion',
                style: TextStyle(color: muted, fontSize: 12))),
            Text('${(progress * 100).round()}%',
                style: const TextStyle(color: teal, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: const Color(0xFFE3EEE8),
              color: teal,
            ),
          ),
          const SizedBox(height: 8),
          const Text('Based on your five basic student profile fields.',
              style: TextStyle(fontSize: 11, color: muted)),
        ],
      ),
    );
  }

  Widget _appointmentsSection() {
    return StreamBuilder<List<Appointment>>(
      stream: _appointmentStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _card(child: const Text('Unable to load appointments. Please try again later.'));
        }
        if (!snapshot.hasData) {
          return _card(child: const Center(child: Padding(
            padding: EdgeInsets.all(12),
            child: CircularProgressIndicator(color: teal),
          )));
        }

        final all = snapshot.data!;
        final now = DateTime.now();
        final upcoming = all.where((a) =>
            a.isActive && !a.dateTime.isBefore(now)).toList()
          ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
        final recent = [...all]..sort((a, b) => b.dateTime.compareTo(a.dateTime));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _heading('Upcoming Appointment', onViewAll: widget.onAppointments),
            const SizedBox(height: 8),
            if (upcoming.isEmpty)
              _card(
                child: Column(
                  children: [
                    const Icon(Icons.event_available_outlined, color: teal, size: 38),
                    const SizedBox(height: 10),
                    const Text('No upcoming appointments',
                        style: TextStyle(fontWeight: FontWeight.w700, color: ink)),
                    const SizedBox(height: 6),
                    const Text('Book a clinic visit whenever you need one.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: muted, fontSize: 13)),
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: widget.onBook,
                      icon: const Icon(Icons.add),
                      label: const Text('Book appointment'),
                    ),
                  ],
                ),
              )
            else
              _appointmentCard(upcoming.first),
            const SizedBox(height: 22),
            _heading('Recent Activity', onViewAll: widget.onAppointments),
            const SizedBox(height: 8),
            if (recent.isEmpty)
              _card(child: const Text('Your appointment activity will appear here.',
                  style: TextStyle(color: muted)))
            else
              _card(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Column(
                  children: recent.take(3).map((appointment) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFE5F5EF),
                        child: const Icon(Icons.event_note_outlined, color: teal),
                      ),
                      title: Text(appointment.reason,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      subtitle: Text(DateFormat('MMM d, yyyy • h:mm a').format(appointment.dateTime),
                          style: const TextStyle(fontSize: 11, color: muted)),
                      trailing: Text(_statusText(appointment.status),
                          style: TextStyle(fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _statusColor(appointment.status))),
                      onTap: widget.onAppointments,
                    );
                  }).toList(),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _appointmentCard(Appointment appointment) {
    final statusColor = _statusColor(appointment.status);
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.calendar_month_outlined, color: teal),
            const SizedBox(width: 8),
            Expanded(child: Text(appointment.reason,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800, color: ink))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(appointment.status,
                  style: TextStyle(fontSize: 11, color: statusColor,
                      fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 12),
          Text(DateFormat('EEEE, MMMM d, yyyy').format(appointment.dateTime),
              style: const TextStyle(color: muted, fontSize: 13)),
          const SizedBox(height: 4),
          Text(DateFormat('h:mm a').format(appointment.dateTime),
              style: const TextStyle(color: muted, fontSize: 13)),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: widget.onAppointments,
              icon: const Icon(Icons.arrow_forward, size: 17),
              label: const Text('Manage appointment'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: teal,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(19, 18, 19, 28),
            children: [
              FutureBuilder<StudentProfile?>(
                future: _profileFuture,
                builder: (context, snapshot) {
                  final profile = snapshot.data;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          width: 39,
                          height: 39,
                          decoration: BoxDecoration(
                            color: teal,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 29),
                        ),
                        const SizedBox(width: 9),
                        const Expanded(
                          child: Text('CampusCare',
                              style: TextStyle(color: ink,
                                  fontSize: 19, fontWeight: FontWeight.w800)),
                        ),
                        const CampusCareMenuButton(),
                      
                      ]),
                      const SizedBox(height: 22),
                      Text('Hello, ${_firstName(profile)}!',
                          style: const TextStyle(fontSize: 25,
                              fontWeight: FontWeight.w800, color: ink)),
                      const SizedBox(height: 5),
                      Text(DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
                          style: const TextStyle(color: muted, fontSize: 13)),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(21),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [teal, darkTeal]),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Row(children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Your health matters.',
                                    style: TextStyle(color: Colors.white,
                                        fontSize: 20, fontWeight: FontWeight.w800)),
                                SizedBox(height: 7),
                                Text('Manage your clinic visits and student profile in one place.',
                                    style: TextStyle(color: Color(0xFFE3F4EC),
                                        fontSize: 12, height: 1.5)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.favorite_outline,
                              size: 60, color: Color(0xBFFFFFFF)),
                        ]),
                      ),
                      const SizedBox(height: 23),
                      _heading('Health & Profile Overview'),
                      const SizedBox(height: 8),
                      if (snapshot.hasError)
                        _card(child: const Text('Unable to load your profile.'))
                      else if (snapshot.connectionState == ConnectionState.waiting)
                        _card(child: const Center(child: CircularProgressIndicator(color: teal)))
                      else
                        _profileSummary(profile),
                    ],
                  );
                },
              ),
              const SizedBox(height: 22),
              _heading('Quick Actions'),
              const SizedBox(height: 9),
              Row(children: [
                _quickAction(Icons.add_circle_outline, 'Book Visit', widget.onBook),
                const SizedBox(width: 8),
                _quickAction(Icons.calendar_month_outlined, 'Appointments', widget.onAppointments),
                const SizedBox(width: 8),
                _quickAction(Icons.favorite_border, 'Health Info', widget.onHealth),
                const SizedBox(width: 8),
                _quickAction(Icons.person_outline, 'My Profile', widget.onProfile),
              ]),
              const SizedBox(height: 22),
              _appointmentsSection(),
            ],
          ),
        ),
      ),
    );
  }
}

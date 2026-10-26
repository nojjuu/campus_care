import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../main.dart';
import 'appointment_form_screen.dart';
import 'appointment_model.dart';
import 'appointment_service.dart';

/// Student-facing appointment list, styled to match the CampusCare Figma.
/// Firebase reads/writes still go through the existing AppointmentService.
class AppointmentsScreen extends StatefulWidget {
  final VoidCallback? onProfile;
  const AppointmentsScreen({super.key, this.onProfile});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  static const teal = Color(0xFF00846F);
  static const ink = Color(0xFF142538);
  static const muted = Color(0xFF718096);
  static const bg = Color(0xFFF7FAFC);
  static const border = Color(0xFFE5EBF0);

  final AppointmentService _service = AppointmentService();
  late final Stream<List<Appointment>> _stream = _service.stream();
  int _filter = 0; // All, Upcoming, History, Cancelled
  bool _newestFirst = true;

  void _book() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AppointmentFormScreen()),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case Appointment.approved:
        return const Color(0xFF2563EB);
      case Appointment.completed:
        return const Color(0xFF15803D);
      case Appointment.cancelled:
        return const Color(0xFF64748B);
      default:
        return const Color(0xFFCA8A04);
    }
  }

  String _statusLabel(String status) => status;

  Widget _statusBadge(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 3, backgroundColor: color),
          const SizedBox(width: 5),
          Text(_statusLabel(status),
              style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Expanded(
      child: Container(
        constraints: const BoxConstraints(minHeight: 80),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800, color: ink)),
            const SizedBox(height: 5),
            Text(label, style: const TextStyle(fontSize: 11, color: muted, height: 1.25)),
          ],
        ),
      ),
    );
  }

  List<Appointment> _filtered(List<Appointment> all) {
    final now = DateTime.now();
    final result = all.where((a) {
      switch (_filter) {
        case 1:
          return a.isActive && !a.dateTime.isBefore(now);
        case 2:
          return a.status == Appointment.completed ||
              (a.isActive && a.dateTime.isBefore(now));
        case 3:
          return a.status == Appointment.cancelled;
        default:
          return true;
      }
    }).toList();
    result.sort((a, b) => _newestFirst
        ? b.dateTime.compareTo(a.dateTime)
        : a.dateTime.compareTo(b.dateTime));
    return result;
  }

  Future<void> _changeStatus(Appointment appointment, String status) async {
    try {
      await _service.setStatus(appointment, status);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Could not update appointment status.'),
      ));
    }
  }

  Future<void> _confirmCancel(Appointment appointment) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel appointment?'),
        content: const Text('This appointment will be marked as Cancelled and kept in your history.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Keep')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: teal),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Cancel appointment'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _service.cancel(appointment);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not cancel appointment.')),
      );
    }
  }

  Widget _appointmentCard(Appointment appointment) {
    final date = appointment.dateTime;
    final active = appointment.isActive;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: const Color(0xFFDEF4EE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(children: [
                  Text(DateFormat('MMM').format(date).toUpperCase(),
                      style: const TextStyle(fontSize: 10, color: teal, fontWeight: FontWeight.w700)),
                  Text(DateFormat('d').format(date),
                      style: const TextStyle(fontSize: 23, color: teal, fontWeight: FontWeight.w800)),
                  Text(DateFormat('EEE').format(date),
                      style: const TextStyle(fontSize: 10, color: muted)),
                ]),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _statusBadge(appointment.status),
                    const SizedBox(height: 6),
                    Text(appointment.reason,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: ink)),
                    const SizedBox(height: 5),
                    Row(children: [
                      const Icon(Icons.schedule_outlined, size: 13, color: muted),
                      const SizedBox(width: 4),
                      Text(DateFormat('h:mm a').format(date),
                          style: const TextStyle(fontSize: 11, color: muted)),
                      const SizedBox(width: 9),
                      const Icon(Icons.location_on_outlined, size: 13, color: muted),
                      const SizedBox(width: 3),
                      const Flexible(
                        child: Text('University Health Clinic',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 10, color: muted)),
                      ),
                    ]),
                    if (appointment.notes.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(appointment.notes,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: muted)),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (active) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: border),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AppointmentFormScreen(existing: appointment),
                    ),
                  ),
                  child: const Text('Edit', style: TextStyle(color: teal)),
                ),
                TextButton(
                  onPressed: () => _confirmCancel(appointment),
                  child: const Text('Cancel', style: TextStyle(color: Color(0xFFDC2626))),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Demo: simulate status',
                  icon: const Icon(Icons.more_vert, color: muted, size: 20),
                  onSelected: (status) => _changeStatus(appointment, status),
                  itemBuilder: (_) => [
                    const PopupMenuItem<String>(enabled: false,
                        child: Text('Demo status simulation', style: TextStyle(fontSize: 11))),
                    if (appointment.status == Appointment.pending)
                      const PopupMenuItem(value: Appointment.approved, child: Text('Mark Approved')),
                    if (appointment.status == Appointment.approved)
                      const PopupMenuItem(value: Appointment.completed, child: Text('Mark Completed')),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _filterTabs() {
    const labels = ['All', 'Upcoming', 'History', 'Cancelled'];
    return Row(
      children: List.generate(labels.length, (index) {
        final selected = _filter == index;
        return Padding(
          padding: const EdgeInsets.only(right: 17),
          child: InkWell(
            onTap: () => setState(() => _filter = index),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(labels[index], style: TextStyle(
                    color: selected ? teal : muted,
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                  )),
                  const SizedBox(height: 7),
                  Container(height: 2, width: 23, color: selected ? teal : Colors.transparent),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

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
              'Appointments',
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

      backgroundColor: bg,
      body: SafeArea(
        child: StreamBuilder<List<Appointment>>(
          stream: _stream,
          builder: (context, snapshot) {
            final all = snapshot.data ?? <Appointment>[];
            final now = DateTime.now();
            final upcomingCount = all.where((a) =>
            a.isActive && !a.dateTime.isBefore(now)).length;
            final completedCount = all.where((a) =>
            a.status == Appointment.completed).length;
            final filtered = _filtered(all);

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(child: Text('My appointments', style: TextStyle(
                              fontSize: 26, fontWeight: FontWeight.w800,
                              letterSpacing: -0.9, color: ink,
                            ))),
                            FilledButton.icon(
                              onPressed: _book,
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Book appointment', style: TextStyle(fontSize: 11)),
                              style: FilledButton.styleFrom(
                                backgroundColor: teal,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        const Text('Every visit, every step. Your care journey in one place.',
                            style: TextStyle(fontSize: 12, color: muted)),
                        const SizedBox(height: 17),
                        Row(children: [
                          _stat('${all.length}', 'Total appointments'),
                          const SizedBox(width: 8),
                          _stat('$upcomingCount', 'Upcoming visits'),
                          const SizedBox(width: 8),
                          _stat('$completedCount', 'Completed visits'),
                        ]),
                        const SizedBox(height: 13),
                        _filterTabs(),
                        Align(
                          alignment: Alignment.centerRight,
                          child: DropdownButton<bool>(
                            value: _newestFirst,
                            underline: const SizedBox.shrink(),
                            style: const TextStyle(color: muted, fontSize: 11),
                            items: const [
                              DropdownMenuItem(value: true, child: Text('Date: newest first')),
                              DropdownMenuItem(value: false, child: Text('Date: oldest first')),
                            ],
                            onChanged: (value) {
                              if (value != null) setState(() => _newestFirst = value);
                            },
                          ),
                        ),
                        const SizedBox(height: 7),
                      ],
                    ),
                  ),
                ),
                if (snapshot.hasError)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text('Could not load appointments.')),
                  )
                else if (!snapshot.hasData)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator(color: teal)),
                  )
                else if (filtered.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.event_note_outlined, color: teal, size: 42),
                              const SizedBox(height: 9),
                              const Text('No appointments to show',
                                  style: TextStyle(color: ink, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              const Text('Your visits will appear here as they are booked.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 12, color: muted)),
                              const SizedBox(height: 10),
                              TextButton(onPressed: _book, child: const Text('Book an appointment')),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 26),
                      sliver: SliverList.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) => _appointmentCard(filtered[index]),
                      ),
                    ),
              ],
            );
          },
        ),
      ),
    );
  }
}

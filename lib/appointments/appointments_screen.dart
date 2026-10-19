import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'appointment_form_screen.dart';
import 'appointment_model.dart';
import 'appointment_service.dart';

// Main appointment page: Upcoming tab + History tab.
class AppointmentsScreen extends StatelessWidget {
  AppointmentsScreen({super.key});

  final _service = AppointmentService();

  static const Color green = Color(0xFF1B8A5A);
  static const Color greenDark = Color(0xFF146B47);
  static const Color background = Color(0xFFF3F9F5);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          title: const Text(
            'My Appointments',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: green,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 4,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            dividerColor: Colors.transparent,
            tabs: [
              Tab(text: 'Upcoming'),
              Tab(text: 'History'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: green,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text(
            'Book',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AppointmentFormScreen(),
            ),
          ),
        ),
        body: StreamBuilder<List<Appointment>>(
          stream: _service.stream(),
          builder: (context, snap) {
            if (snap.hasError) {
              return Center(child: Text('Error: ${snap.error}'));
            }

            if (!snap.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: green),
              );
            }

            final all = snap.data!;
            final upcoming = all.where((a) => a.isActive).toList();
            final history =
            all.where((a) => !a.isActive).toList().reversed.toList();

            return TabBarView(
              children: [
                _list(context, upcoming, 'No upcoming appointments'),
                _list(context, history, 'No past appointments yet'),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _list(BuildContext context, List<Appointment> items, String empty) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_available, size: 56, color: green),
            const SizedBox(height: 10),
            Text(
              empty,
              style: const TextStyle(color: greenDark, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 88),
      itemCount: items.length,
      itemBuilder: (_, i) => _card(context, items[i]),
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case Appointment.approved:
        return green;
      case Appointment.completed:
        return Colors.blue;
      case Appointment.cancelled:
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Widget _card(BuildContext context, Appointment a) {
    final color = _statusColor(a.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  a.reason,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: greenDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Chip(
                label: Text(
                  a.status,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                side: BorderSide(color: color),
                backgroundColor: color.withOpacity(0.1),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.schedule, size: 16, color: green),
              const SizedBox(width: 6),
              Text(
                DateFormat('EEE, MMM d, y  •  h:mm a').format(a.dateTime),
                style: const TextStyle(color: Colors.black87),
              ),
            ],
          ),
          if (a.notes.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(a.notes, style: const TextStyle(color: Colors.grey)),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              PopupMenuButton<String>(
                tooltip: 'Simulate status',
                icon: const Icon(Icons.more_vert, color: greenDark),
                onSelected: (s) => _service.setStatus(a, s),
                itemBuilder: (_) => [
                  Appointment.pending,
                  Appointment.approved,
                  Appointment.completed,
                ]
                    .map((s) => PopupMenuItem(
                  value: s,
                  child: Text('Mark as $s'),
                ))
                    .toList(),
              ),
              if (a.isActive) ...[
                TextButton.icon(
                  icon: const Icon(Icons.edit, color: green),
                  label: const Text('Edit', style: TextStyle(color: green)),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AppointmentFormScreen(existing: a),
                    ),
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  label: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.red),
                  ),
                  onPressed: () => _confirmCancel(context, a),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmCancel(BuildContext context, Appointment a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text(
          'Cancel appointment?',
          style: TextStyle(color: greenDark, fontWeight: FontWeight.bold),
        ),
        content: const Text('This will mark the appointment as Cancelled.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep', style: TextStyle(color: green)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel appointment'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await _service.cancel(a);
    }
  }
}
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'appointment_model.dart';
import 'appointment_service.dart';

class AppointmentFormScreen extends StatefulWidget {
  final Appointment? existing;

  const AppointmentFormScreen({super.key, this.existing});

  @override
  State<AppointmentFormScreen> createState() => _AppointmentFormScreenState();
}

class _AppointmentFormScreenState extends State<AppointmentFormScreen> {
  final _service = AppointmentService();
  final _formKey = GlobalKey<FormState>();
  final _reason = TextEditingController();
  final _notes = TextEditingController();

  DateTime? _date;
  TimeOfDay? _time;
  String _studentId = 'Loading...';
  bool _saving = false;
  bool _submitted = false;

  static const green = Color(0xFF1B8A5A);
  static const greenDark = Color(0xFF146B47);
  static const mint = Color(0xFFF1F8F4);
  static const background = Color(0xFFF3F9F5);

  @override
  void initState() {
    super.initState();
    final e = widget.existing;

    if (e != null) {
      _studentId = e.studentId;
      _reason.text = e.reason;
      _notes.text = e.notes;
      _date = e.dateTime;
      _time = TimeOfDay.fromDateTime(e.dateTime);
    } else {
      _service.getStudentId().then((id) {
        if (mounted) setState(() => _studentId = id);
      });
    }
  }

  @override
  void dispose() {
    _reason.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _date != null &&
          !_date!.isBefore(DateTime(now.year, now.month, now.day))
          ? _date!
          : now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: green),
        ),
        child: child!,
      ),
    );

    if (selected != null) setState(() => _date = selected);
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: green),
        ),
        child: child!,
      ),
    );
    if (selected != null) setState(() => _time = selected);
  }

  Future<void> _save() async {
    setState(() => _submitted = true);

    if (!_formKey.currentState!.validate()) return;

    if (_date == null || _time == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a date and time')),
      );
      return;
    }

    final dateTime = DateTime(
      _date!.year,
      _date!.month,
      _date!.day,
      _time!.hour,
      _time!.minute,
    );

    if (widget.existing == null && dateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a future date and time')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final e = widget.existing;

      if (e == null) {
        await _service.add(Appointment(
          studentId: await _service.getStudentId(),
          dateTime: dateTime,
          reason: _reason.text.trim(),
          notes: _notes.text.trim(),
        ));
      } else {
        await _service.update(Appointment(
          id: e.id,
          studentId: e.studentId,
          dateTime: dateTime,
          reason: _reason.text.trim(),
          notes: _notes.text.trim(),
          status: e.status,
        ));
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    }
  }

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
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
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: green,
        foregroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        title: Text(
          editing ? 'Edit Appointment' : 'New Appointment',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const Text(
              'Book an Appointment',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: greenDark,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Fill in your appointment details below.',
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
                children: [
                  TextFormField(
                    key: ValueKey(_studentId),
                    initialValue: _studentId,
                    readOnly: true,
                    decoration: _decoration('Student ID', Icons.badge_outlined),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: _decoration(
                        'Appointment Date',
                        Icons.calendar_today,
                      ).copyWith(
                        errorText: _submitted && _date == null
                            ? 'Please select a date'
                            : null,
                      ),
                      child: Text(
                        _date == null
                            ? 'Choose date'
                            : DateFormat('MMM d, yyyy').format(_date!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _pickTime,
                    child: InputDecorator(
                      decoration: _decoration(
                        'Appointment Time',
                        Icons.access_time,
                      ).copyWith(
                        errorText: _submitted && _time == null
                            ? 'Please select a time'
                            : null,
                      ),
                      child: Text(
                        _time == null ? 'Choose time' : _time!.format(context),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _reason,
                    decoration: _decoration('Reason', Icons.edit_note),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Reason is required'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notes,
                    maxLines: 3,
                    decoration: _decoration('Notes (Optional)', Icons.notes),
                  ),
                  const SizedBox(height: 24),
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
                          : const Icon(Icons.save),
                      label: Text(
                        _saving
                            ? 'Saving...'
                            : editing
                            ? 'Save Changes'
                            : 'Book Appointment',
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
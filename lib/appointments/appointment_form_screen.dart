import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'appointment_model.dart';
import 'appointment_service.dart';
import '../main.dart' show CampusCareMenuButton;

class AppointmentFormScreen extends StatefulWidget {
  final Appointment? existing;

  const AppointmentFormScreen({super.key, this.existing});

  @override
  State<AppointmentFormScreen> createState() => _AppointmentFormScreenState();
}

class _AppointmentFormScreenState extends State<AppointmentFormScreen> {
  static const Color teal = Color(0xFF00846F);
  static const Color ink = Color(0xFF102B31);
  static const Color muted = Color(0xFF748596);
  static const Color pageBackground = Color(0xFFF8FAFB);
  static const Color border = Color(0xFFE5EBEF);

  final AppointmentService _service = AppointmentService();
  final GlobalKey<FormState> _detailsKey = GlobalKey<FormState>();
  final TextEditingController _reason = TextEditingController();
  final TextEditingController _notes = TextEditingController();

  // Slots are illustrative; the current backend does not track clinic capacity.
  static const List<int> _timeSlots = <int>[
    8 * 60, 9 * 60, 10 * 60, 11 * 60,
    13 * 60, 14 * 60, 15 * 60, 16 * 60,
  ];

  int _step = 0;
  DateTime? _date;
  TimeOfDay? _time;
  String _studentId = 'Loading...';
  bool _saving = false;
  String? _dateError;
  String? _timeError;
  late DateTime _displayMonth;

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _studentId = existing.studentId;
      _reason.text = existing.reason;
      _notes.text = existing.notes;
      _date = DateUtils.dateOnly(existing.dateTime);
      _time = TimeOfDay.fromDateTime(existing.dateTime);
      _displayMonth = DateTime(_date!.year, _date!.month);
    } else {
      final now = DateTime.now();
      _displayMonth = DateTime(now.year, now.month);
      _loadStudentId();
    }
  }

  Future<void> _loadStudentId() async {
    try {
      final id = await _service.getStudentId();
      if (mounted) setState(() => _studentId = id);
    } catch (_) {
      if (mounted) setState(() => _studentId = 'Not available');
    }
  }

  @override
  void dispose() {
    _reason.dispose();
    _notes.dispose();
    super.dispose();
  }

  DateTime get _today => DateUtils.dateOnly(DateTime.now());

  bool _canSelectDate(DateTime date) {
    final day = DateUtils.dateOnly(date);
    if (day.isBefore(_today)) {
      // Let an old appointment retain its date while editing, but do not
      // allow a past date to pass final submission validation.
      return _editing && _date != null && DateUtils.isSameDay(day, _date);
    }
    return !day.isAfter(_today.add(const Duration(days: 365)));
  }

  bool _slotIsFuture(DateTime date, int minutes) {
    final at = DateTime(date.year, date.month, date.day,
        minutes ~/ 60, minutes % 60);
    return at.isAfter(DateTime.now());
  }

  bool _isTimeAllowed(DateTime date, TimeOfDay time) {
    final minutes = time.hour * 60 + time.minute;
    return _timeSlots.contains(minutes) && _slotIsFuture(date, minutes);
  }

  String _formatTime(TimeOfDay time) {
    final date = DateTime(2020, 1, 1, time.hour, time.minute);
    return DateFormat('h:mm a').format(date);
  }

  void _notify(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _goNext() {
    FocusScope.of(context).unfocus();
    if (_step == 0) {
      if (_date == null || !_canSelectDate(_date!) || _date!.isBefore(_today)) {
        setState(() => _dateError = 'Please select a future date.');
        return;
      }
    } else if (_step == 1) {
      if (_date == null || _time == null || !_isTimeAllowed(_date!, _time!)) {
        setState(() => _timeError = 'Select an available future time slot.');
        return;
      }
    } else if (_step == 2) {
      if (!_detailsKey.currentState!.validate()) return;
    }
    if (_step < 3) setState(() => _step++);
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_date == null || _time == null || _reason.text.trim().isEmpty) {
      _notify('Please complete all required appointment details.');
      return;
    }
    if (!_isTimeAllowed(_date!, _time!)) {
      setState(() {
        _step = 1;
        _timeError = 'This time is no longer in the future. Select another.';
      });
      return;
    }

    final scheduled = DateTime(
      _date!.year, _date!.month, _date!.day, _time!.hour, _time!.minute,
    );
    setState(() => _saving = true);
    try {
      final existing = widget.existing;
      if (existing == null) {
        final studentId = await _service.getStudentId();
        await _service.add(Appointment(
          studentId: studentId,
          dateTime: scheduled,
          reason: _reason.text.trim(),
          notes: _notes.text.trim(),
        ));
      } else {
        await _service.update(Appointment(
          id: existing.id,
          studentId: existing.studentId,
          dateTime: scheduled,
          reason: _reason.text.trim(),
          notes: _notes.text.trim(),
          status: existing.status,
        ));
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      _notify('Unable to save appointment: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _panel(Widget child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: border),
    ),
    child: child,
  );


  Widget _buildStepIndicator() {
    const labels = ['Date', 'Time', 'Details', 'Review'];
    const teal = Color(0xFF00846F);
    const inactive = Color(0xFFF1F5F9);

    return LayoutBuilder(
      builder: (context, constraints) {
        final stepWidth = constraints.maxWidth / 4;

        return SizedBox(
          height: 53,
          child: Stack(
            children: [
              // Connecting lines behind the circles
              Positioned(
                top: 13,
                left: stepWidth / 2,
                right: stepWidth / 2,
                child: Row(
                  children: List.generate(3, (index) {
                    return Expanded(
                      child: Container(
                        height: 2,
                        color: index < _step ? teal : inactive,
                      ),
                    );
                  }),
                ),
              ),

              // Four equally spaced steps
              Row(
                children: List.generate(4, (index) {
                  final isActive = _step == index;
                  final isCompleted = index < _step;

                  return Expanded(
                    child: Column(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isActive || isCompleted
                                ? teal
                                : inactive,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isActive || isCompleted
                                  ? Colors.white
                                  : const Color(0xFF64748B),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        const SizedBox(height: 7),

                        Text(
                          labels[index],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: isActive
                                ? teal
                                : const Color(0xFF64748B),
                            fontWeight: isActive
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }



  Widget _dateStep() {
    return _panel(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select a date', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: ink)),
        const SizedBox(height: 4),
        const Text('Choose a day that works best for you.', style: TextStyle(color: muted, fontSize: 12)),
        const SizedBox(height: 12),
        CalendarDatePicker(
          key: ValueKey('${_displayMonth.year}-${_displayMonth.month}'),
          initialDate: _date != null && _canSelectDate(_date!) ? _date : null,
          firstDate: _today.subtract(_editing ? const Duration(days: 365) : Duration.zero),
          lastDate: _today.add(const Duration(days: 365)),
          currentDate: _today,
          selectableDayPredicate: _canSelectDate,
          onDateChanged: (date) => setState(() {
            _date = DateUtils.dateOnly(date);
            _dateError = null;
            _time = null; // Different date requires fresh time selection.
          }),
          onDisplayedMonthChanged: (month) => _displayMonth = month,
        ),
        if (_dateError != null)
          Text(_dateError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
        const SizedBox(height: 8),
        _nextButton('Continue', _goNext),
      ],
    ));
  }

  Widget _timeStep() {
    return _panel(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select a time', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: ink)),
        const SizedBox(height: 6),
        Text(_date == null ? 'Choose a date first' : DateFormat('EEEE, MMMM d, yyyy').format(_date!),
            style: const TextStyle(color: muted, fontSize: 13)),
        const SizedBox(height: 17),
        Wrap(
          spacing: 9,
          runSpacing: 10,
          children: _timeSlots.map((slot) {
            final time = TimeOfDay(hour: slot ~/ 60, minute: slot % 60);
            final enabled = _date != null && _slotIsFuture(_date!, slot);
            final chosen = _time?.hour == time.hour && _time?.minute == time.minute;
            return ChoiceChip(
              label: Text(_formatTime(time)),
              selected: chosen,
              onSelected: enabled ? (_) => setState(() {
                _time = time;
                _timeError = null;
              }) : null,
              selectedColor: const Color(0xFFD5F2E9),
              backgroundColor: Colors.white,
              side: BorderSide(color: chosen ? teal : border),
              labelStyle: TextStyle(color: enabled ? ink : muted),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        const Text('Demo time slots only — not verified clinic availability.',
            style: TextStyle(color: muted, fontSize: 11)),
        if (_timeError != null) ...[
          const SizedBox(height: 8),
          Text(_timeError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
        ],
        const SizedBox(height: 17),
        _nextButton('Continue', _goNext),
      ],
    ));
  }

  InputDecoration _input(String label, {String? hint}) => InputDecoration(
    labelText: label,
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9), borderSide: const BorderSide(color: border)),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9), borderSide: const BorderSide(color: teal, width: 1.5)),
    errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9), borderSide: const BorderSide(color: Colors.red)),
    focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
  );

  Widget _detailsStep() => _panel(Form(
    key: _detailsKey,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Appointment details', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: ink)),
      const SizedBox(height: 6),
      const Text('Tell the clinic why you need a visit.', style: TextStyle(color: muted, fontSize: 12)),
      const SizedBox(height: 18),
      TextFormField(
        controller: _reason,
        textInputAction: TextInputAction.next,
        decoration: _input('Reason for appointment *', hint: 'e.g. General Consultation'),
        validator: (value) => value == null || value.trim().isEmpty
            ? 'Reason is required' : null,
      ),
      const SizedBox(height: 14),
      TextFormField(
        controller: _notes,
        maxLines: 3,
        decoration: _input('Additional notes (optional)'),
      ),
      const SizedBox(height: 18),
      _nextButton('Review appointment', _goNext),
    ]),
  ));

  Widget _summaryLine(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 95, child: Text(label, style: const TextStyle(color: muted, fontSize: 12))),
      Expanded(child: Text(value, textAlign: TextAlign.right,
          style: const TextStyle(color: ink, fontSize: 12, fontWeight: FontWeight.w600))),
    ]),
  );

  Widget _reviewStep() => _panel(Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Review your appointment', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: ink)),
      const SizedBox(height: 8),
      const Text('Check everything before confirming.', style: TextStyle(color: muted, fontSize: 12)),
      const Divider(height: 26),
      _summaryLine('Student ID', _studentId),
      _summaryLine('Date', _date == null ? 'Not selected' : DateFormat('MMMM d, yyyy').format(_date!)),
      _summaryLine('Time', _time == null ? 'Not selected' : _formatTime(_time!)),
      _summaryLine('Reason', _reason.text.trim()),
      _summaryLine('Notes', _notes.text.trim().isEmpty ? 'None' : _notes.text.trim()),
      _summaryLine('Status', _editing ? widget.existing!.status : Appointment.pending),
      const Divider(height: 26),
      _nextButton(_editing ? 'Save changes' : 'Confirm appointment', _saving ? null : _save),
    ],
  ));

  Widget _nextButton(String label, VoidCallback? onPressed) => Align(
    alignment: Alignment.centerRight,
    child: FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: teal,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: _saving ? const SizedBox(width: 16, height: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.arrow_forward, size: 17),
      label: Text(_saving ? 'Saving...' : label),
    ),
  );

 Widget _appointmentSummary() => _panel(Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Row(children: [
      const Icon(Icons.event_note_outlined, color: teal, size: 21),
      const SizedBox(width: 8),
      const Text(
        'Your appointment',
        style: TextStyle(color: ink, fontWeight: FontWeight.w800),
      ),
    ]),
      const SizedBox(height: 11),
      _summaryLine('Date', _date == null ? 'Not selected' : DateFormat('MMM d, yyyy').format(_date!)),
      _summaryLine('Time', _time == null ? 'Not selected' : _formatTime(_time!)),
      _summaryLine('Reason', _reason.text.trim().isEmpty ? 'Not selected' : _reason.text.trim()),
      _summaryLine('Student', _studentId),
      const Divider(height: 25),
      const Text('University Health Clinic', style: TextStyle(color: ink, fontWeight: FontWeight.w700, fontSize: 12)),
      const Text('Location shown for prototype purposes.', style: TextStyle(color: muted, fontSize: 11)),
    ],
  ));

  @override
  Widget build(BuildContext context) {
    final steps = <Widget>[_dateStep(), _timeStep(), _detailsStep(), _reviewStep()];
    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
      backgroundColor: Colors.white,
      foregroundColor: ink,
      title: Text(
      _editing ? 'Edit appointment' : 'Appointments',
      style: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
    ),
  ),

),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
        children: [
          const Text('A little time for your health.',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800, color: ink)),
          const SizedBox(height: 5),
          const Text('Book a visit with your campus clinic. We\'ll take it one step at a time.',
              style: TextStyle(fontSize: 12, color: muted, height: 1.5)),
          const SizedBox(height: 21),
          _buildStepIndicator(),
          const SizedBox(height: 18),
          steps[_step],
          if (_step > 0) ...[
            const SizedBox(height: 7),
            Align(alignment: Alignment.centerLeft, child: TextButton.icon(
              onPressed: _saving ? null : () => setState(() => _step--),
              icon: const Icon(Icons.arrow_back, size: 17),
              label: const Text('Previous step'),
            )),
          ],
          const SizedBox(height: 14),
          _appointmentSummary(),
        ],
      ),
    );
  }
}

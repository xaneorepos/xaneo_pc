import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'scheduled_modal_shell.dart';
import 'scheduled_modal_style.dart';

Future<DateTime?> pickScheduledDesktopDate(
  BuildContext context, {
  required DateTime initial,
  required DateTime minimum,
  required DateTime maximum,
}) => ScheduledModalShell.show<DateTime>(
  context: context,
  builder: (_) => _ScheduledDatePicker(
    initial: initial,
    minimum: minimum,
    maximum: maximum,
  ),
);

class _ScheduledDatePicker extends StatefulWidget {
  const _ScheduledDatePicker({
    required this.initial,
    required this.minimum,
    required this.maximum,
  });
  final DateTime initial;
  final DateTime minimum;
  final DateTime maximum;
  @override
  State<_ScheduledDatePicker> createState() => _ScheduledDatePickerState();
}

class _ScheduledDatePickerState extends State<_ScheduledDatePicker> {
  late DateTime _date = widget.initial;
  @override
  Widget build(BuildContext context) {
    final l10n = MaterialLocalizations.of(context);
    return ScheduledModalShell(
      width: 400,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ScheduledModalHeader(title: l10n.datePickerHelpText),
          Flexible(
            child: SingleChildScrollView(
              child: CalendarDatePicker(
                initialDate: widget.initial,
                firstDate: widget.minimum,
                lastDate: widget.maximum,
                onDateChanged: (date) => setState(() => _date = date),
              ),
            ),
          ),
          ScheduledModalFooter(
            label: l10n.okButtonLabel,
            cancelLabel: l10n.cancelButtonLabel,
            onSave: () => Navigator.pop(context, _date),
            onCancel: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

Future<TimeOfDay?> pickScheduledDesktopTime(
  BuildContext context,
  TimeOfDay initial,
) => ScheduledModalShell.show<TimeOfDay>(
  context: context,
  builder: (_) => _ScheduledTimePicker(initial: initial),
);

class _ScheduledTimePicker extends StatefulWidget {
  const _ScheduledTimePicker({required this.initial});
  final TimeOfDay initial;
  @override
  State<_ScheduledTimePicker> createState() => _ScheduledTimePickerState();
}

class _ScheduledTimePickerState extends State<_ScheduledTimePicker> {
  final _form = GlobalKey<FormState>();
  late final _hour = TextEditingController(
    text: widget.initial.hour.toString().padLeft(2, '0'),
  );
  late final _minute = TextEditingController(
    text: widget.initial.minute.toString().padLeft(2, '0'),
  );
  @override
  void dispose() {
    _hour.dispose();
    _minute.dispose();
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    Navigator.pop(
      context,
      TimeOfDay(hour: int.parse(_hour.text), minute: int.parse(_minute.text)),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    int maximum, {
    bool last = false,
  }) => Expanded(
    child: ScheduledModalLabel(
      label: label,
      child: TextFormField(
        controller: controller,
        autofocus: !last,
        keyboardType: TextInputType.number,
        textInputAction: last ? TextInputAction.done : TextInputAction.next,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(2),
        ],
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 28),
        decoration: const InputDecoration(),
        validator: (text) {
          final value = int.tryParse(text ?? '');
          return value == null || value < 0 || value > maximum
              ? MaterialLocalizations.of(context).invalidTimeLabel
              : null;
        },
        onFieldSubmitted: (_) {
          if (last) _save();
        },
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final l10n = MaterialLocalizations.of(context);
    return ScheduledModalShell(
      width: 360,
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ScheduledModalHeader(title: l10n.timePickerInputHelpText),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _field(_hour, l10n.timePickerHourLabel, 23),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Text(':', style: TextStyle(fontSize: 28)),
                ),
                _field(_minute, l10n.timePickerMinuteLabel, 59, last: true),
              ],
            ),
            const SizedBox(height: 20),
            ScheduledModalFooter(
              label: l10n.okButtonLabel,
              cancelLabel: l10n.cancelButtonLabel,
              onSave: _save,
              onCancel: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

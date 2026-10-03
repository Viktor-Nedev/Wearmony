import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../util/format.dart';

/// The optional day of the event, picked from a calendar and clearable.
class EventDateField extends StatelessWidget {
  const EventDateField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var first = today.subtract(const Duration(days: 30));
    if (value != null && value!.isBefore(first)) first = value!;
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? today.add(const Duration(days: 30)),
      firstDate: first,
      lastDate: today.add(const Duration(days: 3 * 365)),
      helpText: AppLocalizations.of(context).eventDateLabel,
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final day = value;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _pick(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: l10n.eventDateLabel,
          prefixIcon: const Icon(Icons.event_outlined),
          suffixIcon: day == null
              ? const Icon(Icons.edit_calendar_outlined)
              : IconButton(
                  tooltip: l10n.eventDateClear,
                  icon: const Icon(Icons.close),
                  onPressed: () => onChanged(null),
                ),
        ),
        child: Text(
          day == null
              ? l10n.eventDateNone
              : '${formatEventDay(context, day)} · ${countdownLabel(l10n, day)}',
        ),
      ),
    );
  }
}

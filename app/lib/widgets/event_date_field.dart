import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../util/format.dart';

/// An optional day (the event, or when looks are due), picked from a calendar and clearable.
class EventDateField extends StatelessWidget {
  const EventDateField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.emptyText,
    this.icon = Icons.event_outlined,
    this.lastDate,
  });

  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  /// Defaults to the event day's label and empty text.
  final String? label;
  final String? emptyText;
  final IconData icon;

  /// The latest day that can be picked (for example the event day).
  final DateTime? lastDate;

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var first = today.subtract(const Duration(days: 30));
    if (value != null && value!.isBefore(first)) first = value!;
    var last = lastDate ?? today.add(const Duration(days: 3 * 365));
    if (last.isBefore(first)) last = first;
    var initial = value ?? today.add(const Duration(days: 30));
    if (initial.isAfter(last)) initial = last;
    if (initial.isBefore(first)) initial = first;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      helpText: label ?? AppLocalizations.of(context).eventDateLabel,
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
          labelText: label ?? l10n.eventDateLabel,
          prefixIcon: Icon(icon),
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
              ? (emptyText ?? l10n.eventDateNone)
              : '${formatEventDay(context, day)} · ${countdownLabel(l10n, day)}',
        ),
      ),
    );
  }
}

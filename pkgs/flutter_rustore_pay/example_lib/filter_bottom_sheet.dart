import 'package:flutter/material.dart';

class FilterBottomSheet extends StatelessWidget {
  const FilterBottomSheet({
    super.key,
    required this.children,
    required this.onReset,
    required this.onApply,
  });

  final List<Widget> children;
  final VoidCallback onReset;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Фильтры',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Закрыть',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
            const SizedBox(height: 16),
            TextButton(
              onPressed: onReset,
              child: const Text('Сбросить фильтры'),
            ),
            FilledButton(
              onPressed: onApply,
              child: const Text('Применить'),
            ),
          ],
        ),
      ),
    );
  }
}

class MultiChoiceFilter<T> extends StatelessWidget {
  const MultiChoiceFilter({
    super.key,
    required this.title,
    required this.options,
    required this.selected,
    required this.onToggle,
  });

  final String title;
  final Map<T, String> options;
  final Set<T> selected;
  final ValueChanged<T> onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        for (final option in options.entries)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(option.value),
            value: selected.contains(option.key),
            onChanged: (_) => onToggle(option.key),
          ),
      ],
    );
  }
}

class DateFilterField extends StatelessWidget {
  const DateFilterField({
    super.key,
    required this.title,
    required this.date,
    required this.onChanged,
    this.endOfDay = false,
  });

  final String title;
  final DateTime? date;
  final ValueChanged<DateTime?> onChanged;
  final bool endOfDay;

  Future<void> _selectDate(BuildContext context) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: date ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100, 12, 31),
      helpText: title,
      cancelText: 'Отмена',
      confirmText: 'Выбрать',
    );
    if (selected == null || !context.mounted) return;
    final startOfDay =
        DateTime.utc(selected.year, selected.month, selected.day);
    onChanged(
      endOfDay
          ? startOfDay
              .add(const Duration(days: 1))
              .subtract(const Duration(milliseconds: 1))
          : startOfDay,
    );
  }

  @override
  Widget build(BuildContext context) {
    final value = date;
    final label = value == null
        ? 'Не задано'
        : '${value.day.toString().padLeft(2, '0')}.'
            '${value.month.toString().padLeft(2, '0')}.${value.year}';
    return InputDecorator(
      decoration: InputDecoration(
        labelText: title,
        border: const OutlineInputBorder(),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton.icon(
              onPressed: () => _selectDate(context),
              icon: const Icon(Icons.calendar_today),
              label: Text(label),
            ),
          ),
          if (value != null)
            IconButton(
              tooltip: 'Очистить дату',
              onPressed: () => onChanged(null),
              icon: const Icon(Icons.clear),
            ),
        ],
      ),
    );
  }
}
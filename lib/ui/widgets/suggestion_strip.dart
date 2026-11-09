import 'package:flutter/material.dart';

import '../../ai/suggestion.dart';

/// Ненавязчивая лента подсказок ассистента. Касание — добавить, долгое нажатие — «не предлагать».
class SuggestionStrip extends StatelessWidget {
  const SuggestionStrip({
    super.key,
    required this.suggestions,
    required this.onAccept,
    required this.onDismiss,
    required this.onHide,
  });

  final List<Suggestion> suggestions;
  final void Function(Suggestion) onAccept;
  final void Function(Suggestion) onDismiss;
  final VoidCallback onHide;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      padding: const EdgeInsets.fromLTRB(12, 6, 4, 10),
      decoration: BoxDecoration(
        color: t.colorScheme.secondaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.auto_awesome, size: 18, color: t.colorScheme.primary),
          const SizedBox(width: 6),
          Expanded(child: Text('Возможно, понадобится', style: t.textTheme.labelLarge)),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Скрыть подсказки',
            icon: const Icon(Icons.close, size: 18),
            onPressed: onHide,
          ),
        ]),
        SizedBox(
          height: 52,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: suggestions.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final s = suggestions[i];
              return Material(
                color: t.colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => onAccept(s),
                  onLongPress: () => onDismiss(s),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(s.source == SuggestionSource.cloud ? Icons.psychology_alt_outlined : Icons.add_circle_outline,
                          size: 18, color: t.colorScheme.primary),
                      const SizedBox(width: 6),
                      Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(s.name, style: t.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                        Text(s.reason, style: t.textTheme.labelSmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
                      ]),
                    ]),
                  ),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}

/// Проверка перед походом в магазин: отметить нужное и добавить одним касанием.
class PreShopCheckSheet extends StatefulWidget {
  const PreShopCheckSheet({super.key, required this.suggestions});
  final List<Suggestion> suggestions;

  @override
  State<PreShopCheckSheet> createState() => _PreShopCheckSheetState();
}

class _PreShopCheckSheetState extends State<PreShopCheckSheet> {
  final _picked = <Suggestion>{};

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Ничего не забыли?', style: t.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('Обычно к вашему списку берут ещё:', style: t.textTheme.bodyMedium),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final s in widget.suggestions)
              FilterChip(
                label: Text(s.name),
                tooltip: s.reason,
                selected: _picked.contains(s),
                onSelected: (v) => setState(() => v ? _picked.add(s) : _picked.remove(s)),
              ),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, const <Suggestion>[]),
                child: const Text('Всё есть'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _picked.isEmpty ? null : () => Navigator.pop(context, _picked.toList()),
                child: Text(_picked.isEmpty ? 'Добавить' : 'Добавить (${_picked.length})'),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}

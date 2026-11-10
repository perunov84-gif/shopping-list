import '../data/catalog.dart';
import '../data/list_repository.dart';
import '../models/list_item.dart';
import '../models/shop_list.dart';
import 'suggestion.dart';

/// Подсказки «не забыть купить». Без ИИ и без сети — полностью на устройстве:
///  1. Правила из встроенной базы (гвозди → молоток).
///  2. Память пользователя: что он сам обычно покупает вместе и часто.
///
/// Ненавязчивость обеспечивает UI: подсказки показываются небольшой лентой
/// только когда в списке есть хотя бы [minItemsToSuggest] позиции, их можно скрыть,
/// а отклонённые подсказки больше не повторяются в этом списке.
class SuggestionEngine {
  SuggestionEngine({required this.catalog, required this.repo});

  final Catalog catalog;
  final ListRepository repo;

  static const minItemsToSuggest = 1;
  static const maxSuggestions = 8;

  final Map<int, Set<String>> _dismissed = {};

  void dismiss(int listId, String name) => _dismissed.putIfAbsent(listId, () => {}).add(normalizeKey(name));

  /// Быстрые подсказки (правила + память). Вызывается после каждого изменения списка.
  Future<List<Suggestion>> local(ShopList list) async {
    final present = list.items.map((i) => i.key).toSet();
    if (present.length < minItemsToSuggest) return const [];
    final dismissed = {..._dismissed[list.id] ?? const <String>{}};
    try {
      dismissed.addAll(await repo.hidden(list.category));
    } catch (_) {}
    final scores = <String, Suggestion>{};

    void add(String name, String reason, double score, SuggestionSource source) {
      final k = normalizeKey(name);
      if (present.contains(k) || dismissed.contains(k)) return;
      final prev = scores[k];
      if (prev == null) {
        scores[k] = Suggestion(name: name, reason: reason, score: score, source: source);
      } else {
        scores[k] = Suggestion(name: prev.name, reason: prev.reason, score: prev.score + score, source: prev.source);
      }
    }

    // 1. Правила: свежедобавленные позиции весят больше.
    final cc = catalog.of(list.category);
    final items = list.items.where((i) => !i.checked).toList();
    for (var idx = 0; idx < items.length; idx++) {
      final item = items[idx];
      final recency = 1.0 + idx / (items.length + 1); // последние добавленные — выше
      final related = cc.related[item.key] ?? _relatedAnyCategory(item.key);
      for (var r = 0; r < related.length; r++) {
        add(related[r], 'к «${item.name}»', (3.0 - r * 0.3) * recency, SuggestionSource.rules);
      }
    }

    // 2. Память: что пользователь сам покупал вместе с этими товарами.
    try {
      final pairs = await repo.pairsFor(list.category, present.toList());
      final history = await repo.history(list.category, limit: 60);
      final nameByKey = {for (final h in history) normalizeKey(h.name): h.name};
      pairs.forEach((key, count) {
        if (count < 2) return; // одно совпадение — ещё не привычка
        final name = nameByKey[key] ?? capitalize(key);
        add(name, 'обычно берёте вместе', 1.5 * count, SuggestionSource.history);
      });
      // Частые покупки в этом типе магазина (с затуханием по давности).
      final now = DateTime.now();
      for (final h in history.take(20)) {
        if (h.count < 3) continue;
        final days = now.difference(h.lastUsed).inDays;
        if (days < 3) continue; // недавно покупали — вряд ли нужно снова
        add(h.name, 'часто покупаете', (h.count / 3).clamp(1, 4).toDouble() * (days > 30 ? 0.5 : 1), SuggestionSource.history);
      }
    } catch (_) {
      // память — необязательный слой, ошибки не должны мешать
    }

    final list2 = scores.values.toList()..sort((a, b) => b.score.compareTo(a.score));
    return list2.take(maxSuggestions).toList();
  }

  List<String> _relatedAnyCategory(String key) {
    final cat = catalog.categoryOf(key);
    if (cat == null) return const [];
    return catalog.of(cat).related[key] ?? const [];
  }
}

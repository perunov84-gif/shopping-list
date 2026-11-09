import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/list_item.dart';
import '../models/store_category.dart';
import '../services/input_parser.dart';
import '../services/russian_stem.dart';

class CategoryCatalog {
  CategoryCatalog({required this.sectionOf, required this.related, required this.names});

  /// ключ товара -> название отдела магазина
  final Map<String, String> sectionOf;

  /// ключ товара -> «что логично купить вместе»
  final Map<String, List<String>> related;

  /// все известные названия (каноничная форма)
  final List<String> names;

  /// Порядок отделов (для сортировки в режиме магазина).
  List<String> get sectionOrder => sectionOf.values.toSet().toList();
}

/// Встроенная офлайн-база товаров и связей между ними.
/// Это «быстрый мозг» ассистента: работает мгновенно, бесплатно и без сети.
class Catalog implements Lexicon {
  Catalog._(this._byCategory);

  final Map<StoreCategory, CategoryCatalog> _byCategory;
  final Map<String, String> _stemIndex = {}; // стем фразы -> каноничное имя
  int _maxWords = 1;

  static const _aliases = {
    'яиц': 'Яйца',
    'яичек': 'Яйца',
    'яички': 'Яйца',
    'картошка': 'Картофель',
    'картошку': 'Картофель',
    'картошки': 'Картофель',
    'масло': 'Сливочное масло',
    'масла': 'Сливочное масло',
    'туалетка': 'Туалетная бумага',
    'туалетку': 'Туалетная бумага',
    'шурупов': 'Шурупы',
    'саморезов': 'Саморезы',
    'сосисок': 'Сосиски',
    'помидор': 'Помидоры',
    'огурцов': 'Огурцы',
    'бананов': 'Бананы',
    'яблок': 'Яблоки',
    'лимон': 'Лимоны',
    'кофейку': 'Кофе',
    'порошок': 'Стиральный порошок',
    'порошка': 'Стиральный порошок',
    'газировку': 'Газировка',
    'минералку': 'Минеральная вода',
    'курицу': 'Курица',
  };

  static Future<Catalog> load() async {
    final raw = await rootBundle.loadString('assets/data/catalog.json');
    return Catalog.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  factory Catalog.fromJson(Map<String, dynamic> json) {
    final cats = json['categories'] as Map<String, dynamic>;
    final result = <StoreCategory, CategoryCatalog>{};
    for (final entry in cats.entries) {
      final cat = StoreCategory.fromKey(entry.key);
      final data = entry.value as Map<String, dynamic>;
      final sectionOf = <String, String>{};
      final names = <String>{};
      final sections = (data['sections'] as Map<String, dynamic>? ?? {});
      for (final s in sections.entries) {
        for (final n in (s.value as List).cast<String>()) {
          sectionOf[normalizeKey(n)] = s.key;
          names.add(n);
        }
      }
      final related = <String, List<String>>{};
      for (final r in (data['related'] as Map<String, dynamic>? ?? {}).entries) {
        final values = (r.value as List).cast<String>();
        related[normalizeKey(r.key)] = values;
        names.add(r.key);
        names.addAll(values);
      }
      result[cat] = CategoryCatalog(sectionOf: sectionOf, related: related, names: names.toList()..sort());
    }
    final c = Catalog._(result);
    c._buildIndex();
    return c;
  }

  void _buildIndex() {
    for (final cc in _byCategory.values) {
      for (final n in cc.names) {
        final words = n.split(' ');
        if (words.length > _maxWords) _maxWords = words.length;
        _stemIndex.putIfAbsent(stemPhrase(n), () => n);
      }
    }
  }

  CategoryCatalog of(StoreCategory c) =>
      _byCategory[c] ?? CategoryCatalog(sectionOf: const {}, related: const {}, names: const []);

  /// В какой категории магазина обычно продаётся товар (для «Другое» и голосового ввода).
  StoreCategory? categoryOf(String name) {
    final k = normalizeKey(name);
    for (final e in _byCategory.entries) {
      if (e.value.sectionOf.containsKey(k)) return e.key;
    }
    return null;
  }

  String? sectionFor(StoreCategory c, String name) => of(c).sectionOf[normalizeKey(name)];

  /// Автодополнение: сначала совпадения с начала слова, затем вхождения.
  List<String> search(StoreCategory c, String query, {int limit = 8}) {
    final q = normalizeKey(query);
    if (q.isEmpty) return const [];
    Iterable<String> pool = of(c).names;
    if (c == StoreCategory.other) pool = _byCategory.values.expand((x) => x.names).toSet();
    final starts = <String>[];
    final contains = <String>[];
    for (final n in pool) {
      final k = normalizeKey(n);
      if (k.startsWith(q) || k.split(' ').any((w) => w.startsWith(q))) {
        starts.add(n);
      } else if (k.contains(q)) {
        contains.add(n);
      }
    }
    return [...starts, ...contains].take(limit).toList();
  }

  // ---------- Lexicon (для разбора голосового/текстового ввода) ----------

  @override
  LexiconMatch? matchAt(List<String> words, int start) {
    for (var len = _maxWords; len >= 1; len--) {
      if (start + len > words.length) continue;
      final phrase = words.sublist(start, start + len).join(' ');
      final alias = _aliases[normalizeKey(phrase)];
      if (alias != null) return LexiconMatch(alias, len);
      final hit = _stemIndex[stemPhrase(phrase)];
      if (hit != null) return LexiconMatch(hit, len);
    }
    return null;
  }
}

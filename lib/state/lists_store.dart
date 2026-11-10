import 'package:flutter/foundation.dart';

import '../data/catalog.dart';
import '../data/list_repository.dart';
import '../models/list_item.dart';
import '../models/shop_list.dart';
import '../models/store_category.dart';
import '../services/input_parser.dart';

/// Состояние всех списков. Данные небольшие, поэтому держим их в памяти целиком
/// и синхронно отражаем изменения в SQLite.
class ListsStore extends ChangeNotifier {
  ListsStore(this.repo, this.catalog) : parser = InputParser(catalog);

  final ListRepository repo;
  final Catalog catalog;
  final InputParser parser;

  List<ShopList> _lists = [];
  bool loaded = false;

  List<ShopList> get lists => List.unmodifiable(_lists);

  ShopList? byId(int id) {
    for (final l in _lists) {
      if (l.id == id) return l;
    }
    return null;
  }

  Future<void> load() async {
    _lists = await repo.loadAll();
    loaded = true;
    notifyListeners();
  }

  void _touch(ShopList l) {
    l.updatedAt = DateTime.now();
    _lists
      ..remove(l)
      ..insert(0, l);
  }

  Future<ShopList> createList(StoreCategory category, {String? name}) async {
    final now = DateTime.now();
    final title = (name == null || name.trim().isEmpty) ? category.title : name.trim();
    final id = await repo.insertList(title, category, now);
    final list = ShopList(id: id, name: title, category: category, createdAt: now, updatedAt: now);
    _lists.insert(0, list);
    notifyListeners();
    return list;
  }

  Future<void> renameList(ShopList l, String name, StoreCategory category) async {
    l
      ..name = name.trim().isEmpty ? category.title : name.trim()
      ..category = category;
    _touch(l);
    await repo.updateList(l);
    notifyListeners();
  }

  Future<void> deleteList(ShopList l) async {
    _lists.remove(l);
    notifyListeners();
    await repo.deleteList(l.id);
  }

  /// Копия списка (например, «как в прошлый раз»), все галочки сняты.
  Future<ShopList> duplicate(ShopList src) async {
    final copy = await createList(src.category, name: '${src.name} (копия)');
    for (final i in src.items) {
      await _insert(copy, i.name, i.quantity, record: false);
    }
    notifyListeners();
    return copy;
  }

  /// Добавляет позиции из свободного текста/голоса. Возвращает добавленные позиции.
  Future<List<ListItem>> addFromText(ShopList list, String text) async {
    final parsed = parser.parse(text);
    final added = <ListItem>[];
    for (final p in parsed) {
      final item = await addItem(list, p.name, quantity: p.quantity, notify: false);
      if (item != null) added.add(item);
    }
    notifyListeners();
    return added;
  }

  Future<ListItem?> addItem(ShopList list, String name,
      {String quantity = '', bool fromSuggestion = false, bool notify = true}) async {
    final clean = capitalize(name.trim());
    if (clean.isEmpty) return null;
    final key = normalizeKey(clean);
    // Дубль: не плодим, а «оживляем» и обновляем количество.
    for (final i in list.items) {
      if (i.key == key) {
        var changed = false;
        if (i.checked) {
          i.checked = false;
          changed = true;
        }
        if (quantity.isNotEmpty && i.quantity != quantity) {
          i.quantity = quantity;
          changed = true;
        }
        if (changed) await repo.updateItem(i);
        if (notify) notifyListeners();
        return null;
      }
    }
    final item = await _insert(list, clean, quantity, fromSuggestion: fromSuggestion);
    _touch(list);
    await repo.updateList(list);
    if (notify) notifyListeners();
    return item;
  }

  Future<ListItem> _insert(ShopList list, String name, String quantity,
      {bool fromSuggestion = false, bool record = true}) async {
    final others = list.items.map((i) => i.name).toList();
    final pos = list.items.isEmpty ? 0 : list.items.map((i) => i.position).reduce((a, b) => a > b ? a : b) + 1;
    final id = await repo.insertItem(
        listId: list.id, name: name, quantity: quantity, position: pos, fromSuggestion: fromSuggestion);
    final item = ListItem(
        id: id, listId: list.id, name: name, quantity: quantity, position: pos, fromSuggestion: fromSuggestion);
    list.items.add(item);
    if (record) {
      // учим ассистента: этот товар покупают вместе с уже имеющимися
      await repo.recordPurchase(name, list.category, others);
    }
    return item;
  }

  Future<void> toggle(ShopList list, ListItem item) async {
    item.checked = !item.checked;
    notifyListeners();
    await repo.updateItem(item);
  }

  Future<void> updateItem(ShopList list, ListItem item, {required String name, required String quantity}) async {
    item
      ..name = capitalize(name.trim())
      ..quantity = quantity.trim();
    notifyListeners();
    await repo.updateItem(item);
  }

  Future<void> removeItem(ShopList list, ListItem item) async {
    list.items.remove(item);
    notifyListeners();
    await repo.deleteItem(item.id);
  }

  Future<void> restoreItem(ShopList list, ListItem item) async {
    await _insert(list, item.name, item.quantity, record: false);
    notifyListeners();
  }

  Future<void> reorder(ShopList list, int oldIndex, int newIndex) async {
    // newIndex уже скорректирован (onReorderItem)
    final items = [...list.items];
    final moved = items.removeAt(oldIndex);
    items.insert(newIndex, moved);
    for (var i = 0; i < items.length; i++) {
      items[i].position = i;
    }
    list.items
      ..clear()
      ..addAll(items);
    notifyListeners();
    await repo.updatePositions(items);
  }

  Future<void> uncheckAll(ShopList list) async {
    for (final i in list.items) {
      if (i.checked) {
        i.checked = false;
        await repo.updateItem(i);
      }
    }
    notifyListeners();
  }

  Future<void> removeChecked(ShopList list) async {
    final checked = list.items.where((i) => i.checked).toList();
    list.items.removeWhere((i) => i.checked);
    notifyListeners();
    for (final i in checked) {
      await repo.deleteItem(i.id);
    }
  }

  /// Подсказки для автодополнения: история пользователя + каталог.
  Future<List<String>> autocomplete(ShopList list, String query) async {
    final q = normalizeKey(query);
    if (q.isEmpty) return const [];
    final present = {...list.items.map((i) => i.key), ...await repo.hidden(list.category)};
    final hist = await repo.history(list.category, limit: 300);
    final fromHistory = hist.map((h) => h.name).where((n) => normalizeKey(n).contains(q));
    final fromCatalog = catalog.search(list.category, query, limit: 12);
    final seen = <String>{};
    return [...fromHistory, ...fromCatalog]
        .where((n) => !present.contains(normalizeKey(n)) && seen.add(normalizeKey(n)))
        .take(8)
        .toList();
  }

  /// «Частые» товары для быстрых чипов при пустом поле ввода.
  Future<List<String>> frequent(ShopList list, {int limit = 12}) async {
    final present = {...list.items.map((i) => i.key), ...await repo.hidden(list.category)};
    final hist = await repo.history(list.category, limit: 40);
    final names = hist.where((h) => !present.contains(normalizeKey(h.name))).map((h) => h.name).toList();
    if (names.length < limit) {
      // для новичка — популярное из каталога
      for (final n in catalog.of(list.category).sectionOf.keys.take(40)) {
        if (!present.contains(n) && !names.any((x) => normalizeKey(x) == n)) {
          names.add(_catalogName(list.category, n));
        }
        if (names.length >= limit) break;
      }
    }
    return names.take(limit).toList();
  }

  String _catalogName(StoreCategory c, String key) =>
      catalog.of(c).names.firstWhere((n) => normalizeKey(n) == key, orElse: () => capitalize(key));

  Future<void> clearMemory() => repo.clearMemory();

  Future<void> forgetSuggestion(ShopList list, String name) => repo.forget(name, list.category);
}

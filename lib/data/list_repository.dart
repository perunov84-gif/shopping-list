import 'package:sqflite/sqflite.dart';

import '../models/list_item.dart';
import '../models/shop_list.dart';
import '../models/store_category.dart';
import 'database.dart';

class HistoryEntry {
  HistoryEntry(this.name, this.count, this.lastUsed);
  final String name;
  final int count;
  final DateTime lastUsed;
}

/// Доступ к данным. Вся бизнес-логика — в [ListsStore], здесь только SQL.
class ListRepository {
  ListRepository(this._appDb);
  final AppDatabase _appDb;
  Database get _db => _appDb.db;

  Future<List<ShopList>> loadAll() async {
    final listRows = await _db.query('lists', orderBy: 'updated_at DESC');
    final itemRows = await _db.query('items', orderBy: 'position ASC, id ASC');
    final lists = listRows.map(ShopList.fromMap).toList();
    final byId = {for (final l in lists) l.id: l};
    for (final r in itemRows) {
      final item = ListItem.fromMap(r);
      byId[item.listId]?.items.add(item);
    }
    return lists;
  }

  Future<int> insertList(String name, StoreCategory category, DateTime now) => _db.insert('lists', {
        'name': name,
        'category': category.key,
        'created_at': now.millisecondsSinceEpoch,
        'updated_at': now.millisecondsSinceEpoch,
      });

  Future<void> updateList(ShopList list) =>
      _db.update('lists', list.toMap()..remove('id'), where: 'id = ?', whereArgs: [list.id]);

  Future<void> deleteList(int id) async {
    await _db.delete('items', where: 'list_id = ?', whereArgs: [id]);
    await _db.delete('lists', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertItem({
    required int listId,
    required String name,
    required String quantity,
    required int position,
    bool checked = false,
    bool fromSuggestion = false,
  }) =>
      _db.insert('items', {
        'list_id': listId,
        'name': name,
        'quantity': quantity,
        'checked': checked ? 1 : 0,
        'position': position,
        'from_suggestion': fromSuggestion ? 1 : 0,
      });

  Future<void> updateItem(ListItem item) =>
      _db.update('items', item.toMap()..remove('id'), where: 'id = ?', whereArgs: [item.id]);

  Future<void> deleteItem(int id) => _db.delete('items', where: 'id = ?', whereArgs: [id]);

  Future<void> updatePositions(List<ListItem> items) async {
    final batch = _db.batch();
    for (final i in items) {
      batch.update('items', {'position': i.position}, where: 'id = ?', whereArgs: [i.id]);
    }
    await batch.commit(noResult: true);
  }

  // ---------- Память ассистента ----------

  Future<void> recordPurchase(String name, StoreCategory category, Iterable<String> others) async {
    final key = normalizeKey(name);
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.delete('hidden', where: 'key = ? AND category = ?', whereArgs: [key, category.key]);
    await _db.rawInsert(
      'INSERT INTO history(key, category, name, count, last_used) VALUES(?, ?, ?, 1, ?) '
      'ON CONFLICT(key, category) DO UPDATE SET count = count + 1, last_used = excluded.last_used, name = excluded.name',
      [key, category.key, name, now],
    );
    final batch = _db.batch();
    for (final o in others) {
      final ok = normalizeKey(o);
      if (ok == key) continue;
      for (final pair in [
        [ok, key],
        [key, ok],
      ]) {
        batch.rawInsert(
          'INSERT INTO pairs(a, b, category, count) VALUES(?, ?, ?, 1) '
          'ON CONFLICT(a, b, category) DO UPDATE SET count = count + 1',
          [pair[0], pair[1], category.key],
        );
      }
    }
    await batch.commit(noResult: true);
  }

  Future<List<HistoryEntry>> history(StoreCategory category, {int limit = 200}) async {
    final rows = await _db.query('history',
        where: 'category = ?', whereArgs: [category.key], orderBy: 'count DESC, last_used DESC', limit: limit);
    return rows
        .map((r) => HistoryEntry(r['name'] as String, r['count'] as int,
            DateTime.fromMillisecondsSinceEpoch(r['last_used'] as int)))
        .toList();
  }

  /// Возвращает map: товар-кандидат -> сила связи с текущими позициями.
  Future<Map<String, int>> pairsFor(StoreCategory category, List<String> keys) async {
    if (keys.isEmpty) return {};
    final placeholders = List.filled(keys.length, '?').join(',');
    final rows = await _db.rawQuery(
      'SELECT b, SUM(count) AS c FROM pairs WHERE category = ? AND a IN ($placeholders) GROUP BY b',
      [category.key, ...keys],
    );
    return {for (final r in rows) r['b'] as String: (r['c'] as num).toInt()};
  }

  /// Убрать товар из подсказок (пользователь больше не хочет его видеть).
  Future<void> forget(String name, StoreCategory category) async {
    final key = normalizeKey(name);
    await _db.delete('history', where: 'key = ? AND category = ?', whereArgs: [key, category.key]);
    await _db.delete('pairs', where: '(a = ? OR b = ?) AND category = ?', whereArgs: [key, key, category.key]);
    await _db.insert('hidden', {'key': key, 'category': category.key}, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<Set<String>> hidden(StoreCategory category) async {
    final rows = await _db.query('hidden', where: 'category = ?', whereArgs: [category.key]);
    return rows.map((r) => r['key'] as String).toSet();
  }

  Future<void> clearMemory() async {
    await _db.delete('history');
    await _db.delete('pairs');
    await _db.delete('hidden');
  }
}

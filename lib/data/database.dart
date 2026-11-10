import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Локальная база (SQLite). Всё хранится на устройстве — приложение работает офлайн.
///
/// Таблицы:
///  * lists   — списки покупок
///  * items   — позиции списков
///  * history — что пользователь покупал (для автодополнения и «частых»)
///  * pairs   — что покупают вместе (обучаемая часть ассистента)
class AppDatabase {
  AppDatabase._(this.db);

  final Database db;
  static const _version = 2;

  static Future<AppDatabase> open({String? path}) async {
    final dbPath = path ?? p.join(await getDatabasesPath(), 'shopping_list.db');
    final db = await openDatabase(
      dbPath,
      version: _version,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE lists(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            category TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )''');
        await db.execute('''
          CREATE TABLE items(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            list_id INTEGER NOT NULL REFERENCES lists(id) ON DELETE CASCADE,
            name TEXT NOT NULL,
            quantity TEXT NOT NULL DEFAULT '',
            checked INTEGER NOT NULL DEFAULT 0,
            position INTEGER NOT NULL DEFAULT 0,
            from_suggestion INTEGER NOT NULL DEFAULT 0
          )''');
        await db.execute('CREATE INDEX idx_items_list ON items(list_id)');
        await db.execute('''
          CREATE TABLE history(
            key TEXT NOT NULL,
            category TEXT NOT NULL,
            name TEXT NOT NULL,
            count INTEGER NOT NULL DEFAULT 0,
            last_used INTEGER NOT NULL,
            PRIMARY KEY(key, category)
          )''');
        await db.execute('''
          CREATE TABLE pairs(
            a TEXT NOT NULL,
            b TEXT NOT NULL,
            category TEXT NOT NULL,
            count INTEGER NOT NULL DEFAULT 0,
            PRIMARY KEY(a, b, category)
          )''');
        await _createHidden(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) await _createHidden(db);
      },
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
    );
    return AppDatabase._(db);
  }

  /// v2: товары, которые пользователь убрал из подсказок.
  static Future<void> _createHidden(Database db) => db.execute('''
        CREATE TABLE IF NOT EXISTS hidden(
          key TEXT NOT NULL,
          category TEXT NOT NULL,
          PRIMARY KEY(key, category)
        )''');
}

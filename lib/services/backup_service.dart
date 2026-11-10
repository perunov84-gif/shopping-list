import 'dart:convert';
import 'dart:typed_data';

import '../models/store_category.dart';
import '../state/lists_store.dart';

/// Резервная копия всех списков в JSON (для переноса на новый телефон)
/// и импорт списка из текста, которым поделился другой человек.
class BackupService {
  BackupService(this.store);
  final ListsStore store;

  static const _format = 'shopping-list-backup';

  Uint8List exportJson() {
    final data = {
      'format': _format,
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'lists': [
        for (final l in store.lists)
          {
            'name': l.name,
            'category': l.category.key,
            'items': [
              for (final i in l.items) {'name': i.name, 'quantity': i.quantity, 'checked': i.checked},
            ],
          },
      ],
    };
    return Uint8List.fromList(utf8.encode(const JsonEncoder.withIndent(' ').convert(data)));
  }

  /// Возвращает число импортированных списков. Существующие списки не трогает.
  Future<int> importJson(Uint8List bytes) async {
    final data = jsonDecode(utf8.decode(bytes));
    if (data is! Map || data['format'] != _format) {
      throw const FormatException('Это не файл резервной копии «Список покупок»');
    }
    var count = 0;
    for (final l in (data['lists'] as List? ?? const [])) {
      if (l is! Map) continue;
      final list = await store.createList(StoreCategory.fromKey(l['category'] as String?), name: l['name'] as String?);
      for (final i in (l['items'] as List? ?? const [])) {
        if (i is! Map) continue;
        final item = await store.addItem(list, '${i['name'] ?? ''}', quantity: '${i['quantity'] ?? ''}', notify: false);
        if (item != null && i['checked'] == true) await store.toggle(list, item);
      }
      count++;
    }
    return count;
  }

  /// Текст из «Поделиться» (или любой столбик товаров) → новый список.
  /// Понимает формат «🛒 Название (Магазин)» + строки «☐ Молоко — 2 л».
  Future<int> importText(String text) async {
    final lines = text.split(RegExp(r'\r?\n')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (lines.isEmpty) return 0;
    var name = '';
    var category = StoreCategory.grocery;
    final header = RegExp(r'^🛒\s*(.+?)(?:\s*\(([^)]+)\))?$').firstMatch(lines.first);
    if (header != null) {
      name = header.group(1)!.trim();
      final catTitle = header.group(2);
      category = StoreCategory.values.firstWhere((c) => c.title == catTitle, orElse: () => StoreCategory.grocery);
      lines.removeAt(0);
    }
    final list = await store.createList(category, name: name);
    var count = 0;
    for (var line in lines) {
      final checked = line.startsWith('☑') || line.startsWith('✅') || line.startsWith('[x]');
      line = line.replaceFirst(RegExp(r'^(☑|☐|✅|⬜|\[x\]|\[ \]|[-•*]|\d+[.)])\s*'), '');
      if (line.isEmpty) continue;
      final parts = line.split(' — ');
      final item = await store.addItem(list, parts.first,
          quantity: parts.length > 1 ? parts.sublist(1).join(' — ') : '', notify: false);
      if (item != null) {
        count++;
        if (checked) await store.toggle(list, item);
      }
    }
    if (count == 0) await store.deleteList(list);
    return count;
  }
}


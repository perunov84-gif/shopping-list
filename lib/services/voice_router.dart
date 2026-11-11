import '../data/catalog.dart';
import '../models/list_item.dart';
import '../models/shop_list.dart';
import '../models/store_category.dart';
import '../state/lists_store.dart';

/// «Быстрая фраза» с главного экрана: «для ремонта гвозди и молоток, в аптеку пластырь».
/// Сам определяет магазин(ы) и раскладывает товары по подходящим спискам.
class VoiceRouter {
  VoiceRouter(this.store, this.catalog);
  final ListsStore store;
  final Catalog catalog;

  static const _keywords = <StoreCategory, List<String>>{
    StoreCategory.grocery: ['продукт', 'супермаркет', 'магнит', 'пят', 'ашан', 'перекрест', 'еда', 'еды', 'гипермаркет'],
    StoreCategory.hardware: ['строител', 'стройк', 'строймаг', 'леруа', 'петрович', 'ремонт', 'оби'],
    StoreCategory.household: ['хоз', 'бытов', 'химия', 'химию', 'химии'],
    StoreCategory.pharmacy: ['аптек', 'лекарств'],
    StoreCategory.pets: ['зоо', 'питом'],
    StoreCategory.kids: ['детск', 'ребен', 'ребён'],
    StoreCategory.electronics: ['электрон', 'днс', 'dns', 'мвидео', 'эльдорадо'],
    StoreCategory.garden: ['сад', 'дач', 'огород'],
  };

  static const _filler = {
    'в', 'во', 'на', 'для', 'магазин', 'магазине', 'магазина', 'купить', 'нужно', 'надо', 'добавь', 'добавить',
    'запиши', 'записать', 'список', 'мне', 'пожалуйста', 'хочу', 'взять', 'возьми',
  };

  StoreCategory? _detect(String word) {
    final w = normalizeKey(word);
    for (final e in _keywords.entries) {
      for (final k in e.value) {
        if (w.startsWith(k) && !(k.length <= 3 && w.length > k.length + 6)) return e.key;
      }
    }
    return null;
  }

  /// Возвращает: список -> сколько позиций добавлено.
  Future<Map<ShopList, int>> route(String phrase) async {
    final result = <ShopList, int>{};
    // Фразу можно разделить на части для разных магазинов: «… а в аптеку …».
    final segments = phrase.split(RegExp(r',?\s+(?=(?:а\s+)?(?:в|во)\s+\S)', caseSensitive: false));
    for (final seg in segments) {
      StoreCategory? detected;
      final kept = <String>[];
      for (final word in seg.split(RegExp(r'\s+'))) {
        final lw = normalizeKey(word);
        if (lw.isEmpty || lw == 'а') continue;
        final c = _detect(lw);
        if (c != null && detected == null && catalog.matchAt([lw], 0) == null) {
          detected = c;
          continue;
        }
        if (_filler.contains(lw) && kept.isEmpty) continue;
        kept.add(word);
      }
      final parsed = store.parser.parse(kept.join(' '));
      for (final p in parsed) {
        final cat = detected ?? catalog.categoryOf(p.name) ?? StoreCategory.grocery;
        final list = await _targetList(cat);
        final added = await store.addItem(list, p.name, quantity: p.quantity);
        if (added != null) result[list] = (result[list] ?? 0) + 1;
      }
    }
    return result;
  }

  Future<ShopList> _targetList(StoreCategory c) async {
    for (final l in store.lists) {
      if (l.category == c && !l.isDone) return l;
    }
    return store.createList(c);
  }
}

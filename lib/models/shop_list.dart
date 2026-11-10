import 'list_item.dart';
import 'store_category.dart';

class ShopList {
  ShopList({
    required this.id,
    required this.name,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
    this.shareId,
    List<ListItem>? items,
  }) : items = items ?? [];

  final int id;
  String name;
  StoreCategory category;
  final DateTime createdAt;
  DateTime updatedAt;

  /// Идентификатор для обмена ссылкой: одинаковый у отправителя и получателя,
  /// поэтому повторно присланный список обновляется, а не дублируется.
  String? shareId;
  final List<ListItem> items;

  int get total => items.length;
  int get checkedCount => items.where((i) => i.checked).length;
  bool get isDone => items.isNotEmpty && checkedCount == total;
  double get progress => total == 0 ? 0 : checkedCount / total;

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'category': category.key,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
        'share_id': shareId,
      };

  factory ShopList.fromMap(Map<String, Object?> m) => ShopList(
        id: m['id'] as int,
        name: m['name'] as String,
        category: StoreCategory.fromKey(m['category'] as String?),
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(m['updated_at'] as int),
        shareId: m['share_id'] as String?,
      );

  /// Текстовое представление для «Поделиться».
  String toShareText() {
    final b = StringBuffer('🛒 $name (${category.title})\n');
    for (final i in items) {
      b.writeln('${i.checked ? '☑' : '☐'} ${i.displayText}');
    }
    return b.toString().trimRight();
  }
}

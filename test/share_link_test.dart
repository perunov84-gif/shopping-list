import 'package:flutter_test/flutter_test.dart';
import 'package:shopping_list/models/list_item.dart';
import 'package:shopping_list/models/shop_list.dart';
import 'package:shopping_list/models/store_category.dart';
import 'package:shopping_list/services/share_link.dart';

void main() {
  test('round trip through https link', () {
    final now = DateTime.now();
    final list = ShopList(id: 1, name: 'Продукты на неделю', category: StoreCategory.grocery, createdAt: now, updatedAt: now)
      ..items.addAll([
        ListItem(id: 1, listId: 1, name: 'Молоко', quantity: '2 л'),
        ListItem(id: 2, listId: 1, name: 'Хлеб'),
        ListItem(id: 3, listId: 1, name: 'Уже куплено', checked: true),
      ]);
    final url = ShareLink.build(list, 'abc12345');
    expect(url.startsWith(ShareLink.webBase), isTrue);
    final parsed = ShareLink.parse(Uri.parse(url))!;
    expect(parsed.name, 'Продукты на неделю');
    expect(parsed.category, StoreCategory.grocery);
    expect(parsed.shareId, 'abc12345');
    expect(parsed.items.map((e) => e.name), ['Молоко', 'Хлеб']); // купленное не отправляем
    expect(parsed.items.first.quantity, '2 л');
  });

  test('custom scheme link', () {
    final now = DateTime.now();
    final list = ShopList(id: 1, name: 'Стройка', category: StoreCategory.hardware, createdAt: now, updatedAt: now)
      ..items.add(ListItem(id: 1, listId: 1, name: 'Гвозди'));
    final data = Uri.parse(ShareLink.build(list, 'x')).fragment;
    final parsed = ShareLink.parse(Uri.parse('shoppinglist://list?d=$data'))!;
    expect(parsed.items.single.name, 'Гвозди');
  });

  test('foreign links are ignored', () {
    expect(ShareLink.parse(Uri.parse('https://example.com/#zzz')), isNull);
    expect(ShareLink.parse(Uri.parse('shoppinglistpay://result')), isNull);
  });

  test('link stays short for a typical list', () {
    final now = DateTime.now();
    final list = ShopList(id: 1, name: 'Продукты', category: StoreCategory.grocery, createdAt: now, updatedAt: now);
    for (var i = 0; i < 25; i++) {
      list.items.add(ListItem(id: i, listId: 1, name: 'Товар номер $i', quantity: '$i шт'));
    }
    expect(ShareLink.build(list, 'abcdefgh').length, lessThan(1500));
  });
}

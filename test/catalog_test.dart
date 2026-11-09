import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shopping_list/data/catalog.dart';
import 'package:shopping_list/models/list_item.dart';
import 'package:shopping_list/models/store_category.dart';
import 'package:shopping_list/services/input_parser.dart';

void main() {
  late Catalog catalog;
  late InputParser parser;

  setUpAll(() {
    final json = jsonDecode(File('assets/data/catalog.json').readAsStringSync()) as Map<String, dynamic>;
    catalog = Catalog.fromJson(json);
    parser = InputParser(catalog);
  });

  test('assistant knows that nails need a hammer', () {
    final related = catalog.of(StoreCategory.hardware).related[normalizeKey('Гвозди')];
    expect(related, contains('Молоток'));
  });

  test('every category has items except "other"', () {
    for (final c in StoreCategory.values.where((c) => c != StoreCategory.other)) {
      expect(catalog.of(c).names, isNotEmpty, reason: c.title);
    }
  });

  test('category detection by product', () {
    expect(catalog.categoryOf('Молоко'), StoreCategory.grocery);
    expect(catalog.categoryOf('Шурупы'), StoreCategory.hardware);
    expect(catalog.categoryOf('Пластырь'), StoreCategory.pharmacy);
  });

  test('real voice phrase with catalog', () {
    final r = parser.parse('два литра молока хлеб и десяток яиц');
    expect(r.map((e) => e.name), ['Молоко', 'Хлеб', 'Яйца']);
    expect(r.first.quantity, '2 литра');
    expect(r.last.quantity, '10 шт');
  });

  test('hardware phrase', () {
    final r = parser.parse('гвозди, саморезы 2 упаковки и краску белую');
    expect(r.map((e) => e.name).take(2), ['Гвозди', 'Саморезы']);
    expect(r[1].quantity, '2 упаковки');
  });

  test('autocomplete', () {
    expect(catalog.search(StoreCategory.grocery, 'мол').first, 'Молоко');
  });
}

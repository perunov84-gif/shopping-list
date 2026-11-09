import 'package:flutter_test/flutter_test.dart';
import 'package:shopping_list/services/input_parser.dart';
import 'package:shopping_list/services/russian_stem.dart';

class FakeLexicon implements Lexicon {
  FakeLexicon(List<String> names) {
    for (final n in names) {
      _index[stemPhrase(n)] = n;
    }
  }
  final _index = <String, String>{};

  @override
  LexiconMatch? matchAt(List<String> words, int start) {
    for (var len = 2; len >= 1; len--) {
      if (start + len > words.length) continue;
      final hit = _index[stemPhrase(words.sublist(start, start + len).join(' '))];
      if (hit != null) return LexiconMatch(hit, len);
    }
    return null;
  }
}

void main() {
  final parser = InputParser(FakeLexicon(['Молоко', 'Хлеб', 'Гвозди', 'Молоток', 'Лук', 'Туалетная бумага', 'Сыр']));

  test('comma separated with quantities', () {
    expect(parser.parse('Молоко 2 л, хлеб'), [ParsedItem('Молоко', '2 л'), ParsedItem('Хлеб')]);
  });

  test('voice phrase without commas', () {
    expect(parser.parse('два литра молока хлеб и гвозди'),
        [ParsedItem('Молоко', '2 литра'), ParsedItem('Хлеб'), ParsedItem('Гвозди')]);
  });

  test('adjective is kept', () {
    expect(parser.parse('красный лук'), [ParsedItem('Красный лук')]);
  });

  test('unknown product becomes single item', () {
    expect(parser.parse('Корм для ежа'), [ParsedItem('Корм для ежа')]);
  });

  test('multi-word product', () {
    expect(parser.parse('туалетную бумагу 4 рулона'), [ParsedItem('Туалетная бумага', '4 рулона')]);
  });

  test('decimal comma is not a separator', () {
    expect(parser.parse('молоко 3,2%'), [ParsedItem('Молоко', '3,2%')]);
  });

  test('trailing details belong to previous product', () {
    expect(parser.parse('сыр российский 300 г'), [ParsedItem('Сыр российский', '300 г')]);
    expect(parser.parse('хлеб чёрный молоко'), [ParsedItem('Хлеб'), ParsedItem('Чёрный молоко')]);
  });

  test('stemmer', () {
    expect(stemWord('молока'), stemWord('Молоко'));
    expect(stemWord('гвоздей'), stemWord('гвозди'));
  });
}

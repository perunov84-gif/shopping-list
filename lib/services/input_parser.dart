import '../models/list_item.dart';

class LexiconMatch {
  LexiconMatch(this.canonical, this.wordCount);
  final String canonical;
  final int wordCount;
}

/// Источник известных названий товаров (реализует [Catalog]).
abstract class Lexicon {
  LexiconMatch? matchAt(List<String> words, int start);
}

class ParsedItem {
  ParsedItem(this.name, [this.quantity = '']);
  final String name;
  final String quantity;

  @override
  String toString() => quantity.isEmpty ? name : '$name ($quantity)';

  @override
  bool operator ==(Object other) => other is ParsedItem && other.name == name && other.quantity == quantity;

  @override
  int get hashCode => Object.hash(name, quantity);
}

/// Превращает фразу вроде «два литра молока, хлеб и десяток яиц»
/// в отдельные позиции с количеством. Работает и для набранного текста, и для голоса.
class InputParser {
  InputParser(this.lexicon);
  final Lexicon lexicon;

  static const _numberWords = {
    'один': '1', 'одна': '1', 'одну': '1', 'одно': '1', 'два': '2', 'две': '2', 'три': '3', 'четыре': '4',
    'пять': '5', 'шесть': '6', 'семь': '7', 'восемь': '8', 'девять': '9', 'десять': '10',
    'пара': '2', 'пару': '2', 'полтора': '1,5', 'полторы': '1,5', 'пол': '0,5', 'десяток': '10', 'дюжину': '12',
  };

  static const _unitPrefixes = [
    'кг', 'кило', 'грамм', 'гр', 'г', 'литр', 'л', 'мл', 'шт', 'штук', 'пачк', 'упаков', 'уп', 'бутыл',
    'банк', 'рулон', 'коробк', 'мешк', 'мешок', 'метр', 'м', 'пакет', 'десятк', 'бутылочк', 'тюбик', 'флакон', 'набор',
  ];

  static final _splitter = RegExp(r'(?<!\d),|,(?!\d)|;|\n|\s+и\s+|\s+а также\s+|\s+ещ[её]\s+|\s+плюс\s+', caseSensitive: false);
  static final _digits = RegExp(r'^\d+([.,]\d+)?(%)?$');
  static final _digitsWithUnit = RegExp(r'^(\d+(?:[.,]\d+)?)([а-яa-z]+)$', caseSensitive: false);

  List<ParsedItem> parse(String input) {
    final result = <ParsedItem>[];
    for (final rawChunk in input.split(_splitter)) {
      final chunk = rawChunk.trim();
      if (chunk.isEmpty) continue;
      result.addAll(_parseChunk(chunk));
    }
    // убираем дубли внутри одной фразы
    final seen = <String>{};
    return result.where((p) => seen.add(normalizeKey(p.name))).toList();
  }

  bool _isNumber(String w) => _digits.hasMatch(w) || _numberWords.containsKey(w);

  bool _isUnit(String w) {
    if (w.isEmpty) return false;
    for (final u in _unitPrefixes) {
      if (u.length <= 2 ? w == u || w == '$u.' : w.startsWith(u)) return true;
    }
    return false;
  }

  String _numberValue(String w) => _numberWords[w] ?? w;

  List<ParsedItem> _parseChunk(String chunk) {
    final words = chunk
        .split(RegExp(r'\s+'))
        .map((w) => w.replaceAll(RegExp(r'^[^\wа-яё\d%]+|[^\wа-яё\d%.]+$', caseSensitive: false), ''))
        .where((w) => w.isNotEmpty)
        .expand((w) {
          // «2кг» -> «2», «кг»
          final m = _digitsWithUnit.firstMatch(w);
          return m != null ? [m.group(1)!, m.group(2)!] : [w];
        })
        .toList();
    final lower = words.map((w) => w.toLowerCase()).toList();

    final items = <_Draft>[];
    var pendingQty = <String>[];
    final pendingWords = <String>[];
    var anyMatch = false;

    var i = 0;
    while (i < words.length) {
      final w = lower[i];
      final isNum = _isNumber(w);
      // единица измерения считается количеством только рядом с числом или как «пачку/бутылку»
      final isUnitHere = _isUnit(w) &&
          (isNum || (i > 0 && _isNumber(lower[i - 1])) || w.length > 2) &&
          lexicon.matchAt(lower, i) == null;
      if (isNum || isUnitHere) {
        final qty = <String>[];
        while (i < words.length &&
            (_isNumber(lower[i]) || (_isUnit(lower[i]) && lexicon.matchAt(lower, i) == null))) {
          qty.add(_isNumber(lower[i]) ? _numberValue(lower[i]) : lower[i]);
          i++;
        }
        final last = items.isNotEmpty ? items.last : null;
        if (last != null && last.qty.isEmpty && pendingWords.isEmpty) {
          last.qty = qty;
        } else {
          pendingQty = qty;
        }
        continue;
      }
      final match = lexicon.matchAt(lower, i);
      if (match != null) {
        anyMatch = true;
        final name = pendingWords.isEmpty
            ? match.canonical
            : capitalize('${pendingWords.join(' ').toLowerCase()} ${match.canonical.toLowerCase()}');
        items.add(_Draft(name, pendingQty));
        pendingQty = [];
        pendingWords.clear();
        i += match.wordCount;
        continue;
      }
      pendingWords.add(words[i]);
      i++;
    }

    if (!anyMatch) {
      // Незнакомый товар: вся фраза — одна позиция.
      final name = pendingWords.join(' ');
      if (name.isEmpty) return const [];
      return [ParsedItem(capitalize(name), _formatQty(pendingQty))];
    }
    if (pendingWords.isNotEmpty) {
      items.add(_Draft(capitalize(pendingWords.join(' ')), pendingQty));
    }
    return items.map((d) => ParsedItem(d.name, _formatQty(d.qty))).toList();
  }

  String _formatQty(List<String> parts) {
    if (parts.isEmpty) return '';
    final s = parts.join(' ');
    if (s == '10 десяток') return '10 шт';
    return s;
  }
}

class _Draft {
  _Draft(this.name, this.qty);
  final String name;
  List<String> qty;
}

import '../models/list_item.dart';

/// Очень лёгкий «стеммер» для русского: отрезает типичные окончания,
/// чтобы «молока», «молоко» и «молоком» считались одним товаром.
const _endings = [
  'ами', 'ями', 'ого', 'его', 'ому', 'ему', 'ыми', 'ими', 'иях', 'ией',
  'ах', 'ях', 'ов', 'ев', 'ей', 'ой', 'ий', 'ый', 'ая', 'яя', 'ое', 'ее', 'ую', 'юю', 'ам', 'ям', 'ом', 'ем', 'ые', 'ие',
  'а', 'я', 'о', 'е', 'у', 'ю', 'ы', 'и', 'ь', 'й',
];

String stemWord(String word) {
  final w = normalizeKey(word);
  if (w.length <= 3) return w;
  for (final e in _endings) {
    if (w.endsWith(e) && w.length - e.length >= 3) {
      return w.substring(0, w.length - e.length);
    }
  }
  return w;
}

String stemPhrase(String phrase) => normalizeKey(phrase).split(' ').map(stemWord).join(' ');

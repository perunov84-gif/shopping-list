class ListItem {
  ListItem({
    required this.id,
    required this.listId,
    required this.name,
    this.quantity = '',
    this.checked = false,
    this.position = 0,
    this.fromSuggestion = false,
  });

  final int id;
  final int listId;
  String name;
  String quantity;
  bool checked;
  int position;
  final bool fromSuggestion;

  String get displayText => quantity.isEmpty ? name : '$name — $quantity';

  /// Ключ для сравнения/поиска: нижний регистр, ё→е, без лишних пробелов.
  String get key => normalizeKey(name);

  Map<String, Object?> toMap() => {
        'id': id,
        'list_id': listId,
        'name': name,
        'quantity': quantity,
        'checked': checked ? 1 : 0,
        'position': position,
        'from_suggestion': fromSuggestion ? 1 : 0,
      };

  factory ListItem.fromMap(Map<String, Object?> m) => ListItem(
        id: m['id'] as int,
        listId: m['list_id'] as int,
        name: m['name'] as String,
        quantity: (m['quantity'] as String?) ?? '',
        checked: (m['checked'] as int? ?? 0) == 1,
        position: m['position'] as int? ?? 0,
        fromSuggestion: (m['from_suggestion'] as int? ?? 0) == 1,
      );
}

String normalizeKey(String s) =>
    s.toLowerCase().replaceAll('ё', 'е').replaceAll(RegExp(r'\s+'), ' ').trim();

String capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

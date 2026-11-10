import 'dart:convert';
import 'dart:io' show ZLibCodec;
import 'dart:math';

import '../models/shop_list.dart';
import '../models/store_category.dart';

/// Список внутри ссылки. Данные лежат прямо в ссылке (после «#»), сервер их не видит и не хранит.
///
/// Ссылка: https://perunov84-gif.github.io/shopping-list/s/#1.<данные>
///  * в мессенджере она кликабельна;
///  * страница сразу открывает приложение (а если его нет — показывает список в браузере
///    и предлагает установить приложение);
///  * приложение принимает и прямую схему shoppinglist://list?d=<данные>.
class SharedList {
  SharedList({required this.shareId, required this.name, required this.category, required this.items});

  final String shareId;
  final String name;
  final StoreCategory category;
  final List<SharedItem> items;
}

class SharedItem {
  SharedItem(this.name, this.quantity, this.checked);
  final String name;
  final String quantity;
  final bool checked;
}

class ShareLink {
  static const webBase = 'https://perunov84-gif.github.io/shopping-list/s/';
  static const scheme = 'shoppinglist';
  static final _zlib = ZLibCodec(raw: true, level: 9);

  static String newShareId() {
    final r = Random.secure();
    return List.generate(8, (_) => r.nextInt(36).toRadixString(36)).join();
  }

  /// Ссылка для отправки. [shareId] сохраняется у отправителя — при повторной отправке
  /// того же списка у получателя он обновится, а не задвоится.
  static String build(ShopList list, String shareId) {
    final payload = {
      'v': 1,
      'id': shareId,
      'n': list.name,
      'c': list.category.key,
      't': [
        for (final i in list.items.where((i) => !i.checked))
          [i.name, if (i.quantity.isNotEmpty) i.quantity],
      ],
    };
    return '$webBase#1.${encode(jsonEncode(payload))}';
  }

  static String encode(String json) =>
      base64Url.encode(_zlib.encode(utf8.encode(json))).replaceAll('=', '');

  static String decodeToJson(String data) {
    final padded = data.padRight((data.length + 3) ~/ 4 * 4, '=');
    return utf8.decode(_zlib.decode(base64Url.decode(padded)));
  }

  /// Разбирает любую из наших ссылок. Возвращает null, если это не ссылка на список.
  static SharedList? parse(Uri uri) {
    String? data;
    if (uri.scheme == scheme) {
      data = uri.queryParameters['d'];
    } else if (uri.scheme == 'https' && uri.path.contains('/shopping-list/s')) {
      data = uri.fragment;
    }
    if (data == null || data.isEmpty) return null;
    if (data.startsWith('1.')) data = data.substring(2);
    try {
      final m = jsonDecode(decodeToJson(data)) as Map<String, dynamic>;
      final items = <SharedItem>[];
      for (final t in (m['t'] as List? ?? const [])) {
        if (t is List && t.isNotEmpty) {
          items.add(SharedItem('${t[0]}', t.length > 1 ? '${t[1]}' : '', t.length > 2 && t[2] == 1));
        }
      }
      return SharedList(
        shareId: '${m['id'] ?? ''}',
        name: '${m['n'] ?? 'Список'}',
        category: StoreCategory.fromKey(m['c'] as String?),
        items: items,
      );
    } catch (_) {
      return null;
    }
  }
}

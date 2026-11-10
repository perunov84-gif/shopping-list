import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import '../state/lists_store.dart';
import '../ui/list_screen.dart';
import 'share_link.dart';

/// Принимает присланные ссылки: открывает приложение сразу на полученном списке.
class LinkHandler {
  LinkHandler(this.store, this.navigatorKey);

  final ListsStore store;
  final GlobalKey<NavigatorState> navigatorKey;
  final AppLinks _links = AppLinks();
  StreamSubscription<Uri>? _sub;
  String? _last;
  DateTime _lastAt = DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> init() async {
    _sub = _links.uriLinkStream.listen(_handle, onError: (_) {});
    try {
      final initial = await _links.getInitialLink();
      if (initial != null) await _handle(initial);
    } catch (_) {}
  }

  Future<void> _handle(Uri uri) async {
    // одна и та же ссылка может прийти и как «стартовая», и из потока
    final key = uri.toString();
    if (key == _last && DateTime.now().difference(_lastAt) < const Duration(seconds: 5)) return;
    _last = key;
    _lastAt = DateTime.now();

    final shared = ShareLink.parse(uri);
    if (shared == null) return;
    final list = await store.receiveShared(shared);
    final nav = navigatorKey.currentState;
    if (nav == null) return;
    nav.popUntil((r) => r.isFirst);
    unawaited(nav.push(MaterialPageRoute(
      builder: (_) => ListScreen(listId: list.id, initialShopMode: true, receivedNotice: true),
    )));
  }

  void dispose() => _sub?.cancel();
}

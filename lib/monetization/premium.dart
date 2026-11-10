import 'dart:async';

import 'package:flutter/foundation.dart';

import '../app_config.dart';
import '../state/settings_store.dart';
import 'purchase_backend.dart';
import 'purchase_backend_play.dart';
import 'purchase_backend_rustore.dart';

/// Статус VIP. VIP = разовая покупка: отключает рекламу навсегда.
class Premium extends ChangeNotifier {
  Premium(this._settings) : _isVip = _settings.vipCached {
    _backend = AppConfig.isRuStore ? RuStorePurchaseBackend() : PlayPurchaseBackend();
  }

  final SettingsStore _settings;
  late final PurchaseBackend _backend;
  bool _isVip;
  bool busy = false;
  String? price;
  String? lastError;

  bool get isVip => _isVip;
  bool get storeAvailable => _backend.available;

  Future<void> init() async {
    try {
      await _backend.init(onVipGranted: _grant);
      price = await _backend.vipPrice();
      final owned = await _backend.restore();
      if (owned) _grant();
    } catch (e) {
      debugPrint('Premium init failed: $e');
    }
    notifyListeners();
  }

  void _grant() {
    if (_isVip) return;
    _isVip = true;
    _settings.vipCached = true;
    busy = false;
    notifyListeners();
  }

  Future<void> buy() async {
    busy = true;
    lastError = null;
    notifyListeners();
    try {
      final r = await _backend.buy();
      if (r == PurchaseOutcome.success) _grant();
      if (r == PurchaseOutcome.error) lastError = 'Покупка не удалась. Попробуйте позже.';
    } catch (e) {
      lastError = 'Покупка не удалась: $e';
    }
    busy = false;
    notifyListeners();
  }

  Future<bool> restore() async {
    busy = true;
    notifyListeners();
    var ok = false;
    try {
      ok = await _backend.restore();
      if (ok) _grant();
    } catch (_) {}
    busy = false;
    notifyListeners();
    return ok;
  }

  /// Для отладки на тестовой сборке (скрытый пункт в настройках).
  void debugSetVip(bool v) {
    _isVip = v;
    _settings.vipCached = v;
    notifyListeners();
  }

  @override
  void dispose() {
    _backend.dispose();
    super.dispose();
  }
}

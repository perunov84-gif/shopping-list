import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsStore extends ChangeNotifier {
  SettingsStore(this._prefs) {
    launchCount = (_prefs.getInt('launch_count') ?? 0) + 1;
    _prefs.setInt('launch_count', launchCount);
  }

  final SharedPreferences _prefs;
  late final int launchCount;

  static Future<SettingsStore> load() async => SettingsStore(await SharedPreferences.getInstance());

  bool get suggestionsEnabled => _prefs.getBool('suggestions') ?? true;
  set suggestionsEnabled(bool v) {
    _prefs.setBool('suggestions', v);
    notifyListeners();
  }

  bool get onboardingDone => _prefs.getBool('onboarding_done') ?? false;
  set onboardingDone(bool v) {
    _prefs.setBool('onboarding_done', v);
    notifyListeners();
  }

  /// Кэш статуса VIP (источник правды — магазин, проверяется при запуске).
  bool get vipCached => _prefs.getBool('vip') ?? false;
  set vipCached(bool v) => _prefs.setBool('vip', v);

  DateTime? get lastInterstitial {
    final ms = _prefs.getInt('last_interstitial');
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  set lastInterstitial(DateTime? v) => v == null
      ? _prefs.remove('last_interstitial')
      : _prefs.setInt('last_interstitial', v.millisecondsSinceEpoch);
}

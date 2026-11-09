/// Конфигурация сборки. Всё задаётся через --dart-define при сборке, ничего секретного в коде.
///
///  STORE=rustore — RuStore / прямая установка: Яндекс Реклама + оплата через RuStore
///  STORE=gplay   — Google Play / App Store: AdMob + Google Play Billing / StoreKit
class AppConfig {
  static const store = String.fromEnvironment('STORE', defaultValue: 'gplay');
  static bool get isRuStore => store == 'rustore';

  /// Тестовая сборка (для проверки): включает скрытый переключатель VIP. В магазины — false.
  static const testBuild = bool.fromEnvironment('TEST_BUILD');

  /// ID разового продукта «VIP навсегда» (должен совпадать с консолью магазина).
  static const vipProductId = String.fromEnvironment('VIP_PRODUCT_ID', defaultValue: 'vip_forever');

  // ---- Реклама. По умолчанию — официальные тестовые/демо ID, безопасные для разработки. ----
  static const admobBannerId =
      String.fromEnvironment('ADMOB_BANNER_ID', defaultValue: 'ca-app-pub-3940256099942544/9214589741');
  static const admobInterstitialId =
      String.fromEnvironment('ADMOB_INTERSTITIAL_ID', defaultValue: 'ca-app-pub-3940256099942544/1033173712');
  static const yandexBannerId = String.fromEnvironment('YANDEX_BANNER_ID', defaultValue: 'demo-banner-yandex');
  static const yandexInterstitialId =
      String.fromEnvironment('YANDEX_INTERSTITIAL_ID', defaultValue: 'demo-interstitial-yandex');

  // ---- RuStore ----
  static const rustoreConsoleAppId = String.fromEnvironment('RUSTORE_APP_ID', defaultValue: '');
  static const rustoreDeeplinkScheme = 'shoppinglistpay';

  /// Политика показа межстраничной рекламы: не чаще раза в N минут и не в первые запуски.
  static const interstitialMinInterval = Duration(minutes: 4);
  static const interstitialSkipFirstLaunches = 2;

  static const privacyPolicyUrl = 'https://github.com/perunov84-gif/shopping-list/blob/main/docs/privacy-policy.md';
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' as gma;
import 'package:yandex_mobileads/mobile_ads.dart' as ya;

import '../app_config.dart';
import '../state/settings_store.dart';
import 'premium.dart';

/// Единая точка работы с рекламой. Сеть выбирается сборкой:
/// RuStore → Яндекс Реклама, Google Play/App Store → AdMob.
///
/// Принципы «ненавязчивости»:
///  * баннер только на главном экране и в режиме редактирования, НЕ в режиме магазина;
///  * межстраничная реклама — только после завершения покупок, не чаще раза в 4 минуты
///    и не в первые запуски;
///  * VIP полностью отключает рекламу.
class AdsService {
  AdsService(this._settings, this._premium);

  final SettingsStore _settings;
  final Premium _premium;
  bool _initialized = false;

  bool get enabled => !_premium.isVip;

  Future<void> init() async {
    if (_initialized || !enabled) return;
    try {
      if (AppConfig.isRuStore) {
        await ya.YandexAds.initialize();
      } else {
        await _requestAdMobConsent();
        await gma.MobileAds.instance.initialize();
      }
      _initialized = true;
      unawaited(_preloadInterstitial());
    } catch (e) {
      debugPrint('Ads init failed: $e');
    }
  }

  /// Согласие пользователя (GDPR/UMP) — требование Google для показа рекламы в ЕС/UK.
  Future<void> _requestAdMobConsent() {
    final done = Completer<void>();
    gma.ConsentInformation.instance.requestConsentInfoUpdate(
      gma.ConsentRequestParameters(),
      () async {
        gma.ConsentForm.loadAndShowConsentFormIfRequired((_) {
          if (!done.isCompleted) done.complete();
        });
      },
      (_) {
        if (!done.isCompleted) done.complete();
      },
    );
    return done.future.timeout(const Duration(seconds: 10), onTimeout: () {});
  }

  // ---------------- Interstitial ----------------
  gma.InterstitialAd? _gInterstitial;
  ya.InterstitialAd? _yInterstitial;
  final ya.InterstitialAdLoader _yLoader = ya.InterstitialAdLoader();

  Future<void> _preloadInterstitial() async {
    if (!enabled) return;
    if (AppConfig.isRuStore) {
      try {
        _yInterstitial = await _yLoader.loadAd(adRequest: const ya.AdRequest(adUnitId: AppConfig.yandexInterstitialId));
      } catch (_) {
        _yInterstitial = null;
      }
    } else {
      gma.InterstitialAd.load(
        adUnitId: AppConfig.admobInterstitialId,
        request: const gma.AdRequest(),
        adLoadCallback: gma.InterstitialAdLoadCallback(
          onAdLoaded: (ad) => _gInterstitial = ad,
          onAdFailedToLoad: (_) => _gInterstitial = null,
        ),
      );
    }
  }

  /// Вызывается в «естественных паузах» (список закрыт после покупок).
  Future<void> maybeShowInterstitial() async {
    if (!enabled || !_initialized) return;
    if (_settings.launchCount <= AppConfig.interstitialSkipFirstLaunches) return;
    final last = _settings.lastInterstitial;
    if (last != null && DateTime.now().difference(last) < AppConfig.interstitialMinInterval) return;

    if (AppConfig.isRuStore) {
      final ad = _yInterstitial;
      if (ad == null) {
        unawaited(_preloadInterstitial());
        return;
      }
      _yInterstitial = null;
      _settings.lastInterstitial = DateTime.now();
      try {
        await ad.setAdEventListener(eventListener: ya.InterstitialAdEventListener(onAdDismissed: ad.destroy));
        await ad.show();
      } catch (_) {}
    } else {
      final ad = _gInterstitial;
      if (ad == null) {
        unawaited(_preloadInterstitial());
        return;
      }
      _gInterstitial = null;
      _settings.lastInterstitial = DateTime.now();
      ad.fullScreenContentCallback = gma.FullScreenContentCallback(
        onAdDismissedFullScreenContent: (a) => a.dispose(),
        onAdFailedToShowFullScreenContent: (a, _) => a.dispose(),
      );
      await ad.show();
    }
    unawaited(_preloadInterstitial());
  }
}

/// Баннер внизу экрана. Сам скрывается, если у пользователя VIP или реклама не загрузилась.
class AdBanner extends StatefulWidget {
  const AdBanner({super.key, required this.premium});
  final Premium premium;

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  gma.BannerAd? _g;
  ya.BannerAd? _y;
  bool _loaded = false;
  bool _started = false;
  StreamSubscription<ya.BannerAdLoadState>? _ySub;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started && !widget.premium.isVip) {
      _started = true;
      _load();
    }
  }

  Future<void> _load() async {
    final width = MediaQuery.of(context).size.width.truncate();
    if (AppConfig.isRuStore) {
      final banner = ya.BannerAd(adSize: ya.BannerAdSize.sticky(width: width));
      _ySub = banner.loadStateStream.listen((s) {
        if (!mounted) return;
        if (s is ya.BannerAdLoadStateLoaded) setState(() => _loaded = true);
        if (s is ya.BannerAdLoadStateError) setState(() => _loaded = false);
      });
      setState(() => _y = banner);
      await banner.load(const ya.AdRequest(adUnitId: AppConfig.yandexBannerId));
    } else {
      final size = await gma.AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
      if (size == null || !mounted) return;
      final banner = gma.BannerAd(
        adUnitId: AppConfig.admobBannerId,
        size: size,
        request: const gma.AdRequest(),
        listener: gma.BannerAdListener(
          onAdLoaded: (_) {
            if (mounted) setState(() => _loaded = true);
          },
          onAdFailedToLoad: (ad, _) {
            ad.dispose();
            if (mounted) setState(() => _g = null);
          },
        ),
      );
      setState(() => _g = banner);
      await banner.load();
    }
  }

  @override
  void dispose() {
    _ySub?.cancel();
    _g?.dispose();
    _y?.destroy();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.premium.isVip) return const SizedBox.shrink();
    final g = _g;
    if (g != null) {
      if (!_loaded) return const SizedBox.shrink();
      return SafeArea(
        top: false,
        child: SizedBox(width: g.size.width.toDouble(), height: g.size.height.toDouble(), child: gma.AdWidget(ad: g)),
      );
    }
    final y = _y;
    if (y != null) {
      // Яндекс-виджет должен быть в дереве, чтобы загрузиться; до загрузки — нулевой высоты.
      return SafeArea(
        top: false,
        child: ya.AdWidget(bannerAd: y),
      );
    }
    return const SizedBox.shrink();
  }
}

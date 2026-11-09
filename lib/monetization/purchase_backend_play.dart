import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

import '../app_config.dart';
import 'purchase_backend.dart';

/// Google Play Billing (Android) и StoreKit (iOS) через официальный плагин in_app_purchase.
class PlayPurchaseBackend extends PurchaseBackend {
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  ProductDetails? _product;
  bool _available = false;
  void Function()? _onVip;
  Completer<bool>? _restoreCompleter;

  @override
  bool get available => _available;

  @override
  Future<void> init({required void Function() onVipGranted}) async {
    _onVip = onVipGranted;
    _available = await _iap.isAvailable();
    if (!_available) return;
    _sub = _iap.purchaseStream.listen(_onPurchases, onError: (_) {});
    final resp = await _iap.queryProductDetails({AppConfig.vipProductId});
    if (resp.productDetails.isNotEmpty) _product = resp.productDetails.first;
  }

  Future<void> _onPurchases(List<PurchaseDetails> list) async {
    for (final p in list) {
      if (p.productID != AppConfig.vipProductId) continue;
      if (p.status == PurchaseStatus.purchased || p.status == PurchaseStatus.restored) {
        _onVip?.call();
        final c = _restoreCompleter;
        if (c != null && !c.isCompleted) c.complete(true);
      }
      if (p.pendingCompletePurchase) await _iap.completePurchase(p);
    }
  }

  @override
  Future<String?> vipPrice() async => _product?.price;

  @override
  Future<PurchaseOutcome> buy() async {
    final product = _product;
    if (!_available || product == null) return PurchaseOutcome.error;
    final ok = await _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product));
    // Результат придёт в purchaseStream; здесь — лишь факт запуска покупки.
    return ok ? PurchaseOutcome.pending : PurchaseOutcome.error;
  }

  @override
  Future<bool> restore() async {
    if (!_available) return false;
    _restoreCompleter = Completer<bool>();
    await _iap.restorePurchases();
    return _restoreCompleter!.future.timeout(const Duration(seconds: 8), onTimeout: () => false);
  }

  @override
  void dispose() => _sub?.cancel();
}

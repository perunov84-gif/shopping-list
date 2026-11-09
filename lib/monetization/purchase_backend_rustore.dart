import 'package:flutter/foundation.dart';
import 'package:flutter_rustore_pay/api/flutter_rustore_pay_client.dart';
import 'package:flutter_rustore_pay/model/acknowledgement_state.dart';
import 'package:flutter_rustore_pay/model/product_type.dart';
import 'package:flutter_rustore_pay/model/purchase.dart';
import 'package:flutter_rustore_pay/model/purchase_availability.dart';

import '../app_config.dart';
import 'purchase_backend.dart';

/// Оплата VIP через RuStore Pay SDK (карты, СБП, SberPay).
///
/// Требования: приложение опубликовано в RuStore, в консоли подключена монетизация
/// и создан разовый продукт [AppConfig.vipProductId]; код приложения из консоли
/// передаётся в сборку секретом RUSTORE_APP_ID (попадает в AndroidManifest).
class RuStorePurchaseBackend extends PurchaseBackend {
  final RuStorePayClient _client = RuStorePayClient.instance;
  bool _available = false;
  String? _price;

  @override
  bool get available => _available;

  @override
  Future<void> init({required void Function() onVipGranted}) async {
    if (AppConfig.rustoreConsoleAppId.isEmpty) {
      // Сборка без кода приложения RuStore — оплата не настроена.
      _available = false;
      return;
    }
    try {
      final availability = await _client.purchaseInteractor.getPurchaseAvailability();
      _available = availability is Available;
      if (_available) {
        final products = await _client.productInteractor.getProducts([AppConfig.vipProductId]);
        if (products.isNotEmpty) _price = products.first.amountLabel;
      }
    } catch (e) {
      debugPrint('RuStore Pay unavailable: $e');
      _available = false;
    }
  }

  @override
  Future<String?> vipPrice() async => _price;

  @override
  Future<PurchaseOutcome> buy() async {
    if (!_available) return PurchaseOutcome.error;
    try {
      final result = await _client.purchaseInteractor.purchase(AppConfig.vipProductId);
      if (result.productId == AppConfig.vipProductId) {
        await _acknowledge(result.purchaseId);
        return PurchaseOutcome.success;
      }
      return PurchaseOutcome.error;
    } catch (e) {
      // Отмена пользователем тоже приходит исключением — не показываем это как ошибку.
      debugPrint('RuStore purchase: $e');
      return PurchaseOutcome.cancelled;
    }
  }

  Future<void> _acknowledge(String purchaseId) async {
    try {
      await _client.purchaseInteractor.updateAcknowledgementState(purchaseId, AcknowledgementState.acknowledged);
    } catch (_) {
      // для разовых покупок подтверждение не обязательно
    }
  }

  @override
  Future<bool> restore() async {
    if (!_available) return false;
    try {
      final purchases = await _client.purchaseInteractor.getPurchases(productType: ProductType.nonConsumable);
      for (final p in purchases) {
        if (p is ProductPurchase &&
            p.productId == AppConfig.vipProductId &&
            (p.status == ProductPurchaseStatus.confirmed || p.status == ProductPurchaseStatus.paid)) {
          if (p.acknowledgementState == AcknowledgementState.pending) await _acknowledge(p.purchaseId);
          return true;
        }
      }
    } catch (e) {
      debugPrint('RuStore restore: $e');
    }
    return false;
  }
}

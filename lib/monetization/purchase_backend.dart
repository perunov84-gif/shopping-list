enum PurchaseOutcome { success, pending, cancelled, error }

/// Абстракция над магазином приложений, чтобы одна кодовая база работала
/// и с Google Play / App Store, и с RuStore.
abstract class PurchaseBackend {
  bool get available;

  Future<void> init({required void Function() onVipGranted});

  /// Цена VIP в валюте пользователя (если магазин её отдал).
  Future<String?> vipPrice();

  Future<PurchaseOutcome> buy();

  /// true, если VIP уже куплен (восстановление после переустановки).
  Future<bool> restore();

  void dispose() {}
}

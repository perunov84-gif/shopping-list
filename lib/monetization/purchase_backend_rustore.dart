import 'purchase_backend.dart';

/// Оплата через RuStore.
///
/// ВРЕМЕННО: плагин flutter_rustore_billing 10.3.1 ссылается на нативный артефакт,
/// которого нет в Maven-репозитории RuStore, поэтому сборка с ним падает.
/// Реализация подключается отдельным коммитом после выбора рабочей версии SDK
/// (см. docs/monetization.md). Пока VIP в RuStore-сборке недоступен для покупки.
class RuStorePurchaseBackend extends PurchaseBackend {
  @override
  bool get available => false;

  @override
  Future<void> init({required void Function() onVipGranted}) async {}

  @override
  Future<String?> vipPrice() async => null;

  @override
  Future<PurchaseOutcome> buy() async => PurchaseOutcome.error;

  @override
  Future<bool> restore() async => false;
}

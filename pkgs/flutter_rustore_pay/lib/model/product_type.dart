import '../pigeons/flutter_rustore_pay_api.dart';

/// Тип продукта (потребляемый / непотребляемый).
enum ProductType {
  nonConsumable,
  consumable,
  subscription,
  undefined,
}

ProductType mapFlutterProductTypeToProductType(
    FlutterProductType? flutterPurchaseType) {
  return switch (flutterPurchaseType) {
    FlutterProductType.consumableProduct => ProductType.consumable,
    FlutterProductType.nonConsumableProduct => ProductType.nonConsumable,
    FlutterProductType.subscriptionProduct => ProductType.subscription,
    FlutterProductType.undefined => ProductType.undefined,
    null => ProductType.undefined,
  };
}

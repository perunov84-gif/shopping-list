import '../pigeons/flutter_rustore_pay_api.dart';

// Тип покупки (одностадийная / двустадийная).
enum PurchaseType {
  oneStep,
  twoStep,
  undefined,
}

PurchaseType mapFlutterPurchaseTypeToPurchaseType(
    FlutterPurchaseType? flutterPurchaseType) {
  return switch (flutterPurchaseType) {
    FlutterPurchaseType.oneStep => PurchaseType.oneStep,
    FlutterPurchaseType.twoStep => PurchaseType.twoStep,
    FlutterPurchaseType.undefined => PurchaseType.undefined,
    null => PurchaseType.undefined
  };
}
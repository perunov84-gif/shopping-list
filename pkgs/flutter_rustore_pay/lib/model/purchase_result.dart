import 'package:flutter_rustore_pay/model/product_type.dart';
import 'package:flutter_rustore_pay/model/purchase_type.dart';
import 'package:flutter_rustore_pay/pigeons/flutter_rustore_pay_api.dart';

/// Результат успешного завершения покупки цифрового товара. Имеет переопределенные методы equals(), hashcode(), toString().
final class ProductPurchaseResult {
  final String? orderId;
  final String purchaseId;
  final String productId;
  final String invoiceId;
  final PurchaseType purchaseType;
  final ProductType productType;
  final int quantity;
  final bool sandbox;

  ProductPurchaseResult._({
    this.orderId,
    required this.purchaseId,
    required this.productId,
    required this.invoiceId,
    required this.purchaseType,
    required this.productType,
    required this.quantity,
    required this.sandbox,
  });

  @override
  bool operator ==(covariant ProductPurchaseResult other) {
    if (identical(this, other)) return true;
    return other.orderId == orderId &&
        other.purchaseId == purchaseId &&
        other.productId == productId &&
        other.invoiceId == invoiceId &&
        other.purchaseType == purchaseType &&
        other.productType == productType &&
        other.quantity == quantity &&
        other.sandbox == sandbox;
  }

  @override
  int get hashCode {
    return orderId.hashCode ^
        purchaseId.hashCode ^
        productId.hashCode ^
        invoiceId.hashCode ^
        purchaseType.hashCode ^
        productType.hashCode ^
        quantity.hashCode ^
        sandbox.hashCode;
  }

  @override
  String toString() =>
      '$ProductPurchaseResult(orderId: $orderId, purchaseId: $purchaseId, productId: $productId, invoiceId: $invoiceId, purchaseType: $purchaseType, productType: $productType, quantity: $quantity, sandbox: $sandbox)';
}

ProductPurchaseResult mapFlutterPurchaseResultToPurchaseResult(
    FlutterProductPurchaseResult purchaseResult) {
  return ProductPurchaseResult._(
    orderId: purchaseResult.orderId,
    purchaseId: purchaseResult.purchaseId,
    productId: purchaseResult.productId,
    invoiceId: purchaseResult.invoiceId,
    purchaseType:
        mapFlutterPurchaseTypeToPurchaseType(purchaseResult.purchaseType),
    productType: mapFlutterProductTypeToProductType(purchaseResult.productType),
    quantity: purchaseResult.quantity,
    sandbox: purchaseResult.sandbox,
  );
}

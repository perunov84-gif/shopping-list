import 'package:flutter_rustore_pay/model/product_subscription_info.dart';
import 'package:flutter_rustore_pay/model/product_type.dart';
import 'package:flutter_rustore_pay/model/promotion_info.dart';
import 'package:flutter_rustore_pay/pigeons/flutter_rustore_pay_api.dart';

/// Модель продукта. Имеет переопределенные методы equals(), hashcode(), toString().
final class Product {
  final String productId;
  final ProductType type;
  final String amountLabel;
  final int? price;
  final String currency;
  final String imageUrl;
  final String title;
  final String? description;
  final SubscriptionInfo? subscriptionInfo;

  /// Информация об акции, применённой к продукту.
  final PromotionInfo? promotionInfo;

  Product._({
    required this.productId,
    required this.type,
    required this.amountLabel,
    this.price,
    required this.currency,
    required this.imageUrl,
    required this.title,
    this.description,
    this.subscriptionInfo,
    this.promotionInfo,
  });

  @override
  bool operator ==(covariant Product other) {
    if (identical(this, other)) return true;
    return other.productId == productId &&
        other.type == type &&
        other.amountLabel == amountLabel &&
        other.price == price &&
        other.currency == currency &&
        other.imageUrl == imageUrl &&
        other.title == title &&
        other.description == description &&
        other.subscriptionInfo == subscriptionInfo &&
        other.promotionInfo == promotionInfo;
  }

  @override
  int get hashCode {
    return productId.hashCode ^
        type.hashCode ^
        amountLabel.hashCode ^
        price.hashCode ^
        currency.hashCode ^
        imageUrl.hashCode ^
        title.hashCode ^
        description.hashCode ^
        subscriptionInfo.hashCode ^
        promotionInfo.hashCode;
  }

  @override
  String toString() =>
      '$Product(productId: $productId, type: $type, amountLabel: $amountLabel, price: $price, currency: $currency, imageUrl: $imageUrl, title: $title, description: $description, subscriptionInfo: $subscriptionInfo, promotionInfo: $promotionInfo)';
}

Product mapFlutterProductToProduct(FlutterProduct flutterProduct) {
  return Product._(
    productId: flutterProduct.productId,
    type: mapFlutterProductTypeToProductType(flutterProduct.type),
    amountLabel: flutterProduct.amountLabel,
    price: flutterProduct.price,
    currency: flutterProduct.currency,
    imageUrl: flutterProduct.imageUrl,
    title: flutterProduct.title,
    description: flutterProduct.description,
    subscriptionInfo: mapFlutterSubscriptionInfoToSubscriptionInfo(
        flutterProduct.subscriptionInfo),
    promotionInfo:
        mapFlutterPromotionInfoToPromotionInfo(flutterProduct.promotionInfo),
  );
}

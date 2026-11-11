import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter_rustore_pay/pigeons/flutter_rustore_pay_api.dart';

/// Модель информации о скидках, применённых к покупке.
final class PurchaseDiscount {
  /// Цена без скидок в минимальных единицах валюты.
  final int basePrice;

  /// Список применённых скидок.
  final List<PurchaseDiscountItem> discounts;

  PurchaseDiscount._({
    required this.basePrice,
    required this.discounts,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PurchaseDiscount &&
        other.basePrice == basePrice &&
        listEquals(other.discounts, discounts);
  }

  @override
  int get hashCode => basePrice.hashCode ^ Object.hashAll(discounts);

  @override
  String toString() =>
      'PurchaseDiscount(basePrice: $basePrice, discounts: $discounts)';
}

/// Абстрактный класс скидки, применённой к покупке.
sealed class PurchaseDiscountItem {
  /// Размер скидки в минимальных единицах валюты.
  int get discountValue;
}

/// Скидка по акции.
final class PromotionDiscount implements PurchaseDiscountItem {
  @override
  final int discountValue;

  /// Код акции.
  final String code;

  PromotionDiscount._({
    required this.discountValue,
    required this.code,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PromotionDiscount &&
        other.discountValue == discountValue &&
        other.code == code;
  }

  @override
  int get hashCode => discountValue.hashCode ^ code.hashCode;

  @override
  String toString() =>
      'PromotionDiscount(discountValue: $discountValue, code: $code)';
}

/// Скидка по купону.
final class CouponDiscount implements PurchaseDiscountItem {
  @override
  final int discountValue;

  CouponDiscount._({required this.discountValue});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CouponDiscount && other.discountValue == discountValue;
  }

  @override
  int get hashCode => discountValue.hashCode;

  @override
  String toString() => 'CouponDiscount(discountValue: $discountValue)';
}

/// Скидка неизвестного типа.
final class UnknownDiscount implements PurchaseDiscountItem {
  @override
  final int discountValue;

  UnknownDiscount._({required this.discountValue});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UnknownDiscount && other.discountValue == discountValue;
  }

  @override
  int get hashCode => discountValue.hashCode;

  @override
  String toString() => 'UnknownDiscount(discountValue: $discountValue)';
}

PurchaseDiscount? mapFlutterPurchaseDiscountToPurchaseDiscount(
    FlutterPurchaseDiscount? flutterPurchaseDiscount) {
  if (flutterPurchaseDiscount == null) return null;

  return PurchaseDiscount._(
    basePrice: flutterPurchaseDiscount.basePrice,
    discounts: flutterPurchaseDiscount.discounts
        .map(mapFlutterPurchaseDiscountItemToPurchaseDiscountItem)
        .toList(),
  );
}

PurchaseDiscountItem mapFlutterPurchaseDiscountItemToPurchaseDiscountItem(
    FlutterPurchaseDiscountItemWrapper flutterDiscountItem) {
  final promotionDiscount = flutterDiscountItem.promotionDiscount;
  if (promotionDiscount != null) {
    return PromotionDiscount._(
      discountValue: promotionDiscount.discountValue,
      code: promotionDiscount.code,
    );
  }

  final couponDiscount = flutterDiscountItem.couponDiscount;
  if (couponDiscount != null) {
    return CouponDiscount._(discountValue: couponDiscount.discountValue);
  }

  final unknownDiscount = flutterDiscountItem.unknownDiscount;
  if (unknownDiscount != null) {
    return UnknownDiscount._(discountValue: unknownDiscount.discountValue);
  }

  throw UnsupportedError('Unknown purchase discount type');
}
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter_rustore_pay/pigeons/flutter_rustore_pay_api.dart';

/// Модель акции приложения.
final class Promotion {
  /// Код акции.
  final String code;

  /// Название акции.
  final String name;

  /// Тип скидки по акции.
  final PromotionDiscountType discountType;

  /// Статус акции.
  final PromotionStatus status;

  /// Дата начала акции в формате ISO 8601 (UTC).
  final String startDate;

  /// Дата окончания акции в формате ISO 8601 (UTC) (может быть null).
  final String? endDate;

  /// Список идентификаторов продуктов, участвующих в акции (может быть null —
  /// тогда акция распространяется на все продукты). Содержится только в акции,
  /// полученной по коду; в списке всех акций всегда null.
  final List<String>? productCodes;

  Promotion._({
    required this.code,
    required this.name,
    required this.discountType,
    required this.status,
    required this.startDate,
    this.endDate,
    this.productCodes,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Promotion &&
        other.code == code &&
        other.name == name &&
        other.discountType == discountType &&
        other.status == status &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        listEquals(other.productCodes, productCodes);
  }

  @override
  int get hashCode {
    return code.hashCode ^
        name.hashCode ^
        discountType.hashCode ^
        status.hashCode ^
        startDate.hashCode ^
        endDate.hashCode ^
        (productCodes == null ? null.hashCode : Object.hashAll(productCodes!));
  }

  @override
  String toString() =>
      'Promotion(code: $code, name: $name, discountType: $discountType, status: $status, startDate: $startDate, endDate: $endDate, productCodes: $productCodes)';
}

/// Возможные статусы акции.
enum PromotionStatus {
  /// Активная.
  active,

  /// Запланированная.
  scheduled,
}

/// Абстрактный класс типа скидки по акции.
sealed class PromotionDiscountType {}

/// Скидка в процентах.
final class PercentDiscount implements PromotionDiscountType {
  /// Размер скидки в процентах.
  final int percents;

  PercentDiscount._({required this.percents});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PercentDiscount && other.percents == percents;
  }

  @override
  int get hashCode => percents.hashCode;

  @override
  String toString() => 'PercentDiscount(percents: $percents)';
}

/// Цена товара по акции.
final class PromoCost implements PromotionDiscountType {
  /// Цена в минимальных единицах (копейках).
  final int value;

  /// Код валюты ISO 4217.
  final String currency;

  PromoCost._({required this.value, required this.currency});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PromoCost &&
        other.value == value &&
        other.currency == currency;
  }

  @override
  int get hashCode => value.hashCode ^ currency.hashCode;

  @override
  String toString() => 'PromoCost(value: $value, currency: $currency)';
}

Promotion mapFlutterPromotionToPromotion(FlutterPromotion flutterPromotion) {
  return Promotion._(
    code: flutterPromotion.code,
    name: flutterPromotion.name,
    discountType: mapFlutterPromotionDiscountTypeToPromotionDiscountType(
        flutterPromotion.discountType),
    status: mapFlutterPromotionStatusToPromotionStatus(flutterPromotion.status),
    startDate: flutterPromotion.startDate,
    endDate: flutterPromotion.endDate,
    productCodes: flutterPromotion.productCodes,
  );
}

PromotionStatus mapFlutterPromotionStatusToPromotionStatus(
    FlutterPromotionStatus flutterPromotionStatus) {
  return switch (flutterPromotionStatus) {
    FlutterPromotionStatus.active => PromotionStatus.active,
    FlutterPromotionStatus.scheduled => PromotionStatus.scheduled,
  };
}

PromotionDiscountType mapFlutterPromotionDiscountTypeToPromotionDiscountType(
    FlutterPromotionDiscountTypeWrapper flutterDiscountType) {
  final percentDiscount = flutterDiscountType.percentDiscount;
  if (percentDiscount != null) {
    return PercentDiscount._(percents: percentDiscount.percents);
  }

  final promoCost = flutterDiscountType.promoCost;
  if (promoCost != null) {
    return PromoCost._(value: promoCost.value, currency: promoCost.currency);
  }

  throw UnsupportedError('Unknown promotion discount type');
}
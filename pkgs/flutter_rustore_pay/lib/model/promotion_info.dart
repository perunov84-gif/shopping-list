import 'package:flutter_rustore_pay/pigeons/flutter_rustore_pay_api.dart';

/// Модель информации об акции, применённой к продукту.
final class PromotionInfo {
  /// Код акции.
  final String code;

  /// Название акции.
  final String name;

  /// Тип акции.
  final PromotionType type;

  /// Цена продукта без скидки в минимальных единицах валюты.
  final int basePrice;

  /// Размер скидки в минимальных единицах валюты.
  final int discountValue;

  /// Отформатированный размер скидки с обозначением валюты.
  final String discountValueLabel;

  /// Дата начала акции в формате ISO 8601 (UTC).
  final String startDate;

  /// Дата окончания акции в формате ISO 8601 (UTC).
  final String? endDate;

  PromotionInfo._({
    required this.code,
    required this.name,
    required this.type,
    required this.basePrice,
    required this.discountValue,
    required this.discountValueLabel,
    required this.startDate,
    this.endDate,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PromotionInfo &&
        other.code == code &&
        other.name == name &&
        other.type == type &&
        other.basePrice == basePrice &&
        other.discountValue == discountValue &&
        other.discountValueLabel == discountValueLabel &&
        other.startDate == startDate &&
        other.endDate == endDate;
  }

  @override
  int get hashCode {
    return code.hashCode ^
        name.hashCode ^
        type.hashCode ^
        basePrice.hashCode ^
        discountValue.hashCode ^
        discountValueLabel.hashCode ^
        startDate.hashCode ^
        endDate.hashCode;
  }

  @override
  String toString() =>
      'PromotionInfo(code: $code, name: $name, type: $type, basePrice: $basePrice, discountValue: $discountValue, discountValueLabel: $discountValueLabel, startDate: $startDate, endDate: $endDate)';
}

/// Возможные типы акции.
enum PromotionType {
  /// Скидка в процентах.
  percentDiscount,

  /// Фиксированная цена продукта по акции.
  promoCost,
}

PromotionInfo? mapFlutterPromotionInfoToPromotionInfo(
    FlutterPromotionInfo? flutterPromotionInfo) {
  if (flutterPromotionInfo == null) return null;

  return PromotionInfo._(
    code: flutterPromotionInfo.code,
    name: flutterPromotionInfo.name,
    type: mapFlutterPromotionTypeToPromotionType(flutterPromotionInfo.type),
    basePrice: flutterPromotionInfo.basePrice,
    discountValue: flutterPromotionInfo.discountValue,
    discountValueLabel: flutterPromotionInfo.discountValueLabel,
    startDate: flutterPromotionInfo.startDate,
    endDate: flutterPromotionInfo.endDate,
  );
}

PromotionType mapFlutterPromotionTypeToPromotionType(
    FlutterPromotionType flutterPromotionType) {
  return switch (flutterPromotionType) {
    FlutterPromotionType.percentDiscount => PromotionType.percentDiscount,
    FlutterPromotionType.promoCost => PromotionType.promoCost,
  };
}
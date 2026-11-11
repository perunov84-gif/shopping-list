import 'package:flutter_rustore_pay/model/date_interval.dart';
import 'package:flutter_rustore_pay/pigeons/flutter_rustore_pay_api.dart';

/// Модель генератора купонов приложения.
final class CouponGenerator {
  /// Ссылка для активации купона.
  final String deepLink;

  /// Период действия ссылки.
  final DateInterval deepLinkDateInterval;

  /// Название купона.
  final String couponName;

  /// Продукты, к которым применим купон.
  final CouponProductScope couponProductScope;

  /// Признак применения купона только к первой покупке.
  final bool firstPurchaseOnly;

  /// Краткое описание купона.
  final String couponShortDescription;

  /// Полное описание купона.
  final String couponFullDescription;

  /// Описание купона от разработчика.
  final String? couponDeveloperDescription;

  /// Тип периода действия купона.
  final IntervalCouponType intervalCouponType;

  /// Номинал купона в минимальных единицах валюты.
  final int couponNominal;

  /// Максимальное количество купонов.
  final int couponMaxQuantity;

  /// Минимальная цена продукта в минимальных единицах валюты.
  final int? minProductPrice;

  CouponGenerator._({
    required this.deepLink,
    required this.deepLinkDateInterval,
    required this.couponName,
    required this.couponProductScope,
    required this.firstPurchaseOnly,
    required this.couponShortDescription,
    required this.couponFullDescription,
    this.couponDeveloperDescription,
    required this.intervalCouponType,
    required this.couponNominal,
    required this.couponMaxQuantity,
    this.minProductPrice,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CouponGenerator &&
        other.deepLink == deepLink &&
        other.deepLinkDateInterval == deepLinkDateInterval &&
        other.couponName == couponName &&
        other.couponProductScope == couponProductScope &&
        other.firstPurchaseOnly == firstPurchaseOnly &&
        other.couponShortDescription == couponShortDescription &&
        other.couponFullDescription == couponFullDescription &&
        other.couponDeveloperDescription == couponDeveloperDescription &&
        other.intervalCouponType == intervalCouponType &&
        other.couponNominal == couponNominal &&
        other.couponMaxQuantity == couponMaxQuantity &&
        other.minProductPrice == minProductPrice;
  }

  @override
  int get hashCode {
    return deepLink.hashCode ^
        deepLinkDateInterval.hashCode ^
        couponName.hashCode ^
        couponProductScope.hashCode ^
        firstPurchaseOnly.hashCode ^
        couponShortDescription.hashCode ^
        couponFullDescription.hashCode ^
        couponDeveloperDescription.hashCode ^
        intervalCouponType.hashCode ^
        couponNominal.hashCode ^
        couponMaxQuantity.hashCode ^
        minProductPrice.hashCode;
  }

  @override
  String toString() =>
      'CouponGenerator(deepLink: $deepLink, deepLinkDateInterval: $deepLinkDateInterval, couponName: $couponName, couponProductScope: $couponProductScope, firstPurchaseOnly: $firstPurchaseOnly, couponShortDescription: $couponShortDescription, couponFullDescription: $couponFullDescription, couponDeveloperDescription: $couponDeveloperDescription, intervalCouponType: $intervalCouponType, couponNominal: $couponNominal, couponMaxQuantity: $couponMaxQuantity, minProductPrice: $minProductPrice)';
}

/// Модель информации о купоне пользователя.
final class UserCouponInfo {
  /// Ссылка для активации купона.
  final String deepLink;

  /// Период действия ссылки.
  final DateInterval deepLinkDateInterval;

  /// Идентификатор купона.
  final String? couponId;

  /// Название купона.
  final String couponName;

  /// Период действия купона пользователя.
  final DateInterval? couponDateInterval;

  /// Статус купона пользователя.
  final CouponUserStatus couponUserStatus;

  /// Продукты, к которым применим купон.
  final CouponProductScope couponProductScope;

  /// Признак применения купона только к первой покупке.
  final bool firstPurchaseOnly;

  /// Краткое описание купона.
  final String couponShortDescription;

  /// Полное описание купона.
  final String couponFullDescription;

  /// Описание купона от разработчика.
  final String? couponDeveloperDescription;

  /// Тип периода действия купона.
  final IntervalCouponType intervalCouponType;

  /// Номинал купона в минимальных единицах валюты.
  final int couponNominal;

  /// Максимальное количество купонов.
  final int couponMaxQuantity;

  /// Минимальная цена продукта в минимальных единицах валюты.
  final int? minProductPrice;

  UserCouponInfo._({
    required this.deepLink,
    required this.deepLinkDateInterval,
    this.couponId,
    required this.couponName,
    this.couponDateInterval,
    required this.couponUserStatus,
    required this.couponProductScope,
    required this.firstPurchaseOnly,
    required this.couponShortDescription,
    required this.couponFullDescription,
    this.couponDeveloperDescription,
    required this.intervalCouponType,
    required this.couponNominal,
    required this.couponMaxQuantity,
    this.minProductPrice,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserCouponInfo &&
        other.deepLink == deepLink &&
        other.deepLinkDateInterval == deepLinkDateInterval &&
        other.couponId == couponId &&
        other.couponName == couponName &&
        other.couponDateInterval == couponDateInterval &&
        other.couponUserStatus == couponUserStatus &&
        other.couponProductScope == couponProductScope &&
        other.firstPurchaseOnly == firstPurchaseOnly &&
        other.couponShortDescription == couponShortDescription &&
        other.couponFullDescription == couponFullDescription &&
        other.couponDeveloperDescription == couponDeveloperDescription &&
        other.intervalCouponType == intervalCouponType &&
        other.couponNominal == couponNominal &&
        other.couponMaxQuantity == couponMaxQuantity &&
        other.minProductPrice == minProductPrice;
  }

  @override
  int get hashCode {
    return deepLink.hashCode ^
        deepLinkDateInterval.hashCode ^
        couponId.hashCode ^
        couponName.hashCode ^
        couponDateInterval.hashCode ^
        couponUserStatus.hashCode ^
        couponProductScope.hashCode ^
        firstPurchaseOnly.hashCode ^
        couponShortDescription.hashCode ^
        couponFullDescription.hashCode ^
        couponDeveloperDescription.hashCode ^
        intervalCouponType.hashCode ^
        couponNominal.hashCode ^
        couponMaxQuantity.hashCode ^
        minProductPrice.hashCode;
  }

  @override
  String toString() =>
      'UserCouponInfo(deepLink: $deepLink, deepLinkDateInterval: $deepLinkDateInterval, couponId: $couponId, couponName: $couponName, couponDateInterval: $couponDateInterval, couponUserStatus: $couponUserStatus, couponProductScope: $couponProductScope, firstPurchaseOnly: $firstPurchaseOnly, couponShortDescription: $couponShortDescription, couponFullDescription: $couponFullDescription, couponDeveloperDescription: $couponDeveloperDescription, intervalCouponType: $intervalCouponType, couponNominal: $couponNominal, couponMaxQuantity: $couponMaxQuantity, minProductPrice: $minProductPrice)';
}

/// Область применения купона.
enum CouponProductScope {
  /// Все продукты.
  allProducts,

  /// Потребляемые продукты.
  consumableProducts,

  /// Непотребляемые продукты.
  nonConsumableProducts,
}

/// Возможные статусы купона пользователя.
enum CouponUserStatus {
  /// Активен.
  active,

  /// Истёк срок действия.
  expired,

  /// Использован.
  redeemed,

  /// Не активирован.
  notActivated,
}

/// Абстрактный класс типа периода действия купона.
sealed class IntervalCouponType {}

/// Фиксированный период действия купона.
final class Fixed implements IntervalCouponType {
  Fixed._();

  @override
  bool operator ==(Object other) => other is Fixed;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'Fixed()';
}

/// Период действия купона относительно момента активации.
final class Relative implements IntervalCouponType {
  /// Продолжительность действия купона.
  final int duration;

  Relative._({required this.duration});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Relative && other.duration == duration;
  }

  @override
  int get hashCode => duration.hashCode;

  @override
  String toString() => 'Relative(duration: $duration)';
}

CouponGenerator mapFlutterCouponGeneratorToCouponGenerator(
    FlutterCouponGenerator flutterCouponGenerator) {
  return CouponGenerator._(
    deepLink: flutterCouponGenerator.deepLink,
    deepLinkDateInterval: mapFlutterDateIntervalToDateInterval(
        flutterCouponGenerator.deepLinkDateInterval),
    couponName: flutterCouponGenerator.couponName,
    couponProductScope: mapFlutterCouponProductScopeToCouponProductScope(
        flutterCouponGenerator.couponProductScope),
    firstPurchaseOnly: flutterCouponGenerator.firstPurchaseOnly,
    couponShortDescription: flutterCouponGenerator.couponShortDescription,
    couponFullDescription: flutterCouponGenerator.couponFullDescription,
    couponDeveloperDescription:
        flutterCouponGenerator.couponDeveloperDescription,
    intervalCouponType: mapFlutterIntervalCouponTypeToIntervalCouponType(
        flutterCouponGenerator.intervalCouponType),
    couponNominal: flutterCouponGenerator.couponNominal,
    couponMaxQuantity: flutterCouponGenerator.couponMaxQuantity,
    minProductPrice: flutterCouponGenerator.minProductPrice,
  );
}

UserCouponInfo mapFlutterUserCouponInfoToUserCouponInfo(
    FlutterUserCouponInfo flutterUserCouponInfo) {
  final couponDateInterval = flutterUserCouponInfo.couponDateInterval;
  return UserCouponInfo._(
    deepLink: flutterUserCouponInfo.deepLink,
    deepLinkDateInterval: mapFlutterDateIntervalToDateInterval(
        flutterUserCouponInfo.deepLinkDateInterval),
    couponId: flutterUserCouponInfo.couponId,
    couponName: flutterUserCouponInfo.couponName,
    couponDateInterval: couponDateInterval == null
        ? null
        : mapFlutterDateIntervalToDateInterval(couponDateInterval),
    couponUserStatus: mapFlutterCouponUserStatusToCouponUserStatus(
        flutterUserCouponInfo.couponUserStatus),
    couponProductScope: mapFlutterCouponProductScopeToCouponProductScope(
        flutterUserCouponInfo.couponProductScope),
    firstPurchaseOnly: flutterUserCouponInfo.firstPurchaseOnly,
    couponShortDescription: flutterUserCouponInfo.couponShortDescription,
    couponFullDescription: flutterUserCouponInfo.couponFullDescription,
    couponDeveloperDescription:
        flutterUserCouponInfo.couponDeveloperDescription,
    intervalCouponType: mapFlutterIntervalCouponTypeToIntervalCouponType(
        flutterUserCouponInfo.intervalCouponType),
    couponNominal: flutterUserCouponInfo.couponNominal,
    couponMaxQuantity: flutterUserCouponInfo.couponMaxQuantity,
    minProductPrice: flutterUserCouponInfo.minProductPrice,
  );
}

CouponProductScope mapFlutterCouponProductScopeToCouponProductScope(
    FlutterCouponProductScope flutterCouponProductScope) {
  return switch (flutterCouponProductScope) {
    FlutterCouponProductScope.allProducts => CouponProductScope.allProducts,
    FlutterCouponProductScope.consumableProducts =>
      CouponProductScope.consumableProducts,
    FlutterCouponProductScope.nonConsumableProducts =>
      CouponProductScope.nonConsumableProducts,
  };
}

CouponUserStatus mapFlutterCouponUserStatusToCouponUserStatus(
    FlutterCouponUserStatus flutterCouponUserStatus) {
  return switch (flutterCouponUserStatus) {
    FlutterCouponUserStatus.active => CouponUserStatus.active,
    FlutterCouponUserStatus.expired => CouponUserStatus.expired,
    FlutterCouponUserStatus.redeemed => CouponUserStatus.redeemed,
    FlutterCouponUserStatus.notActivated => CouponUserStatus.notActivated,
  };
}

IntervalCouponType mapFlutterIntervalCouponTypeToIntervalCouponType(
    FlutterIntervalCouponTypeWrapper flutterIntervalCouponType) {
  if (flutterIntervalCouponType.fixed == true) {
    return Fixed._();
  }

  final relativeDuration = flutterIntervalCouponType.relativeDuration;
  if (relativeDuration != null) {
    return Relative._(duration: relativeDuration);
  }

  throw UnsupportedError('Unknown coupon interval type');
}
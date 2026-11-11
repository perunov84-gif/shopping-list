import 'package:flutter_rustore_pay/model/acknowledgement_state.dart';
import 'package:flutter_rustore_pay/model/product_type.dart';
import 'package:flutter_rustore_pay/model/purchase_discount.dart';
import 'package:flutter_rustore_pay/model/purchase_type.dart';
import 'package:flutter_rustore_pay/pigeons/flutter_rustore_pay_api.dart';

/// Абстрактная модель покупки.
sealed class Purchase {
  String get purchaseId;
  String get invoiceId;
  String? get orderId;
  PurchaseType get purchaseType;
  PurchaseStatus get status;
  String get description;
  String? get purchaseTime;
  int get price;
  String get amountLabel;
  String get currency;
  String? get developerPayload;
  bool get sandbox;

  /// Состояние подтверждения выдачи товара.
  AcknowledgementState get acknowledgementState;

  /// Информация о скидках, применённых к покупке.
  PurchaseDiscount? get discount;
}

/// Модель покупки товара.
final class ProductPurchase implements Purchase {
  @override
  final String purchaseId;
  @override
  final String invoiceId;
  @override
  final String? orderId;
  @override
  final PurchaseType purchaseType;
  @override
  final String description;
  @override
  final String? purchaseTime;
  @override
  final int price;
  @override
  final String amountLabel;
  @override
  final String currency;
  @override
  final ProductPurchaseStatus status;
  @override
  final String? developerPayload;
  @override
  final bool sandbox;
  @override
  final AcknowledgementState acknowledgementState;
  @override
  final PurchaseDiscount? discount;
  final String productId;
  final ProductType productType;
  final int quantity;

  ProductPurchase._({
    required this.purchaseId,
    required this.invoiceId,
    this.orderId,
    required this.purchaseType,
    required this.description,
    this.purchaseTime,
    required this.price,
    required this.amountLabel,
    required this.currency,
    required this.status,
    this.developerPayload,
    required this.sandbox,
    required this.acknowledgementState,
    this.discount,
    required this.productId,
    required this.productType,
    required this.quantity,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductPurchase &&
        other.purchaseId == purchaseId &&
        other.invoiceId == invoiceId &&
        other.orderId == orderId &&
        other.purchaseType == purchaseType &&
        other.description == description &&
        other.purchaseTime == purchaseTime &&
        other.price == price &&
        other.amountLabel == amountLabel &&
        other.currency == currency &&
        other.status == status &&
        other.developerPayload == developerPayload &&
        other.sandbox == sandbox &&
        other.acknowledgementState == acknowledgementState &&
        other.productId == productId &&
        other.productType == productType &&
        other.quantity == quantity &&
        other.discount == discount;
  }

  @override
  int get hashCode {
    return purchaseId.hashCode ^
        invoiceId.hashCode ^
        orderId.hashCode ^
        purchaseType.hashCode ^
        description.hashCode ^
        purchaseTime.hashCode ^
        price.hashCode ^
        amountLabel.hashCode ^
        currency.hashCode ^
        status.hashCode ^
        developerPayload.hashCode ^
        sandbox.hashCode ^
        acknowledgementState.hashCode ^
        productId.hashCode ^
        productType.hashCode ^
        quantity.hashCode ^
        discount.hashCode;
  }

  @override
  String toString() =>
      'ProductPurchase(purchaseId: $purchaseId, invoiceId: $invoiceId, orderId: $orderId, purchaseType: $purchaseType, description: $description, purchaseTime: $purchaseTime, price: $price, amountLabel: $amountLabel, currency: $currency, status: $status, developerPayload: $developerPayload, sandbox: $sandbox, acknowledgementState: $acknowledgementState, productId: $productId, productType: $productType, quantity: $quantity, discount: $discount)';
}

/// Модель покупки подписки.
final class SubscriptionPurchase implements Purchase {
  @override
  final String purchaseId;
  @override
  final String invoiceId;
  @override
  final String? orderId;
  @override
  final PurchaseType purchaseType;
  @override
  final String description;
  @override
  final String? purchaseTime;
  @override
  final int price;
  @override
  final String amountLabel;
  @override
  final String currency;
  @override
  final PurchaseStatus status;
  @override
  final String? developerPayload;
  @override
  final bool sandbox;
  @override
  final AcknowledgementState acknowledgementState;
  @override
  final PurchaseDiscount? discount;
  final String productId;
  final String expirationDate;
  final bool gracePeriodEnabled;

  SubscriptionPurchase._({
    required this.purchaseId,
    required this.invoiceId,
    this.orderId,
    required this.purchaseType,
    required this.description,
    this.purchaseTime,
    required this.price,
    required this.amountLabel,
    required this.currency,
    required this.status,
    this.developerPayload,
    required this.sandbox,
    required this.acknowledgementState,
    this.discount,
    required this.productId,
    required this.expirationDate,
    required this.gracePeriodEnabled,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SubscriptionPurchase &&
        other.purchaseId == purchaseId &&
        other.invoiceId == invoiceId &&
        other.orderId == orderId &&
        other.purchaseType == purchaseType &&
        other.description == description &&
        other.purchaseTime == purchaseTime &&
        other.price == price &&
        other.amountLabel == amountLabel &&
        other.currency == currency &&
        other.status == status &&
        other.developerPayload == developerPayload &&
        other.sandbox == sandbox &&
        other.acknowledgementState == acknowledgementState &&
        other.productId == productId &&
        other.expirationDate == expirationDate &&
        other.gracePeriodEnabled == gracePeriodEnabled &&
        other.discount == discount;
  }

  @override
  int get hashCode {
    return purchaseId.hashCode ^
        invoiceId.hashCode ^
        orderId.hashCode ^
        purchaseType.hashCode ^
        description.hashCode ^
        purchaseTime.hashCode ^
        price.hashCode ^
        amountLabel.hashCode ^
        currency.hashCode ^
        status.hashCode ^
        developerPayload.hashCode ^
        sandbox.hashCode ^
        acknowledgementState.hashCode ^
        productId.hashCode ^
        expirationDate.hashCode ^
        gracePeriodEnabled.hashCode ^
        discount.hashCode;
  }

  @override
  String toString() =>
      'SubscriptionPurchase(purchaseId: $purchaseId, invoiceId: $invoiceId, orderId: $orderId, purchaseType: $purchaseType, description: $description, purchaseTime: $purchaseTime, price: $price, amountLabel: $amountLabel, currency: $currency, status: $status, developerPayload: $developerPayload, sandbox: $sandbox, acknowledgementState: $acknowledgementState, productId: $productId, expirationDate: $expirationDate, gracePeriodEnabled: $gracePeriodEnabled, discount: $discount)';
}

/// Модель подписки от SDK Billing Client.
///
/// Не является реализацией [Purchase]: возвращается только из
/// `getBillingSubscriptions()` и не попадает в общий поток покупок
/// (`getPurchases()` / `getPurchase()`).
final class BillingSubscription {
  final String purchaseId;
  final String invoiceId;
  final String? orderId;
  final PurchaseType purchaseType;
  final String description;
  final String? purchaseTime;
  final int price;
  final String amountLabel;
  final String currency;
  final SubscriptionPurchaseStatus status;
  final String? developerPayload;
  final bool sandbox;
  final String productId;
  final String expirationDate;
  final bool gracePeriodEnabled;
  final String subscriptionToken;

  BillingSubscription._({
    required this.purchaseId,
    required this.invoiceId,
    this.orderId,
    required this.purchaseType,
    required this.description,
    this.purchaseTime,
    required this.price,
    required this.amountLabel,
    required this.currency,
    required this.status,
    this.developerPayload,
    required this.sandbox,
    required this.productId,
    required this.expirationDate,
    required this.gracePeriodEnabled,
    required this.subscriptionToken,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BillingSubscription &&
        other.purchaseId == purchaseId &&
        other.invoiceId == invoiceId &&
        other.orderId == orderId &&
        other.purchaseType == purchaseType &&
        other.description == description &&
        other.purchaseTime == purchaseTime &&
        other.price == price &&
        other.amountLabel == amountLabel &&
        other.currency == currency &&
        other.status == status &&
        other.developerPayload == developerPayload &&
        other.sandbox == sandbox &&
        other.productId == productId &&
        other.expirationDate == expirationDate &&
        other.gracePeriodEnabled == gracePeriodEnabled &&
        other.subscriptionToken == subscriptionToken;
  }

  @override
  int get hashCode {
    return purchaseId.hashCode ^
        invoiceId.hashCode ^
        orderId.hashCode ^
        purchaseType.hashCode ^
        description.hashCode ^
        purchaseTime.hashCode ^
        price.hashCode ^
        amountLabel.hashCode ^
        currency.hashCode ^
        status.hashCode ^
        developerPayload.hashCode ^
        sandbox.hashCode ^
        productId.hashCode ^
        expirationDate.hashCode ^
        gracePeriodEnabled.hashCode ^
        subscriptionToken.hashCode;
  }

  @override
  String toString() =>
      'BillingSubscription(purchaseId: $purchaseId, invoiceId: $invoiceId, orderId: $orderId, purchaseType: $purchaseType, description: $description, purchaseTime: $purchaseTime, price: $price, amountLabel: $amountLabel, currency: $currency, status: $status, developerPayload: $developerPayload, sandbox: $sandbox, productId: $productId, expirationDate: $expirationDate, gracePeriodEnabled: $gracePeriodEnabled, subscriptionToken: $subscriptionToken)';
}

BillingSubscription mapFlutterBillingSubscriptionToBillingSubscription(
    FlutterBillingSubscription flutterSubscription) {
  final status =
      _mapFlutterSubscriptionPurchaseStatusToSubscriptionPurchaseStatus(
          flutterSubscription.status);
  final purchaseType =
      mapFlutterPurchaseTypeToPurchaseType(flutterSubscription.purchaseType);

  return BillingSubscription._(
    purchaseId: flutterSubscription.purchaseId,
    invoiceId: flutterSubscription.invoiceId,
    orderId: flutterSubscription.orderId,
    purchaseType: purchaseType,
    description: flutterSubscription.description,
    purchaseTime: flutterSubscription.purchaseTime,
    price: flutterSubscription.price,
    amountLabel: flutterSubscription.amountLabel,
    currency: flutterSubscription.currency,
    status: status,
    developerPayload: flutterSubscription.developerPayload,
    sandbox: flutterSubscription.sandbox,
    productId: flutterSubscription.productId,
    expirationDate: flutterSubscription.expirationDate,
    gracePeriodEnabled: flutterSubscription.gracePeriodEnabled,
    subscriptionToken: flutterSubscription.subscriptionToken,
  );
}

sealed class PurchaseStatus {}

/// Возможные статусы покупки продукта.
enum ProductPurchaseStatus implements PurchaseStatus {
  invoiceCreated,
  cancelled,
  processing,
  rejected,
  confirmed,
  refunded,
  refunding,
  executing,
  expired,
  paid,
  reversed,
  unknown;
}

/// Возможные статусы покупки подписки.
enum SubscriptionPurchaseStatus implements PurchaseStatus {
  invoiceCreated,
  cancelled,
  expired,
  processing,
  rejected,
  active,
  paused,
  terminated,
  closed,
  unknown;
}

Purchase mapFlutterPurchaseToPurchase(FlutterPurchaseResultWrapper result) {
  if (result.productPurchase != null) {
    final productPurchase = result.productPurchase!;
    final status = _mapFlutterProductPurchaseStatusToProductPurchaseStatus(
        productPurchase.status as FlutterProductPurchaseStatus?);
    final purchaseType = mapFlutterPurchaseTypeToPurchaseType(
        result.productPurchase!.purchaseType);
    return ProductPurchase._(
      purchaseId: productPurchase.purchaseId,
      invoiceId: productPurchase.invoiceId,
      orderId: productPurchase.orderId,
      purchaseType: purchaseType,
      description: productPurchase.description,
      purchaseTime: productPurchase.purchaseTime,
      price: productPurchase.price,
      amountLabel: productPurchase.amountLabel,
      currency: productPurchase.currency,
      status: status,
      developerPayload: productPurchase.developerPayload,
      sandbox: productPurchase.sandbox,
      acknowledgementState:
          mapFlutterAcknowledgementStateToAcknowledgementState(
              productPurchase.acknowledgementState),
      productId: productPurchase.productId,
      productType:
          mapFlutterProductTypeToProductType(productPurchase.productType),
      quantity: productPurchase.quantity,
      discount: mapFlutterPurchaseDiscountToPurchaseDiscount(
          productPurchase.discount),
    );
  } else if (result.subscriptionPurchase != null) {
    final subscriptionPurchase = result.subscriptionPurchase!;
    final status =
        _mapFlutterSubscriptionPurchaseStatusToSubscriptionPurchaseStatus(
            subscriptionPurchase.status as FlutterSubscriptionPurchaseStatus?);
    final purchaseType = mapFlutterPurchaseTypeToPurchaseType(
        result.subscriptionPurchase!.purchaseType);
    return SubscriptionPurchase._(
      purchaseId: subscriptionPurchase.purchaseId,
      invoiceId: subscriptionPurchase.invoiceId,
      orderId: subscriptionPurchase.orderId,
      purchaseType: purchaseType,
      description: subscriptionPurchase.description,
      purchaseTime: subscriptionPurchase.purchaseTime,
      price: subscriptionPurchase.price,
      amountLabel: subscriptionPurchase.amountLabel,
      currency: subscriptionPurchase.currency,
      status: status,
      developerPayload: subscriptionPurchase.developerPayload,
      sandbox: subscriptionPurchase.sandbox,
      acknowledgementState:
          mapFlutterAcknowledgementStateToAcknowledgementState(
              subscriptionPurchase.acknowledgementState),
      productId: subscriptionPurchase.productId,
      expirationDate: subscriptionPurchase.expirationDate,
      gracePeriodEnabled: subscriptionPurchase.gracePeriodEnabled,
      discount: mapFlutterPurchaseDiscountToPurchaseDiscount(
          subscriptionPurchase.discount),
    );
  } else {
    throw UnsupportedError('Unknown purchase type');
  }
}

ProductPurchaseStatus _mapFlutterProductPurchaseStatusToProductPurchaseStatus(
    FlutterProductPurchaseStatus? flutterStatus) {
  return switch (flutterStatus) {
    FlutterProductPurchaseStatus.invoiceCreated =>
      ProductPurchaseStatus.invoiceCreated,
    FlutterProductPurchaseStatus.cancelled => ProductPurchaseStatus.cancelled,
    FlutterProductPurchaseStatus.processing => ProductPurchaseStatus.processing,
    FlutterProductPurchaseStatus.rejected => ProductPurchaseStatus.rejected,
    FlutterProductPurchaseStatus.confirmed => ProductPurchaseStatus.confirmed,
    FlutterProductPurchaseStatus.refunded => ProductPurchaseStatus.refunded,
    FlutterProductPurchaseStatus.refunding => ProductPurchaseStatus.refunding,
    FlutterProductPurchaseStatus.executing => ProductPurchaseStatus.executing,
    FlutterProductPurchaseStatus.expired => ProductPurchaseStatus.expired,
    FlutterProductPurchaseStatus.paid => ProductPurchaseStatus.paid,
    FlutterProductPurchaseStatus.reversed => ProductPurchaseStatus.reversed,
    null => ProductPurchaseStatus.unknown,
  };
}

SubscriptionPurchaseStatus
    _mapFlutterSubscriptionPurchaseStatusToSubscriptionPurchaseStatus(
        FlutterSubscriptionPurchaseStatus? flutterStatus) {
  return switch (flutterStatus) {
    FlutterSubscriptionPurchaseStatus.invoiceCreated =>
      SubscriptionPurchaseStatus.invoiceCreated,
    FlutterSubscriptionPurchaseStatus.cancelled =>
      SubscriptionPurchaseStatus.cancelled,
    FlutterSubscriptionPurchaseStatus.expired =>
      SubscriptionPurchaseStatus.expired,
    FlutterSubscriptionPurchaseStatus.processing =>
      SubscriptionPurchaseStatus.processing,
    FlutterSubscriptionPurchaseStatus.rejected =>
      SubscriptionPurchaseStatus.rejected,
    FlutterSubscriptionPurchaseStatus.active =>
      SubscriptionPurchaseStatus.active,
    FlutterSubscriptionPurchaseStatus.paused =>
      SubscriptionPurchaseStatus.paused,
    FlutterSubscriptionPurchaseStatus.terminated =>
      SubscriptionPurchaseStatus.terminated,
    FlutterSubscriptionPurchaseStatus.closed =>
      SubscriptionPurchaseStatus.closed,
    null => SubscriptionPurchaseStatus.unknown,
  };
}

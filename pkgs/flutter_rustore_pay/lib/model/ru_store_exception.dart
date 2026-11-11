sealed class RuStoreException implements Exception {
  const RuStoreException([this.message]);

  final String? message;
}

/// Ошибка сетевого взаимодействия SDK.
final class RuStorePaymentNetworkException extends RuStoreException {
  const RuStorePaymentNetworkException([super.message]);

  @override
  String toString() => '$RuStorePaymentNetworkException(message: $message)';
}

/// Общая ошибка SDK.
final class RuStorePaymentCommonException extends RuStoreException {
  const RuStorePaymentCommonException([super.message]);

  @override
  String toString() => '$RuStorePaymentCommonException(message: $message)';
}

/// Ошибка повторной инициализации SDK.
final class RuStorePayClientAlreadyExist extends RuStoreException {
  const RuStorePayClientAlreadyExist([super.message]);

  @override
  String toString() => '$RuStorePayClientAlreadyExist(message: $message)';
}

/// Попытка обратиться к публичным интерфейсам SDK до момента её инициализации.
final class RuStorePayClientNotCreated extends RuStoreException {
  const RuStorePayClientNotCreated([super.message]);

  @override
  String toString() => '$RuStorePayClientNotCreated(message: $message)';
}

/// Запущено флоу оплаты неизвестного типа продукта.
final class RuStorePayInvalidActivePurchase extends RuStoreException {
  const RuStorePayInvalidActivePurchase([super.message]);

  @override
  String toString() => '$RuStorePayInvalidActivePurchase(message: $message)';
}

/// Не задан обязательный параметр сonsole_application_id для инициализации SDK.
final class RuStorePayInvalidConsoleAppId extends RuStoreException {
  const RuStorePayInvalidConsoleAppId([super.message]);

  @override
  String toString() => '$RuStorePayInvalidConsoleAppId(message: $message)';
}

/// Неверная сигнатура ответа (возникает при попытке совершить мошеннические действия).
final class RuStorePaySignatureException extends RuStoreException {
  const RuStorePaySignatureException([super.message]);

  @override
  String toString() => '$RuStorePaySignatureException(message: $message)';
}

/// Ошибка получения платежного токена
final class EmptyPaymentTokenException extends RuStoreException {
  const EmptyPaymentTokenException([super.message]);

  @override
  String toString() => '$EmptyPaymentTokenException(message: $message)';
}

/// Ошибка оплаты сохраненной картой.
final class InvalidCardBindingIdException extends RuStoreException {
  const InvalidCardBindingIdException([super.message]);

  @override
  String toString() => '$InvalidCardBindingIdException(message: $message)';
}

/// Не указана схема для обратного диплинка.
final class ApplicationSchemeWasNotProvided extends RuStoreException {
  const ApplicationSchemeWasNotProvided([super.message]);

  @override
  String toString() => '$ApplicationSchemeWasNotProvided(message: $message)';
}

/// Ошибка покупки продукта.
final class RuStoreProductPurchaseException extends RuStoreException {
  const RuStoreProductPurchaseException({
    this.orderId,
    this.purchaseId,
    this.productId,
    this.invoiceId,
    this.quantity,
    this.purchaseType,
    this.sandbox,
    this.productType,
    String? message,
  }) : super(message);

  final dynamic orderId;
  final dynamic purchaseId;
  final dynamic productId;
  final dynamic invoiceId;
  final dynamic quantity;
  final dynamic purchaseType;
  final dynamic sandbox;
  final dynamic productType;

  @override
  String toString() {
    return '$runtimeType(orderId: $orderId, purchaseId: $purchaseId, productId: $productId, invoiceId: $invoiceId, quantity: $quantity, purchaseType: $purchaseType, sandbox: $sandbox, productType: $productType, message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return other is RuStoreProductPurchaseException;
  }

  @override
  int get hashCode => runtimeType.hashCode;
}

/// Отмена покупки продукта
final class RuStorePurchaseCancelledException extends RuStoreException {
  const RuStorePurchaseCancelledException({
    this.purchaseId,
    this.purchaseType,
    this.productType,
    String? message,
  }) : super(message ?? 'Purchase product is cancelled');

  final dynamic purchaseId;
  final dynamic purchaseType;
  final dynamic productType;

  @override
  String toString() =>
      '$runtimeType(purchaseId: $purchaseId, purchaseType: $purchaseType, productType: $productType, message: $message)';

  @override
  bool operator ==(Object other) => other is RuStorePurchaseCancelledException;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// На устройстве пользователя не установлен RuStore.
final class RuStoreNotInstalledException extends RuStoreException {
  const RuStoreNotInstalledException([super.message]);

  @override
  String toString() => '$RuStoreNotInstalledException(message: $message)';
}

/// RuStore установленный на устройстве пользователя не поддерживает платежи.
final class RuStoreOutdatedException extends RuStoreException {
  const RuStoreOutdatedException([super.message]);

  @override
  String toString() => '$RuStoreOutdatedException(message: $message)';
}

/// Пользователь не авторизован в RuStore.
final class RuStoreUserUnauthorizedException extends RuStoreException {
  const RuStoreUserUnauthorizedException([super.message]);

  @override
  String toString() => '$RuStoreUserUnauthorizedException(message: $message)';
}

/// Приложение забанено в RuStore.
final class RuStoreApplicationBannedException extends RuStoreException {
  const RuStoreApplicationBannedException([super.message]);

  @override
  String toString() => '$RuStoreApplicationBannedException(message: $message)';
}

/// Пользователь забанен в RuStore.
final class RuStoreUserBannedException extends RuStoreException {
  const RuStoreUserBannedException([super.message]);

  @override
  String toString() => '$RuStoreUserBannedException(message: $message)';
}

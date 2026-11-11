import 'package:flutter/services.dart';
import 'package:flutter_rustore_pay/api/purchase_event_listener.dart';
import 'package:flutter_rustore_pay/model/coupon.dart';
import 'package:flutter_rustore_pay/model/preferred_purchase_type.dart';
import 'package:flutter_rustore_pay/model/promotion.dart';
import 'package:flutter_rustore_pay/model/sdk_theme.dart';
import 'package:flutter_rustore_pay/model/user_authorization_status.dart';
import 'package:flutter_rustore_pay/pigeons/flutter_rustore_pay_api.dart';

import '../model/acknowledgement_state.dart';
import '../model/product.dart';
import '../model/product_type.dart';
import '../model/purchase.dart';
import '../model/purchase_availability.dart';
import '../model/purchase_result.dart';
import '../model/ru_store_exception.dart';

/// Класс для работы с pay sdk, содержит:
/// purchaseInteractor - класс, который позволяет работать с платежами.
/// productInteractor - класс, который позволяет работать с продуктами.
/// promotionInteractor - класс, который позволяет работать с акциями.
/// couponInteractor - класс, который позволяет работать с купонами.
/// userInteractor - класс, который позволяет получить статус авторизации пользователя.
/// ruStoreUtils - класс содержит набор утилитных методов.
class RuStorePayClient {
  RuStorePayClient._privateConstructor();

  static final RuStorePayClient _instance =
      RuStorePayClient._privateConstructor();

  static RuStorePayClient get instance => _instance;

  final RuStoreFlutterUtils ruStoreUtils = _RuStoreFlutterUtilsImpl.instance;

  final RuStoreFlutterProductInteractor productInteractor =
      _RuStoreFlutterProductInteractorImpl.instance;

  final RuStoreFlutterPromotionInteractor promotionInteractor =
      _RuStoreFlutterPromotionInteractorImpl.instance;

  final RuStoreFlutterCouponInteractor couponInteractor =
      _RuStoreFlutterCouponInteractorImpl.instance;

  final RuStoreFlutterPurchaseInteractor purchaseInteractor =
      _RuStoreFlutterPurchaseInteractorImpl.instance;

  final RuStoreFlutterUserInteractor userInteractor =
      _RuStoreFlutterUserInteractorImpl.instance;
}

abstract class RuStoreFlutterPurchaseInteractor {
  /// Позволяет получить информацию о покупке по её ID. Возвращает покупку по её ID.
  Future<Purchase> getPurchase(String purchaseId);

  /// Позволяет получить покупки пользователя. Данный метод поддерживает опциональную фильтрацию по типу товаров: потребляемые товары, непотребляемые товары или подписки,
  /// по статусу покупки, а также по состоянию подтверждения выдачи товара. По умолчанию фильтры выключены и вернутся все покупки пользователя (в не зависимости от типа товара).
  ///
  /// Передача [AcknowledgementState.unknown] в [acknowledgementState] равнозначна отсутствию фильтра:
  /// отобрать покупки именно в состоянии unknown нельзя.
  Future<List<Purchase>> getPurchases(
      {ProductType? productType,
      PurchaseStatus? purchaseStatus,
      AcknowledgementState? acknowledgementState});

  /// Позволяет получить результат доступности работы с платежами. Возвращает PurchaseAvailabilityResult.
  Future<PurchaseAvailabilityResult> getPurchaseAvailability();

  /// Запускает флоу покупки товара с выбором стадийности оплаты. Возвращает ProductPurchaseResult.
  Future<ProductPurchaseResult> purchase(String productId,
      {String? orderId,
      int? quantity,
      String? developerPayload,
      String? appUserId,
      String? appUserEmail,
      PreferredPurchaseType? preferredPurchaseType,
      SdkTheme? sdkTheme,
      PurchaseEventListener? purchaseEventListener});

  /// Запускает флоу двустадийной покупки товара. Возвращает ProductPurchaseResult.
  Future<ProductPurchaseResult> purchaseTwoStep(String productId,
      {String? orderId,
      int? quantity,
      String? appUserId,
      String? appUserEmail,
      String? developerPayload,
      SdkTheme? sdkTheme,
      PurchaseEventListener? purchaseEventListener});

  /// Подтверждение покупки (для покупок, совершенных по двустадийной оплате). В этом случае происходит перевод холдированных средств.
  Future<void> confirmTwoStepPurchase(String purchaseId,
      {String? developerPayload});

  /// Подтверждение выдачи товара пользователю. Возвращает фактическое состояние подтверждения
  /// после выполнения операции — оно может отличаться от запрошенного.
  Future<AcknowledgementState> updateAcknowledgementState(
      String purchaseId, AcknowledgementState acknowledgementState,
      {String? developerPayload});

  /// Отмена покупки (для покупок, совершенных по двустадийной оплате). В этом случае происходит отмена холдирования средств
  Future<void> cancelTwoStepPurchase(String purchaseId);

  /// Получение подписок от SDK Billing Client. Возвращает список BillingSubscription.
  Future<List<BillingSubscription>> getBillingSubscriptions();
}

final class _RuStoreFlutterPurchaseInteractorImpl
    extends RuStoreFlutterPurchaseInteractor {

  _RuStoreFlutterPurchaseInteractorImpl._() {
    FlutterPurchaseEventListener.setUp(_FlutterPurchaseEventListenerExample());
  }

  static _RuStoreFlutterPurchaseInteractorImpl? _instance;
  static PurchaseEventListener? _purchaseEventListener;

  static RuStoreFlutterPurchaseInteractor get instance =>
      _instance ??= _RuStoreFlutterPurchaseInteractorImpl._();

  final RuStorePurchaseApi _api = RuStorePurchaseApi();

  @override
  Future<Purchase> getPurchase(String purchaseId) async {
    try {
      final flutterPurchase = await _api.getPurchase(purchaseId);
      return mapFlutterPurchaseToPurchase(flutterPurchase);
    } on PlatformException catch (error, stackTrace) {
      _handleRuStoreException(error, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<Purchase>> getPurchases(
      {ProductType? productType,
      PurchaseStatus? purchaseStatus,
      AcknowledgementState? acknowledgementState}) async {
    try {
      final flutterPurchases = await _api.getPurchases(
          productType: _mapProductTypeToFlutterProductType(productType),
          purchaseStatus:
              _mapPurchaseStatusToFlutterPurchaseStatus(purchaseStatus),
          acknowledgementState:
              _mapAcknowledgementStateToFilter(acknowledgementState));
      return flutterPurchases.map(mapFlutterPurchaseToPurchase).toList();
    } on PlatformException catch (error, stackTrace) {
      _handleRuStoreException(error, stackTrace);
      rethrow;
    }
  }

  @override
  Future<PurchaseAvailabilityResult> getPurchaseAvailability() async {
    try {
      final response = await _api.getPurchaseAvailability();
      if (response.availability == true) {
        return Available();
      } else {
        return Unavailable(errorMessage: response.cause);
      }
    } on PlatformException catch (error, stackTrace) {
      _handleRuStoreException(error, stackTrace);
      rethrow;
    }
  }

  @override
  Future<ProductPurchaseResult> purchase(
    String productId, {
    String? orderId,
    int? quantity,
    String? developerPayload,
    String? appUserId,
    String? appUserEmail,
    PreferredPurchaseType? preferredPurchaseType,
    SdkTheme? sdkTheme,
    PurchaseEventListener? purchaseEventListener,
  }) async {
    try {
      _purchaseEventListener = purchaseEventListener;
      final purchaseResult = await _api.purchase(
        productId,
        orderId: orderId,
        quantity: quantity,
        developerPayload: developerPayload,
        appUserId: appUserId,
        appUserEmail: appUserEmail,
        preferredPurchaseType: _mapFlutterPurchaseTypeToPreferredPurchaseType(
            preferredPurchaseType),
        sdkTheme: mapSdkThemeToFlutterSdkTheme(sdkTheme),
      );
      return mapFlutterPurchaseResultToPurchaseResult(purchaseResult);
    } on PlatformException catch (error, stackTrace) {
      _handleRuStoreException(error, stackTrace);
      rethrow;
    }
  }

  @override
  Future<ProductPurchaseResult> purchaseTwoStep(
    String productId, {
    String? orderId,
    int? quantity,
    String? developerPayload,
    String? appUserId,
    String? appUserEmail,
    SdkTheme? sdkTheme,
    PurchaseEventListener? purchaseEventListener,
  }) async {
    try {
      _purchaseEventListener = purchaseEventListener;
      final purchaseResult = await _api.purchaseTwoStep(
        productId,
        orderId: orderId,
        quantity: quantity,
        developerPayload: developerPayload,
        appUserId: appUserId,
        appUserEmail: appUserEmail,
        sdkTheme: mapSdkThemeToFlutterSdkTheme(sdkTheme),
      );
      return mapFlutterPurchaseResultToPurchaseResult(purchaseResult);
    } on PlatformException catch (error, stackTrace) {
      _handleRuStoreException(error, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> confirmTwoStepPurchase(String purchaseId,
      {String? developerPayload}) async {
    try {
      return await _api.confirmTwoStepPurchase(purchaseId,
          developerPayload: developerPayload);
    } on PlatformException catch (error, stackTrace) {
      _handleRuStoreException(error, stackTrace);
      rethrow;
    }
  }

  @override
  Future<AcknowledgementState> updateAcknowledgementState(
      String purchaseId, AcknowledgementState acknowledgementState,
      {String? developerPayload}) async {
    try {
      final result = await _api.updateAcknowledgementState(
        purchaseId,
        mapAcknowledgementStateToFlutterAcknowledgementState(
            acknowledgementState),
        developerPayload: developerPayload,
      );
      return mapFlutterAcknowledgementStateToAcknowledgementState(result);
    } on PlatformException catch (error, stackTrace) {
      _handleRuStoreException(error, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> cancelTwoStepPurchase(String purchaseId) async {
    try {
      return await _api.cancelTwoStepPurchase(purchaseId);
    } on PlatformException catch (error, stackTrace) {
      _handleRuStoreException(error, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<BillingSubscription>> getBillingSubscriptions() async {
    try {
      final flutterSubscriptions = await _api.getBillingSubscriptions();
      return flutterSubscriptions
          .map(mapFlutterBillingSubscriptionToBillingSubscription)
          .toList();
    } on PlatformException catch (error, stackTrace) {
      _handleRuStoreException(error, stackTrace);
      rethrow;
    }
  }
}

class _FlutterPurchaseEventListenerExample implements FlutterPurchaseEventListener {
  @override
  void onPaymentCompleted(String purchaseId, String invoiceId) {
    _RuStoreFlutterPurchaseInteractorImpl._purchaseEventListener?.onPaymentCompleted(
      purchaseId,
      invoiceId,
    );
  }

  @override
  void onPaymentFailed(String purchaseId, String invoiceId) {
    _RuStoreFlutterPurchaseInteractorImpl._purchaseEventListener?.onPaymentFailed(
      purchaseId,
      invoiceId,
    );
  }

  @override
  void onPaymentStarted(String purchaseId, String invoiceId) {
    _RuStoreFlutterPurchaseInteractorImpl._purchaseEventListener?.onPaymentStarted(
      purchaseId,
      invoiceId,
    );
  }

  @override
  void onPurchaseCancelled(String purchaseId, String invoiceId) {
    _RuStoreFlutterPurchaseInteractorImpl._purchaseEventListener?.onPurchaseCancelled(
      purchaseId,
      invoiceId,
    );
  }

  @override
  void onPurchaseCreated(String purchaseId, String invoiceId) {
    _RuStoreFlutterPurchaseInteractorImpl._purchaseEventListener?.onPurchaseCreated(
      purchaseId,
      invoiceId,
    );
  }
}

abstract class RuStoreFlutterProductInteractor {
  /// Позволяет получить список продуктов по их ID (Данный метод имеет ограничение в 1000 продуктов). Возвращает список продуктов.
  Future<List<Product>> getProducts(List<String> ids);
}

final class _RuStoreFlutterProductInteractorImpl
    extends RuStoreFlutterProductInteractor {
  _RuStoreFlutterProductInteractorImpl._();

  static _RuStoreFlutterProductInteractorImpl? _instance;

  static RuStoreFlutterProductInteractor get instance =>
      _instance ??= _RuStoreFlutterProductInteractorImpl._();

  final RuStoreProductApi _api = RuStoreProductApi();

  @override
  Future<List<Product>> getProducts(List<String> ids) async {
    try {
      final flutterProducts = await _api.getProducts(ids);
      return flutterProducts.map(mapFlutterProductToProduct).toList();
    } on PlatformException catch (error, stackTrace) {
      _handleRuStoreException(error, stackTrace);
      rethrow;
    }
  }
}

abstract class RuStoreFlutterPromotionInteractor {
  /// Получает акцию по её коду.
  ///
  /// Список продуктов [Promotion.productCodes] содержится только в акции,
  /// полученной по коду. Значение null означает применение ко всем продуктам.
  Future<Promotion> getPromotion(String promotionCode);

  /// Получает список акций с необязательной фильтрацией по статусам и датам.
  ///
  /// [startDateFrom] и [endDateTo] задаются в формате ISO 8601 (UTC).
  /// Без фильтров возвращаются все акции. В списке акций
  /// [Promotion.productCodes] всегда null.
  Future<List<Promotion>> getPromotions({
    List<PromotionStatus>? statuses,
    String? startDateFrom,
    String? endDateTo,
  });
}

final class _RuStoreFlutterPromotionInteractorImpl
    extends RuStoreFlutterPromotionInteractor {
  _RuStoreFlutterPromotionInteractorImpl._();

  static _RuStoreFlutterPromotionInteractorImpl? _instance;

  static RuStoreFlutterPromotionInteractor get instance =>
      _instance ??= _RuStoreFlutterPromotionInteractorImpl._();

  final RuStorePromotionApi _api = RuStorePromotionApi();

  @override
  Future<Promotion> getPromotion(String promotionCode) async {
    try {
      final flutterPromotion = await _api.getPromotion(promotionCode);
      return mapFlutterPromotionToPromotion(flutterPromotion);
    } on PlatformException catch (error, stackTrace) {
      _handleRuStoreException(error, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<Promotion>> getPromotions({
    List<PromotionStatus>? statuses,
    String? startDateFrom,
    String? endDateTo,
  }) async {
    try {
      final flutterPromotions = await _api.getPromotions(
        statuses:
            statuses?.map(_mapPromotionStatusToFlutterPromotionStatus).toList(),
        startDateFrom: startDateFrom,
        endDateTo: endDateTo,
      );
      return flutterPromotions.map(mapFlutterPromotionToPromotion).toList();
    } on PlatformException catch (error, stackTrace) {
      _handleRuStoreException(error, stackTrace);
      rethrow;
    }
  }
}

abstract class RuStoreFlutterCouponInteractor {
  /// Получает генераторы купонов с необязательной фильтрацией по продуктам,
  /// применению к первой покупке и периоду действия ссылки.
  ///
  /// [deepLinkDateIntervalStart] и [deepLinkDateIntervalEnd] задаются
  /// в формате ISO 8601 (UTC). Без фильтров возвращаются все генераторы.
  Future<List<CouponGenerator>> getCouponGenerators({
    List<CouponProductScope>? couponProductScopes,
    bool? firstPurchaseOnly,
    String? deepLinkDateIntervalStart,
    String? deepLinkDateIntervalEnd,
  });

  /// Получает купоны пользователя с необязательной фильтрацией по продуктам,
  /// применению к первой покупке, статусам и периоду действия купона.
  ///
  /// [couponDateIntervalStart] и [couponDateIntervalEnd] задаются
  /// в формате ISO 8601 (UTC). Без фильтров возвращаются все купоны пользователя.
  Future<List<UserCouponInfo>> getUserCouponsInfo({
    List<CouponProductScope>? couponProductScopes,
    bool? firstPurchaseOnly,
    List<CouponUserStatus>? couponUserStatuses,
    String? couponDateIntervalStart,
    String? couponDateIntervalEnd,
  });
}

final class _RuStoreFlutterCouponInteractorImpl
    extends RuStoreFlutterCouponInteractor {
  _RuStoreFlutterCouponInteractorImpl._();

  static _RuStoreFlutterCouponInteractorImpl? _instance;

  static RuStoreFlutterCouponInteractor get instance =>
      _instance ??= _RuStoreFlutterCouponInteractorImpl._();

  final RuStoreCouponApi _api = RuStoreCouponApi();

  @override
  Future<List<CouponGenerator>> getCouponGenerators({
    List<CouponProductScope>? couponProductScopes,
    bool? firstPurchaseOnly,
    String? deepLinkDateIntervalStart,
    String? deepLinkDateIntervalEnd,
  }) async {
    try {
      final flutterGenerators = await _api.getCouponGenerators(
        couponProductScopes: couponProductScopes
            ?.map(_mapCouponProductScopeToFlutterCouponProductScope)
            .toList(),
        firstPurchaseOnly: firstPurchaseOnly,
        deepLinkDateIntervalStart: deepLinkDateIntervalStart,
        deepLinkDateIntervalEnd: deepLinkDateIntervalEnd,
      );
      return flutterGenerators
          .map(mapFlutterCouponGeneratorToCouponGenerator)
          .toList();
    } on PlatformException catch (error, stackTrace) {
      _handleRuStoreException(error, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<UserCouponInfo>> getUserCouponsInfo({
    List<CouponProductScope>? couponProductScopes,
    bool? firstPurchaseOnly,
    List<CouponUserStatus>? couponUserStatuses,
    String? couponDateIntervalStart,
    String? couponDateIntervalEnd,
  }) async {
    try {
      final flutterCoupons = await _api.getUserCouponsInfo(
        couponProductScopes: couponProductScopes
            ?.map(_mapCouponProductScopeToFlutterCouponProductScope)
            .toList(),
        firstPurchaseOnly: firstPurchaseOnly,
        couponUserStatuses: couponUserStatuses
            ?.map(_mapCouponUserStatusToFlutterCouponUserStatus)
            .toList(),
        couponDateIntervalStart: couponDateIntervalStart,
        couponDateIntervalEnd: couponDateIntervalEnd,
      );
      return flutterCoupons
          .map(mapFlutterUserCouponInfoToUserCouponInfo)
          .toList();
    } on PlatformException catch (error, stackTrace) {
      _handleRuStoreException(error, stackTrace);
      rethrow;
    }
  }
}

abstract class RuStoreFlutterUserInteractor {
  /// позволяет получить статус авторизации пользователя UserAuthorizationStatus. У данной модели может быть 2 возможных состояния: authorized - пользователь авторизован в RuStore, unauthorized - пользователь неавторизован в RuStore.
  Future<UserAuthorizationStatus> getUserAuthorizationStatus();
}

final class _RuStoreFlutterUserInteractorImpl
    extends RuStoreFlutterUserInteractor {
  _RuStoreFlutterUserInteractorImpl._();

  static _RuStoreFlutterUserInteractorImpl? _instance;

  static RuStoreFlutterUserInteractor get instance =>
      _instance ??= _RuStoreFlutterUserInteractorImpl._();

  final RuStoreUserApi _api = RuStoreUserApi();

  @override
  Future<UserAuthorizationStatus> getUserAuthorizationStatus() async {
    try {
      final bool authStatus = await _api.getUserAuthorizationStatus();
      return authStatus ? Authorized() : Unauthorized();
    } on PlatformException catch (error, stackTrace) {
      _handleRuStoreException(error, stackTrace);
      rethrow;
    }
  }
}

abstract class RuStoreFlutterUtils {
  /// Запускает МП RuStore.
  Future<void> openRuStore();

  /// Проверяет наличие приложения RuStore на девайсе пользователя. Возвращает логическое значение.
  Future<bool> isRuStoreInstalled();

  /// Запускает МП RuStore для авторизации. После успешной авторизации пользователя МП RuStore автоматически закроется.
  Future<void> openRuStoreAuthorization();

  /// Открывает web старницу для скачивания МП RuStore.
  Future<void> openRuStoreDownloadInstruction();
}

final class _RuStoreFlutterUtilsImpl extends RuStoreFlutterUtils {
  _RuStoreFlutterUtilsImpl._();

  static _RuStoreFlutterUtilsImpl? _instance;

  static RuStoreFlutterUtils get instance =>
      _instance ??= _RuStoreFlutterUtilsImpl._();

  final RuStoreUtilsApi _api = RuStoreUtilsApi();

  @override
  Future<void> openRuStore() => _api.openRuStore();

  @override
  Future<bool> isRuStoreInstalled() => _api.isRuStoreInstalled();

  @override
  Future<void> openRuStoreAuthorization() => _api.openRuStoreAuthorization();

  @override
  Future<void> openRuStoreDownloadInstruction() =>
      _api.openRuStoreDownloadInstruction();
}

RuStoreProductPurchaseException _productPurchaseException(
    String? message, Map? details) {
  return RuStoreProductPurchaseException(
      message: message,
      orderId: details?['orderId'],
      purchaseId: details?['purchaseId'],
      productId: details?['productId'],
      invoiceId: details?['invoiceId'],
      quantity: details?['quantity'],
      purchaseType: details?['purchaseType'],
      sandbox: details?['sandbox'],
      productType: details?['productType']);
}

RuStorePurchaseCancelledException _purchaseCancelledException(
    String? message, Map? details) {
  return RuStorePurchaseCancelledException(
      purchaseId: details?['purchaseId'],
      purchaseType: details?['purchaseType'],
      productType: details?['productType'],
      message: message ?? 'Purchase product is cancelled');
}

Map<String, String> _parseDetailsString(String details) {
  return details
      .replaceAll('{', '')
      .replaceAll('}', '')
      .split(',')
      .map((e) => e.split('='))
      .where((kv) => kv.length == 2)
      .map((kv) => MapEntry(kv[0].trim(), kv[1].trim()))
      .fold<Map<String, String>>({}, (map, entry) {
    map[entry.key] = entry.value;
    return map;
  });
}

extension on PlatformException {
  RuStoreException? _makeRuStoreException() {
    if (message != null) {
      final match = RegExp(r'({.*})').firstMatch(message!);
      if (match != null) {
        final detailsString = match.group(1)!;
        final detailsMap = _parseDetailsString(detailsString);
        final errorType = detailsMap['type'];

        if (errorType != null) {
          switch (errorType) {
            case 'RuStoreProductPurchaseException':
              return _productPurchaseException(detailsMap['message'], detailsMap);

            case 'RuStorePurchaseCancelledException':
              return _purchaseCancelledException(detailsMap['message'], detailsMap);
          }
        }
      }
    }

    final fallbackMessage = message?.split(': ').skip(1).join(': ').trim();

    return switch (code) {
      'RuStorePaymentNetworkException' =>
          RuStorePaymentNetworkException(fallbackMessage),
      'RuStorePaymentCommonException' => RuStorePaymentCommonException(fallbackMessage),
      'RuStorePayClientAlreadyExist' => RuStorePayClientAlreadyExist(fallbackMessage),
      'RuStorePayClientNotCreated' => RuStorePayClientNotCreated(fallbackMessage),
      'RuStorePayInvalidActivePurchase' =>
          RuStorePayInvalidActivePurchase(fallbackMessage),
      'RuStorePayInvalidConsoleAppId' => RuStorePayInvalidConsoleAppId(fallbackMessage),
      'RuStorePaySignatureException' => RuStorePaySignatureException(fallbackMessage),
      'EmptyPaymentTokenException' => EmptyPaymentTokenException(fallbackMessage),
      'InvalidCardBindingIdException' => InvalidCardBindingIdException(fallbackMessage),
      'ApplicationSchemeWasNotProvided' =>
          ApplicationSchemeWasNotProvided(fallbackMessage),
      'RuStoreNotInstalledException' => RuStoreNotInstalledException(fallbackMessage),
      'RuStoreOutdatedException' => RuStoreOutdatedException(fallbackMessage),
      'RuStoreUserUnauthorizedException' =>
          RuStoreUserUnauthorizedException(fallbackMessage),
      'RuStoreApplicationBannedException' =>
          RuStoreApplicationBannedException(fallbackMessage),
      'RuStoreUserBannedException' => RuStoreUserBannedException(fallbackMessage),
      _ => null,
    };
  }
}

void _handleRuStoreException(PlatformException error, StackTrace stackTrace) {
  if (error._makeRuStoreException() case RuStoreException exception) {
    Error.throwWithStackTrace(exception, stackTrace);
  }
}

FlutterPromotionStatus _mapPromotionStatusToFlutterPromotionStatus(
    PromotionStatus status) {
  return switch (status) {
    PromotionStatus.active => FlutterPromotionStatus.active,
    PromotionStatus.scheduled => FlutterPromotionStatus.scheduled,
  };
}

FlutterCouponProductScope _mapCouponProductScopeToFlutterCouponProductScope(
    CouponProductScope scope) {
  return switch (scope) {
    CouponProductScope.allProducts => FlutterCouponProductScope.allProducts,
    CouponProductScope.consumableProducts =>
      FlutterCouponProductScope.consumableProducts,
    CouponProductScope.nonConsumableProducts =>
      FlutterCouponProductScope.nonConsumableProducts,
  };
}

FlutterCouponUserStatus _mapCouponUserStatusToFlutterCouponUserStatus(
    CouponUserStatus status) {
  return switch (status) {
    CouponUserStatus.active => FlutterCouponUserStatus.active,
    CouponUserStatus.expired => FlutterCouponUserStatus.expired,
    CouponUserStatus.redeemed => FlutterCouponUserStatus.redeemed,
    CouponUserStatus.notActivated => FlutterCouponUserStatus.notActivated,
  };
}

FlutterProductType? _mapProductTypeToFlutterProductType(
    ProductType? productType) {
  return switch (productType) {
    ProductType.consumable => FlutterProductType.consumableProduct,
    ProductType.nonConsumable => FlutterProductType.nonConsumableProduct,
    ProductType.subscription => FlutterProductType.subscriptionProduct,
    ProductType.undefined => FlutterProductType.undefined,
    null => null,
  };
}

FlutterPreferredPurchaseType? _mapFlutterPurchaseTypeToPreferredPurchaseType(
    PreferredPurchaseType? flutterPurchaseType) {
  return switch (flutterPurchaseType) {
    PreferredPurchaseType.oneStep => FlutterPreferredPurchaseType.oneStep,
    PreferredPurchaseType.twoStep => FlutterPreferredPurchaseType.twoStep,
    null => null
  };
}

FlutterPurchaseStatus? _mapPurchaseStatusToFlutterPurchaseStatus(
    PurchaseStatus? purchaseStatus) {
  return switch (purchaseStatus) {
    ProductPurchaseStatus.invoiceCreated =>
      FlutterPurchaseStatus.invoiceCreated,
    ProductPurchaseStatus.cancelled => FlutterPurchaseStatus.cancelled,
    ProductPurchaseStatus.processing => FlutterPurchaseStatus.processing,
    ProductPurchaseStatus.rejected => FlutterPurchaseStatus.rejected,
    ProductPurchaseStatus.confirmed => FlutterPurchaseStatus.confirmed,
    ProductPurchaseStatus.refunded => FlutterPurchaseStatus.refunded,
    ProductPurchaseStatus.paid => FlutterPurchaseStatus.paid,
    ProductPurchaseStatus.reversed => FlutterPurchaseStatus.reversed,
    ProductPurchaseStatus.refunding => FlutterPurchaseStatus.refunding,
    ProductPurchaseStatus.executing => FlutterPurchaseStatus.executing,
    ProductPurchaseStatus.expired => FlutterPurchaseStatus.expired,
    SubscriptionPurchaseStatus.invoiceCreated =>
      FlutterPurchaseStatus.invoiceCreated,
    SubscriptionPurchaseStatus.cancelled => FlutterPurchaseStatus.cancelled,
    SubscriptionPurchaseStatus.expired => FlutterPurchaseStatus.expired,
    SubscriptionPurchaseStatus.processing => FlutterPurchaseStatus.processing,
    SubscriptionPurchaseStatus.rejected => FlutterPurchaseStatus.rejected,
    SubscriptionPurchaseStatus.active => FlutterPurchaseStatus.active,
    SubscriptionPurchaseStatus.paused => FlutterPurchaseStatus.paused,
    SubscriptionPurchaseStatus.terminated => FlutterPurchaseStatus.terminated,
    SubscriptionPurchaseStatus.closed => FlutterPurchaseStatus.closed,
    ProductPurchaseStatus.unknown => null,
    SubscriptionPurchaseStatus.unknown => null,
    null => null,
  };
}

FlutterAcknowledgementState? _mapAcknowledgementStateToFilter(
    AcknowledgementState? acknowledgementState) {
  return switch (acknowledgementState) {
    AcknowledgementState.pending => FlutterAcknowledgementState.pending,
    AcknowledgementState.acknowledged =>
      FlutterAcknowledgementState.acknowledged,
    AcknowledgementState.unknown => null,
    null => null,
  };
}

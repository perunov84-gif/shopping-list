import 'package:flutter/cupertino.dart';
import 'package:flutter_rustore_pay/api/purchase_event_listener.dart';

// Пример реализации PurchaseEventListener
class PurchaseEventListenerStub implements PurchaseEventListener {
  static const String _logTag = 'RuStorePayPurchaseCallbacks';

  @override
  void onPurchaseCreated(String purchaseId, String invoiceId) {
    // Сделайте свою реализацию
    debugPrint('$_logTag onPurchaseCreated invoked');
  }

  @override
  void onPaymentStarted(String purchaseId, String invoiceId) {
    // Сделайте свою реализацию
    debugPrint('$_logTag onPaymentStarted invoked');
  }

  @override
  void onPaymentCompleted(String purchaseId, String invoiceId) {
    // Сделайте свою реализацию
    debugPrint('$_logTag onPaymentCompleted invoked');
  }

  @override
  void onPaymentFailed(String purchaseId, String invoiceId) {
    // Сделайте свою реализацию
    debugPrint('$_logTag onPaymentFailed invoked');
  }

  @override
  void onPurchaseCancelled(String purchaseId, String invoiceId) {
    // Сделайте свою реализацию
    debugPrint('$_logTag onPurchaseCancelled invoked');
  }
}
abstract class PurchaseEventListener {
  void onPurchaseCreated(String purchaseId, String invoiceId);
  void onPaymentStarted(String purchaseId, String invoiceId);
  void onPaymentCompleted(String purchaseId, String invoiceId);
  void onPaymentFailed(String purchaseId, String invoiceId);
  void onPurchaseCancelled(String purchaseId, String invoiceId);
}
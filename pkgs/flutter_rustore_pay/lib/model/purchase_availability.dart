/// Результат доступности работы платежей.
sealed class PurchaseAvailabilityResult {}

final class Available extends PurchaseAvailabilityResult {
  /// Результат доступности работы с платежами. Имеет переопределенный метод toString().
  Available();

  @override
  String toString() => '$Available';
}

final class Unavailable extends PurchaseAvailabilityResult {
  final String? errorMessage;

  /// Результат недоступности работы с платежами. Имеет переопределенный метод toString().
  Unavailable({required this.errorMessage});

  @override
  String toString() => '$Unavailable(exception: $errorMessage)';
}

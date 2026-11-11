/// Статус авторизации пользователя
sealed class UserAuthorizationStatus {}

final class Authorized extends UserAuthorizationStatus {
  /// Пользователь авторизован в RuStore.
  Authorized();

  @override
  String toString() => '$Authorized';
}

final class Unauthorized extends UserAuthorizationStatus {
  /// Пользователь неавторизован в RuStore. Данное значение также вернется если у пользователя нет установленного МП RuStore на девайсе.
  Unauthorized();

  @override
  String toString() => '$Unauthorized';
}
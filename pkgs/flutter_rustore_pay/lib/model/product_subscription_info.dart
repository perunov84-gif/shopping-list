import 'package:flutter_rustore_pay/pigeons/flutter_rustore_pay_api.dart';

/// Модель информации о подписке.
final class SubscriptionInfo {
  final List<SubscriptionPeriod> periods;

  SubscriptionInfo._({
    required this.periods,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SubscriptionInfo && other.periods == periods;
  }

  @override
  int get hashCode => periods.hashCode;

  @override
  String toString() => 'SubscriptionInfo(periods: $periods)';
}

/// Абстрактный класс периода подписки.
sealed class SubscriptionPeriod {
  String get duration;
}

/// Бесплатный период подписки.
final class TrialPeriod implements SubscriptionPeriod {
  @override
  final String duration;
  final String currency;
  final int price;

  TrialPeriod._({
    required this.duration,
    required this.currency,
    required this.price,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TrialPeriod &&
        other.duration == duration &&
        other.currency == currency &&
        other.price == price;
  }

  @override
  int get hashCode => duration.hashCode ^ currency.hashCode ^ price.hashCode;

  @override
  String toString() =>
      'TrialPeriod(duration: $duration, currency: $currency, price: $price)';
}

/// Промо-период подписки.
final class PromoPeriod implements SubscriptionPeriod {
  @override
  final String duration;
  final String currency;
  final int price;

  PromoPeriod._({
    required this.duration,
    required this.currency,
    required this.price,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PromoPeriod &&
        other.duration == duration &&
        other.currency == currency &&
        other.price == price;
  }

  @override
  int get hashCode => duration.hashCode ^ currency.hashCode ^ price.hashCode;

  @override
  String toString() =>
      'PromoPeriod(duration: $duration, currency: $currency, price: $price)';
}

/// Основной период подписки.
final class MainPeriod implements SubscriptionPeriod {
  @override
  final String duration;
  final String currency;
  final int price;

  MainPeriod._({
    required this.duration,
    required this.currency,
    required this.price,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MainPeriod &&
        other.duration == duration &&
        other.currency == currency &&
        other.price == price;
  }

  @override
  int get hashCode => duration.hashCode ^ currency.hashCode ^ price.hashCode;

  @override
  String toString() =>
      'MainPeriod(duration: $duration, currency: $currency, price: $price)';
}

/// Период отсрочки подписки.
final class GracePeriod implements SubscriptionPeriod {
  @override
  final String duration;

  GracePeriod._({
    required this.duration,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GracePeriod && other.duration == duration;
  }

  @override
  int get hashCode => duration.hashCode;

  @override
  String toString() => 'GracePeriod(duration: $duration)';
}

/// Период приостановки подписки.
final class HoldPeriod implements SubscriptionPeriod {
  @override
  final String duration;

  HoldPeriod._({
    required this.duration,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HoldPeriod && other.duration == duration;
  }

  @override
  int get hashCode => duration.hashCode;

  @override
  String toString() => 'HoldPeriod(duration: $duration)';
}

/// Функция для маппинга FlutterSubscriptionInfo в SubscriptionInfo.
SubscriptionInfo? mapFlutterSubscriptionInfoToSubscriptionInfo(
    FlutterSubscriptionInfo? flutterSubscriptionInfo) {
  if (flutterSubscriptionInfo == null) return null;

  return SubscriptionInfo._(
    periods: flutterSubscriptionInfo.periods.map((period) {
      if (period.trialPeriod != null) {
        final trial = period.trialPeriod!;
        return TrialPeriod._(
          duration: trial.duration,
          currency: trial.currency,
          price: trial.price,
        );
      } else if (period.promoPeriod != null) {
        final promo = period.promoPeriod!;
        return PromoPeriod._(
          duration: promo.duration,
          currency: promo.currency,
          price: promo.price,
        );
      } else if (period.mainPeriod != null) {
        final main = period.mainPeriod!;
        return MainPeriod._(
          duration: main.duration,
          currency: main.currency,
          price: main.price,
        );
      } else if (period.gracePeriod != null) {
        final grace = period.gracePeriod!;
        return GracePeriod._(
          duration: grace.duration,
        );
      } else if (period.holdPeriod != null) {
        final hold = period.holdPeriod!;
        return HoldPeriod._(
          duration: hold.duration,
        );
      } else {
        throw UnsupportedError('Unknown subscription period type');
      }
    }).toList(),
  );
}
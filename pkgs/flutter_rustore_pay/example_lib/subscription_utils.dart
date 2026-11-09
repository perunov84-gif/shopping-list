import 'package:flutter_rustore_pay/model/product_subscription_info.dart';

String getFormattedPeriod(String duration) {
  if (duration.startsWith('P')) {
    final value = duration.substring(1, duration.length - 1);
    final unit = duration.substring(duration.length - 1);

    final numValue = int.tryParse(value) ?? 1;

    switch (unit) {
      case 'D':
        return _formatPeriodUnit(numValue, 'день', 'дня', 'дней');
      case 'W':
        return _formatPeriodUnit(numValue, 'неделя', 'недели', 'недель');
      case 'M':
        return _formatPeriodUnit(numValue, 'месяц', 'месяца', 'месяцев');
      case 'Y':
        return _formatPeriodUnit(numValue, 'год', 'года', 'лет');
      default:
        return duration;
    }
  }
  return duration;
}

String _formatPeriodUnit(int value, String one, String two, String many) {
  if (value == 1) return '$value $one';
  if (value >= 2 && value <= 4) return '$value $two';
  return '$value $many';
}

String getPriceWithCurrency(int price, String currency) {
  if (price == 0) {
    return 'Бесплатно';
  }
  final formattedPrice = (price / 100).toStringAsFixed(2);
  return '$formattedPrice $currency';
}

String getPeriodTypeName(SubscriptionPeriod period) {
  return switch (period) {
    TrialPeriod _ => 'Trial',
    PromoPeriod _ => 'Promo',
    MainPeriod _ => 'Main',
    GracePeriod _ => 'Grace',
    HoldPeriod _ => 'Hold',
  };
}

import 'package:flutter_rustore_pay/pigeons/flutter_rustore_pay_api.dart';

/// Модель интервала дат.
final class DateInterval {
  /// Дата начала интервала в формате ISO 8601 (UTC).
  final String startDate;

  /// Дата окончания интервала в формате ISO 8601 (UTC).
  final String endDate;

  DateInterval._({
    required this.startDate,
    required this.endDate,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DateInterval &&
        other.startDate == startDate &&
        other.endDate == endDate;
  }

  @override
  int get hashCode => startDate.hashCode ^ endDate.hashCode;

  @override
  String toString() => 'DateInterval(startDate: $startDate, endDate: $endDate)';
}

DateInterval mapFlutterDateIntervalToDateInterval(
    FlutterDateInterval flutterDateInterval) {
  return DateInterval._(
    startDate: flutterDateInterval.startDate,
    endDate: flutterDateInterval.endDate,
  );
}
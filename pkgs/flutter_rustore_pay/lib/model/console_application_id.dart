import 'package:flutter_rustore_pay/pigeons/flutter_rustore_pay_api.dart';

final class ConsoleApplicationId {
  final String value;

  ConsoleApplicationId({
    required this.value,
  });

  @override
  bool operator ==(covariant ConsoleApplicationId other) {
    if (identical(this, other)) return true;
    return other.value == value;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => '$ConsoleApplicationId(value: $value)';
}

ConsoleApplicationId mapFromFlutterToConsoleApplicationId(FlutterConsoleApplicationId flutterId) {
  return ConsoleApplicationId(value: flutterId.value);
}
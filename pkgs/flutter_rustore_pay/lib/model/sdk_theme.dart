import '../pigeons/flutter_rustore_pay_api.dart';

/// Тема SDK для отображения интерфейса платежей
enum SdkTheme {
  light,
  dark,
}

FlutterSdkTheme? mapSdkThemeToFlutterSdkTheme(SdkTheme? sdkTheme) {
  return switch (sdkTheme) {
    SdkTheme.light => FlutterSdkTheme.light,
    SdkTheme.dark => FlutterSdkTheme.dark,
    null => null,
  };
}
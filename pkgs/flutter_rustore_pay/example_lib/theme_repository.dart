import 'package:flutter/material.dart';
import 'package:flutter_rustore_pay/model/sdk_theme.dart';

/// Репозиторий для управления темой SDK
class ThemeRepository with ChangeNotifier {
  SdkTheme _currentTheme = SdkTheme.light;

  SdkTheme get currentTheme => _currentTheme;

  void setTheme(SdkTheme theme) {
    _currentTheme = theme;
    notifyListeners();
  }
}
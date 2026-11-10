import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'suggestions/suggestion_engine.dart';
import 'data/catalog.dart';
import 'data/database.dart';
import 'data/list_repository.dart';
import 'monetization/ads.dart';
import 'monetization/premium.dart';
import 'services/link_handler.dart';
import 'services/voice_service.dart';
import 'state/lists_store.dart';
import 'state/settings_store.dart';
import 'ui/home_screen.dart';
import 'ui/splash.dart';
import 'ui/theme.dart';

Future<void> main() async {
  final startup = Stopwatch()..start();
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final settings = await SettingsStore.load();
  final db = await AppDatabase.open();
  final repo = ListRepository(db);
  final catalog = await Catalog.load();
  final lists = ListsStore(repo, catalog);
  await lists.load();
  final premium = Premium(settings);
  final ads = AdsService(settings, premium);
  final engine = SuggestionEngine(catalog: catalog, repo: repo);

  final navigatorKey = GlobalKey<NavigatorState>();
  final links = LinkHandler(lists, navigatorKey);

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: settings),
      ChangeNotifierProvider.value(value: lists),
      ChangeNotifierProvider.value(value: premium),
      ChangeNotifierProvider(create: (_) => VoiceService()),
      Provider.value(value: ads),
      Provider.value(value: engine),
      Provider.value(value: catalog),
    ],
    // Заставка видна ~1 секунду с момента запуска (включая время загрузки данных).
    child: ShoppingListApp(splashHold: _splashHold(startup.elapsed), navigatorKey: navigatorKey),
  ));

  // Присланная ссылка на список (приложение открыто из мессенджера).
  await links.init();

  // Магазин и реклама инициализируются после первого кадра, чтобы не тормозить запуск.
  await premium.init();
  await ads.init();
}

Duration _splashHold(Duration elapsed) {
  const total = Duration(milliseconds: 1000);
  final rest = total - elapsed;
  return rest < const Duration(milliseconds: 250) ? const Duration(milliseconds: 250) : rest;
}

class ShoppingListApp extends StatelessWidget {
  const ShoppingListApp({super.key, this.splashHold = const Duration(milliseconds: 800), this.navigatorKey});
  final Duration splashHold;
  final GlobalKey<NavigatorState>? navigatorKey;

  @override
  Widget build(BuildContext context) {
    final dark = context.select<SettingsStore, bool>((s) => s.darkTheme);
    return MaterialApp(
      title: 'Список покупок',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      home: const HomeScreen(),
      builder: (context, child) => SplashOverlay(hold: splashHold, child: child ?? const SizedBox()),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'ai/cloud_suggestions.dart';
import 'ai/suggestion_engine.dart';
import 'data/catalog.dart';
import 'data/database.dart';
import 'data/list_repository.dart';
import 'monetization/ads.dart';
import 'monetization/premium.dart';
import 'services/voice_service.dart';
import 'state/lists_store.dart';
import 'state/settings_store.dart';
import 'ui/home_screen.dart';
import 'ui/theme.dart';

Future<void> main() async {
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
  final engine = SuggestionEngine(catalog: catalog, repo: repo, cloud: CloudSuggestionClient());

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
    child: const ShoppingListApp(),
  ));

  // Магазин и реклама инициализируются после первого кадра, чтобы не тормозить запуск.
  await premium.init();
  await ads.init();
}

class ShoppingListApp extends StatelessWidget {
  const ShoppingListApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Список покупок',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      home: const HomeScreen(),
    );
  }
}

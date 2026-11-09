import 'package:flutter/material.dart';
import 'package:flutter_rustore_pay/model/sdk_theme.dart';
import 'package:flutter_rustore_pay_example/billing_subscription_widget.dart';
import 'package:flutter_rustore_pay_example/coupon_widget.dart';
import 'package:flutter_rustore_pay_example/product_widget.dart';
import 'package:flutter_rustore_pay_example/promotion_widget.dart';
import 'package:flutter_rustore_pay_example/purchase_widget.dart';
import 'package:flutter_rustore_pay_example/theme_repository.dart';
import 'package:flutter_rustore_pay_example/utils_widget.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeRepository(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with SingleTickerProviderStateMixin {
  // define your tab controller here
  late TabController _tabController;

  @override
  void initState() {
    // initialise your tab controller here
    _tabController = TabController(length: 6, vsync: this);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeRepository>(
      builder: (context, themeRepo, child) {
        return MaterialApp(
          theme: themeRepo.currentTheme == SdkTheme.light
              ? ThemeData.light()
              : ThemeData.dark(),
          home: Scaffold(
            appBar: AppBar(
              leading: Icon(
                Icons.menu,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(
                'RuStore Pay Example',
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
              actions: [
                Consumer<ThemeRepository>(
                  builder: (context, themeRepo, child) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: IconButton(
                        icon: Icon(
                          themeRepo.currentTheme == SdkTheme.light
                              ? Icons.light_mode
                              : Icons.dark_mode,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        onPressed: () {
                          final newTheme = themeRepo.currentTheme == SdkTheme.light
                              ? SdkTheme.dark
                              : SdkTheme.light;
                          themeRepo.setTheme(newTheme);
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
            body: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: Colors.green,
                    isScrollable: true,
                    indicatorColor: Colors.transparent,
                    unselectedLabelColor: Colors.grey,
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      fontWeight: FontWeight.w700,
                    ),
                    labelStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    tabs: const <Widget>[
                      Text('PRODUCTS'),
                      Text('PURCHASES'),
                      Text('BILLING'),
                      Text('PROMOTIONS'),
                      Text('COUPONS'),
                      Text('UTILS'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: const <Widget>[
                      ProductWidget(),
                      PurchaseWidget(),
                      BillingSubscriptionWidget(),
                      PromotionWidget(),
                      CouponWidget(),
                      UtilsWidget()
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_rustore_pay/api/flutter_rustore_pay_client.dart';
import 'package:flutter_rustore_pay/model/preferred_purchase_type.dart';
import 'package:flutter_rustore_pay/model/product.dart';
import 'package:flutter_rustore_pay/model/product_type.dart';
import 'package:flutter_rustore_pay/model/ru_store_exception.dart';
import 'package:flutter_rustore_pay_example/purchase_event_listener_stub.dart';
import 'package:flutter_rustore_pay_example/theme_repository.dart';
import 'package:provider/provider.dart';

import 'subscription_dialog.dart';

final List<String> ids = ["product_1", "product_2", "product_3"];

class ProductWidget extends StatefulWidget {
  const ProductWidget({super.key});

  @override
  State<ProductWidget> createState() => _ProductWidgetState();
}

class _ProductWidgetState extends State<ProductWidget> {
  List<Product?> products = [];

  void _showToast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  FutureOr<Null> _handlePurchaseError(Object error) {
    if (!mounted) return null;
    String? purchaseId;
    String message;
    if (error is RuStorePurchaseCancelledException) {
      purchaseId = error.purchaseId;
      message =
          "Отмена покупки: [Message: ${error.message ?? 'Неизвестная ошибка'}]";
    } else if (error is RuStoreProductPurchaseException) {
      purchaseId = error.purchaseId;
      message =
          "Ошибка покупки:  [Message: ${error.message ?? 'Неизвестная ошибка'}]";
    } else {
      message = "Неизвестная ошибка: $error";
    }
    if (purchaseId != null) message += ", [purchaseId: $purchaseId]";
    _showToast(message);
    return null;
  }

  Future<void> _purchase(String id, PreferredPurchaseType preferredPurchaseType) async {
    try {
      final themeRepo = Provider.of<ThemeRepository>(context, listen: false);
      await RuStorePayClient.instance.purchaseInteractor.purchase(
        id,
        preferredPurchaseType: preferredPurchaseType,
        sdkTheme: themeRepo.currentTheme,
        purchaseEventListener: PurchaseEventListenerStub(),
      );
      if (!mounted) return;
      if (preferredPurchaseType == PreferredPurchaseType.oneStep) {
        _showToast("Одностадийная покупка прошла успешно");
      } else {
        _showToast("Двустадийная покупка прошла успешно, теперь необходимо подтвердить ее, для этого перейдите в покупки");
      }

    } catch (error) {
      _handlePurchaseError(error);
    }
  }

  Future<void> _purchaseTwoStep(String id) async {
    try {
      final themeRepo = Provider.of<ThemeRepository>(context, listen: false);
      await RuStorePayClient.instance.purchaseInteractor.purchaseTwoStep(
        id,
        sdkTheme: themeRepo.currentTheme,
        purchaseEventListener: PurchaseEventListenerStub(),
      );
      if (!mounted) return;
      _showToast(
          "Двустадийная покупка прошла успешно, теперь необходимо подтвердить ее, для этого перейдите в покупки");
    } catch (error) {
      _handlePurchaseError(error);
    }
  }

  @override
  void initState() {
    super.initState();
    _reloadProducts();
    _getUserAuthorizationStatus();
  }

  Future<void> _getUserAuthorizationStatus() async {
    try {
      final value = await RuStorePayClient.instance.userInteractor
          .getUserAuthorizationStatus();
      _showToast(value.toString());
    } catch (err) {
      _showToast(err.toString());
    }
  }

  Future<void> _reloadProducts() async {
    final products =
        await RuStorePayClient.instance.productInteractor.getProducts(ids);
    if (!mounted) return;
    setState(() {
      this.products = products;
    });
  }

  Widget _buildText(String text,
      {double fontSize = 16,
      FontWeight fontWeight = FontWeight.normal,
      Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color ?? Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  void _showDialogWithButtons(String productId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выбери метод покупки'),
        actions: [
          TextButton(
            child: const Text('purchaseOneStep'),
            onPressed: () {
              Navigator.of(context).pop();
              _purchase(productId, PreferredPurchaseType.oneStep);
            },
          ),
          TextButton(
            child: const Text('purchasePreferredTwoStep'),
            onPressed: () {
              Navigator.of(context).pop();
              _purchase(productId, PreferredPurchaseType.twoStep);
            },
          ),
          TextButton(
            child: const Text('purchaseTwoStep'),
            onPressed: () {
              Navigator.of(context).pop();
              _purchaseTwoStep(productId);
            },
          ),
        ],
      ),
    );
  }

  void _showSubscriptionInfoDialog(Product product) {
    showDialog(
      context: context,
      builder: (context) => SubscriptionDialog(product: product),
    );
  }

  Widget _buildItem(Product product) {
    final isSubscription = product.type == ProductType.subscription;
    final hasSubscriptionInfo = product.subscriptionInfo != null;
    final showInfoIcon = isSubscription && hasSubscriptionInfo;

    return InkWell(
      onTap: () => _showDialogWithButtons(product.productId),
      child: Card(
        margin: const EdgeInsets.all(8.0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок с иконкой информации
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _buildText(
                      'Name: ${product.title}',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (showInfoIcon)
                    IconButton(
                      icon: const Icon(
                        Icons.info_outline,
                        color: Colors.blue,
                      ),
                      onPressed: () => _showSubscriptionInfoDialog(product),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      iconSize: 28,
                    ),
                ],
              ),
              _buildText('Desc: ${product.description ?? ""}'),
              _buildText('Type: ${product.type.name}'),
              _buildText('AmountLabel: ${product.amountLabel}'),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          for (final product in products)
            if (product != null) _buildItem(product),
        ],
      ),
    );
  }
}

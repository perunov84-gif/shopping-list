import 'package:flutter/material.dart';
import 'package:flutter_rustore_pay/api/flutter_rustore_pay_client.dart';
import 'package:flutter_rustore_pay/model/purchase.dart';

/// Пример получения подписок от SDK Billing Client.
/// Важно: SDK предоставляет API, но решение о том, когда и при каких условиях
/// вызывать этот метод, полностью зависит от бизнес-логики вашего приложения.
class BillingSubscriptionWidget extends StatefulWidget {
  const BillingSubscriptionWidget({super.key});

  @override
  State<BillingSubscriptionWidget> createState() => _BillingSubscriptionWidgetState();
}

class _BillingSubscriptionWidgetState extends State<BillingSubscriptionWidget> {
  List<BillingSubscription> _subscriptions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _reloadSubscriptions();
  }

  Future<void> _reloadSubscriptions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final subscriptions = await RuStorePayClient.instance.purchaseInteractor.getBillingSubscriptions();
      if (mounted) {
        setState(() {
          _subscriptions = subscriptions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Ошибка при загрузке подписок от SDK Billing Client: $e';
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildText(String text, {double fontSize = 16, FontWeight fontWeight = FontWeight.normal, Color? color}) {
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

  Widget _buildItem(BillingSubscription subscription) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildText('ProductId: ${subscription.productId}', fontWeight: FontWeight.bold),
            _buildText('Дата истечения: ${subscription.expirationDate}'),
            _buildText('Льготный период: ${subscription.gracePeriodEnabled ? 'включён' : 'выключен'}'),
            const SizedBox(height: 8),
            _buildText('Статус: ${subscription.status.name}'),
            _buildText('Тип покупки: ${subscription.purchaseType.name}'),
            _buildText('ID покупки: ${subscription.purchaseId}'),
            _buildText('Цена: ${subscription.amountLabel}'),
            const SizedBox(height: 8),
            // subscriptionToken используется для валидации подписки на вашем сервере.
            _buildText('Токен подписки: ${subscription.subscriptionToken}', fontSize: 14),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text(_error!, style: const TextStyle(color: Colors.red)));
    }

    if (_subscriptions.isEmpty) {
      return const Center(child: Text("Нет подписок от SDK Billing Client"));
    }

    return RefreshIndicator(
      onRefresh: _reloadSubscriptions,
      child: ListView.builder(
        itemCount: _subscriptions.length,
        itemBuilder: (context, index) {
          final subscription = _subscriptions[index];
          return _buildItem(subscription);
        },
      ),
    );
  }
}

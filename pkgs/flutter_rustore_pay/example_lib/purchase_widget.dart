import 'package:flutter/material.dart';
import 'package:flutter_rustore_pay/api/flutter_rustore_pay_client.dart';
import 'package:flutter_rustore_pay/model/acknowledgement_state.dart';
import 'package:flutter_rustore_pay/model/purchase.dart';
import 'package:flutter_rustore_pay/model/purchase_type.dart';

class PurchaseWidget extends StatefulWidget {
  const PurchaseWidget({super.key});

  @override
  State<PurchaseWidget> createState() => _PurchaseWidgetState();
}

class _PurchaseWidgetState extends State<PurchaseWidget> {
  List<Purchase> _purchases = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _reloadPurchases();
  }

  Future<void> _reloadPurchases() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final purchases = await RuStorePayClient.instance.purchaseInteractor.getPurchases();
      final validPurchases = purchases.whereType<Purchase>().toList();
      if (mounted) {
        setState(() {
          _purchases = validPurchases;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Ошибка загрузки покупок: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _confirmTwoStepPurchase(String id) async {
    try {
      await RuStorePayClient.instance.purchaseInteractor.confirmTwoStepPurchase(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Покупка успешно подтверждена"),
        ));
      }
      _reloadPurchases(); // Перезагружаем список, чтобы обновить статус
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Ошибка подтверждения: $e"),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _cancelTwoStepPurchase(String id) async {
    try {
      await RuStorePayClient.instance.purchaseInteractor.cancelTwoStepPurchase(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Покупка успешно отменена"),
        ));
      }
      _reloadPurchases(); // Перезагружаем список, чтобы обновить статус
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Ошибка отмены: $e"),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _updateAcknowledgementState(
      String id, AcknowledgementState newState) async {
    try {
      final state = await RuStorePayClient.instance.purchaseInteractor
          .updateAcknowledgementState(id, newState);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Состояние выдачи товара: ${state.name}"),
        ));
      }
      _reloadPurchases(); // Перезагружаем список, чтобы обновить статус
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Ошибка изменения состояния выдачи: $e"),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  void _purchaseInfo(String id) async {
    final value = await RuStorePayClient.instance.purchaseInteractor.getPurchase(id);
    print('purchaseInfo: $value');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Информация о покупке выведена в консоль"),
      ));
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

  Widget _buildAcknowledgementChip(AcknowledgementState state) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final (String label, IconData icon, Color lightColor, Color darkColor) =
        switch (state) {
      AcknowledgementState.pending => (
          'PENDING',
          Icons.hourglass_bottom,
          Colors.orange,
          Colors.orangeAccent
        ),
      AcknowledgementState.acknowledged => (
          'ACKNOWLEDGED',
          Icons.check_circle,
          Colors.green,
          Colors.greenAccent
        ),
      AcknowledgementState.unknown => (
          'UNKNOWN',
          Icons.help_outline,
          Colors.grey,
          Colors.grey
        ),
    };

    final Color color = isDark ? darkColor : lightColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: color.withValues(alpha: 0.6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              'Выдача товара: $label',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(Purchase purchase) {
    final String productId;
    final String specificInfo;

    if (purchase is ProductPurchase) {
      productId = purchase.productId;
      specificInfo = 'Тип продукта: ${purchase.productType.name}, Количество: ${purchase.quantity}';
    } else if (purchase is SubscriptionPurchase) {
      productId = purchase.productId;
      specificInfo = 'Дата истечения: ${purchase.expirationDate}';
    } else {
      productId = 'N/A';
      specificInfo = 'Неизвестный тип покупки';
    }

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildText('ProductId: $productId', fontWeight: FontWeight.bold),
            _buildText(specificInfo),
            const SizedBox(height: 8),
            _buildText('Статус: ${purchase.status.runtimeType}'),
            _buildText('Тип покупки: ${purchase.purchaseType.name}'),
            _buildText('ID покупки: ${purchase.purchaseId}'),
            _buildAcknowledgementChip(purchase.acknowledgementState),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.spaceAround,
              children: [
                OutlinedButton(
                  onPressed: () => _purchaseInfo(purchase.purchaseId),
                  child: const Text('Инфо'),
                ),
                // Показываем кнопки только для двухшаговых покупок в статусе PAID
                if (purchase.purchaseType == PurchaseType.twoStep && purchase.status == ProductPurchaseStatus.paid)
                  OutlinedButton(
                    onPressed: () => _confirmTwoStepPurchase(purchase.purchaseId),
                    child: const Text('Подтвердить'),
                  ),
                if (purchase.purchaseType == PurchaseType.twoStep && purchase.status == ProductPurchaseStatus.paid)
                  OutlinedButton(
                    onPressed: () => _cancelTwoStepPurchase(purchase.purchaseId),
                    child: const Text('Отменить'),
                  ),
                if (purchase.acknowledgementState == AcknowledgementState.pending)
                  OutlinedButton(
                    onPressed: () => _updateAcknowledgementState(
                        purchase.purchaseId, AcknowledgementState.acknowledged),
                    child: const Text('Подтвердить выдачу'),
                  ),
                if (purchase.acknowledgementState ==
                    AcknowledgementState.acknowledged)
                  OutlinedButton(
                    onPressed: () => _updateAcknowledgementState(
                        purchase.purchaseId, AcknowledgementState.pending),
                    child: const Text('Вернуть в PENDING'),
                  ),
              ],
            ),
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

    if (_purchases.isEmpty) {
      return const Center(child: Text("Нет доступных покупок"));
    }

    return RefreshIndicator(
      onRefresh: _reloadPurchases,
      child: ListView.builder(
        itemCount: _purchases.length,
        itemBuilder: (context, index) {
          final purchase = _purchases[index];
          return _buildItem(purchase);
        },
      ),
    );
  }
}

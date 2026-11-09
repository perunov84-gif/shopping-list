import 'package:flutter/material.dart';
import 'package:flutter_rustore_pay/model/product.dart';

import 'subscription_period_item.dart';

class SubscriptionDialog extends StatelessWidget {
  final Product product;

  const SubscriptionDialog({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    final subscriptionInfo = product.subscriptionInfo;

    if (subscriptionInfo == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      title: Text(
        'Информация о подписке',
        style: TextStyle(color: theme.colorScheme.onSurface),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.title,
              style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 8),
            if (product.description != null)
              Text(
                product.description!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: 16),
            Text(
              'Периоды подписки:',
              style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final period in subscriptionInfo.periods)
                      SubscriptionPeriodItem(period: period),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Закрыть',
            style: TextStyle(color: theme.colorScheme.primary),
          ),
        ),
      ],
    );
  }
}

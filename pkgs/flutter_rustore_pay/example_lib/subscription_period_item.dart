import 'package:flutter/material.dart';
import 'package:flutter_rustore_pay/model/product_subscription_info.dart';

import 'subscription_utils.dart';

class SubscriptionPeriodItem extends StatelessWidget {
  final SubscriptionPeriod period;

  const SubscriptionPeriodItem({
    super.key,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            getPeriodTypeName(period),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildPeriodDetails(period),
        ],
      ),
    );
  }

  Widget _buildPeriodDetails(SubscriptionPeriod period) {
    return switch (period) {
      TrialPeriod trial => _buildPricePeriod(
          duration: trial.duration,
          price: trial.price,
          currency: trial.currency,
        ),
      PromoPeriod promo => _buildPricePeriod(
          duration: promo.duration,
          price: promo.price,
          currency: promo.currency,
        ),
      MainPeriod main => _buildPricePeriod(
          duration: main.duration,
          price: main.price,
          currency: main.currency,
        ),
      GracePeriod grace => _buildPricePeriod(
          duration: grace.duration,
          price: 0,
          currency: '',
        ),
      HoldPeriod hold => _buildPricePeriod(
          duration: hold.duration,
          price: 0,
          currency: '',
        ),
    };
  }

  Widget _buildPricePeriod({
    required String duration,
    required int price,
    required String currency,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          getFormattedPeriod(duration),
          style: const TextStyle(fontSize: 16),
        ),
        Text(
          getPriceWithCurrency(price, currency),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

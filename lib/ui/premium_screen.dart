import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_config.dart';
import '../monetization/premium.dart';
import 'widgets/wide_button.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<Premium>();
    final t = Theme.of(context);
    Widget benefit(IconData i, String title, String sub) => ListTile(
          leading: CircleAvatar(backgroundColor: t.colorScheme.primaryContainer, child: Icon(i, color: t.colorScheme.primary)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(sub),
        );
    return Scaffold(
      appBar: AppBar(title: const Text('VIP')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Icon(Icons.star_rounded, size: 88, color: t.colorScheme.primary),
        const SizedBox(height: 8),
        Text(p.isVip ? 'У вас VIP — спасибо!' : 'VIP навсегда',
            textAlign: TextAlign.center, style: t.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('Всего ${p.price ?? AppConfig.vipFallbackPrice} — одна покупка навсегда, без подписок', textAlign: TextAlign.center, style: t.textTheme.bodyMedium),
        const SizedBox(height: 16),
        benefit(Icons.block, 'Без рекламы', 'Никаких баннеров и всплывающей рекламы'),
        benefit(Icons.favorite_outline, 'Поддержка разработки', 'Помогаете приложению развиваться'),
        const SizedBox(height: 24),
        if (!p.isVip) ...[
          WideButton(
            icon: Icons.star_rounded,
            label: 'Купить VIP за ${p.price ?? AppConfig.vipFallbackPrice}',
            busy: p.busy,
            onPressed: p.storeAvailable ? p.buy : null,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: p.busy || !p.storeAvailable
                ? null
                : () async {
                    final ok = await p.restore();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(ok ? 'Покупка восстановлена' : 'Покупки не найдены')));
                    }
                  },
            child: const Text('Восстановить покупку'),
          ),
          if (!p.storeAvailable)
            Text(
              AppConfig.isRuStore
                  ? 'Оплата будет доступна после публикации приложения в RuStore.'
                  : 'Оплата будет доступна после публикации в магазине приложений.',
              textAlign: TextAlign.center,
              style: t.textTheme.bodySmall,
            ),
          if (p.lastError != null)
            Text(p.lastError!, textAlign: TextAlign.center, style: TextStyle(color: t.colorScheme.error)),
        ],
      ]),
    );
  }
}

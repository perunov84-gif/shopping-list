import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../app_config.dart';
import '../monetization/premium.dart';
import '../state/lists_store.dart';
import '../state/settings_store.dart';
import 'premium_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _taps = 0;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsStore>();
    final p = context.watch<Premium>();
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(children: [
        Card(
          child: ListTile(
            leading: Icon(Icons.workspace_premium, color: t.colorScheme.primary),
            title: Text(p.isVip ? 'VIP активен' : 'VIP: без рекламы'),
            subtitle: Text(p.isVip ? 'Спасибо за поддержку!' : 'Разовая покупка, навсегда'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PremiumScreen())),
          ),
        ),
        const _Header('Ассистент'),
        SwitchListTile(
          secondary: const Icon(Icons.auto_awesome),
          title: const Text('Подсказки «не забыть купить»'),
          subtitle: const Text('Например: гвозди → молоток'),
          value: s.suggestionsEnabled,
          onChanged: (v) => s.suggestionsEnabled = v,
        ),
        SwitchListTile(
          secondary: const Icon(Icons.psychology_alt_outlined),
          title: const Text('Облачный ИИ (VIP)'),
          subtitle: const Text('Состав списка отправляется на сервер для подсказок'),
          value: p.isVip && s.cloudAiEnabled,
          onChanged: p.isVip ? (v) => s.cloudAiEnabled = v : null,
        ),
        ListTile(
          leading: const Icon(Icons.delete_sweep_outlined),
          title: const Text('Очистить историю покупок'),
          subtitle: const Text('Ассистент забудет ваши привычки'),
          onTap: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Очистить историю?'),
                content: const Text('Списки останутся, но подсказки и «частые товары» начнутся с нуля.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
                  FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Очистить')),
                ],
              ),
            );
            if (ok == true && context.mounted) {
              await context.read<ListsStore>().clearMemory();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('История очищена')));
              }
            }
          },
        ),
        const _Header('О приложении'),
        ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: const Text('Политика конфиденциальности'),
          subtitle: const Text(AppConfig.privacyPolicyUrl, maxLines: 1, overflow: TextOverflow.ellipsis),
          onTap: () {
            Clipboard.setData(const ClipboardData(text: AppConfig.privacyPolicyUrl));
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ссылка скопирована')));
          },
        ),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('Список покупок'),
          subtitle: Text('Версия 1.0.0 · сборка ${AppConfig.store}'),
          onTap: () {
            // Скрытый переключатель VIP для тестирования: 7 касаний по версии.
            if (!AppConfig.testBuild) return;
            if (++_taps >= 7) {
              _taps = 0;
              p.debugSetVip(!p.isVip);
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(p.isVip ? 'Тест: VIP включён' : 'Тест: VIP выключен')));
            }
          },
        ),
      ]),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
        child: Text(text, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.primary)),
      );
}

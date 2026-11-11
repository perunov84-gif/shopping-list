import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../app_config.dart';
import '../monetization/premium.dart';
import '../services/backup_service.dart';
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

  Future<void> _export() async {
    final bytes = BackupService(context.read<ListsStore>()).exportJson();
    final date = DateTime.now().toIso8601String().substring(0, 10);
    await SharePlus.instance.share(ShareParams(
      files: [XFile.fromData(bytes, mimeType: 'application/json', name: 'shopping-lists-$date.json')],
      fileNameOverrides: ['shopping-lists-$date.json'],
      subject: 'Резервная копия списков покупок',
    ));
  }

  Future<void> _import() async {
    final messenger = ScaffoldMessenger.of(context);
    final backup = BackupService(context.read<ListsStore>());
    try {
      final file = await FilePicker.pickFile();
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final n = await backup.importJson(bytes);
      messenger.showSnackBar(SnackBar(content: Text('Восстановлено списков: $n')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Не удалось восстановить: $e')));
    }
  }

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
            leading: Icon(Icons.star_rounded, color: t.colorScheme.primary),
            title: Text(p.isVip ? 'VIP активен' : 'VIP: без рекламы'),
            subtitle: Text(p.isVip ? 'Спасибо за поддержку!' : 'Всего ${p.price ?? AppConfig.vipFallbackPrice}, навсегда'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PremiumScreen())),
          ),
        ),
        const _Header('Оформление'),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, icon: Icon(Icons.light_mode_outlined), label: Text('Светлая')),
              ButtonSegment(value: true, icon: Icon(Icons.dark_mode_outlined), label: Text('Тёмная')),
            ],
            selected: {s.darkTheme},
            onSelectionChanged: (v) => s.darkTheme = v.first,
          ),
        ),
        const _Header('Подсказки'),
        SwitchListTile(
          secondary: const Icon(Icons.auto_awesome),
          title: const Text('Подсказки «не забыть купить»'),
          subtitle: const Text('Например: гвозди → молоток'),
          value: s.suggestionsEnabled,
          onChanged: (v) => s.suggestionsEnabled = v,
        ),
        ListTile(
          leading: const Icon(Icons.delete_sweep_outlined),
          title: const Text('Очистить историю покупок'),
          subtitle: const Text('Подсказки и «частые товары» начнутся с нуля'),
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
        const _Header('Резервная копия'),
        ListTile(
          leading: const Icon(Icons.upload_file_outlined),
          title: const Text('Сохранить все списки в файл'),
          subtitle: const Text('Для переноса на новый телефон'),
          onTap: _export,
        ),
        ListTile(
          leading: const Icon(Icons.download_outlined),
          title: const Text('Восстановить из файла'),
          subtitle: const Text('Списки добавятся к текущим'),
          onTap: _import,
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/catalog.dart';
import '../models/shop_list.dart';
import '../monetization/ads.dart';
import '../monetization/premium.dart';
import '../services/backup_service.dart';
import '../services/voice_router.dart';
import '../state/lists_store.dart';
import 'list_screen.dart';
import 'premium_screen.dart';
import 'settings_screen.dart';
import 'theme.dart';
import 'widgets/new_list_sheet.dart';
import 'widgets/share_sheet.dart';
import 'widgets/voice_sheet.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _openList(BuildContext context, ShopList list) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ListScreen(listId: list.id)));
    if (context.mounted && list.isDone) {
      await context.read<AdsService>().maybeShowInterstitial();
    }
  }

  Future<void> _create(BuildContext context) async {
    final created = await showNewListSheet(context);
    if (created != null && context.mounted) await _openList(context, created);
  }

  Future<void> _quickVoice(BuildContext context) async {
    final text = await showVoiceSheet(context,
        hint: 'Скажите, например:\n«В строительный гвозди и молоток, в аптеку пластырь»');
    if (text == null || text.trim().isEmpty || !context.mounted) return;
    final router = VoiceRouter(context.read<ListsStore>(), context.read<Catalog>());
    final res = await router.route(text);
    if (!context.mounted) return;
    final msg = res.isEmpty
        ? 'Не удалось распознать товары'
        : res.entries.map((e) => '«${e.key.name}»: +${e.value}').join(', ');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      action: res.length == 1
          ? SnackBarAction(label: 'Открыть', onPressed: () => _openList(context, res.keys.first))
          : null,
    ));
  }

  /// Список, которым поделились текстом (мессенджер, заметки), — из буфера обмена.
  Future<void> _pasteList(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text ?? '';
    if (!context.mounted) return;
    if (text.trim().isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('Скопируйте список (например, из мессенджера) и повторите')));
      return;
    }
    final n = await BackupService(context.read<ListsStore>()).importText(text);
    messenger.showSnackBar(SnackBar(content: Text(n == 0 ? 'В буфере нет товаров' : 'Создан список: $n поз.')));
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ListsStore>();
    final premium = context.watch<Premium>();
    final lists = store.lists;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои списки', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          if (!premium.isVip)
            IconButton(
              tooltip: 'VIP без рекламы',
              icon: const Icon(Icons.workspace_premium_outlined),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PremiumScreen())),
            ),
          IconButton(
            tooltip: 'Вставить список из буфера',
            icon: const Icon(Icons.content_paste_go),
            onPressed: () => _pasteList(context),
          ),
          IconButton(
            tooltip: 'Настройки',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: !store.loaded
          ? const Center(child: CircularProgressIndicator())
          : lists.isEmpty
              ? _EmptyState(onCreate: () => _create(context), onVoice: () => _quickVoice(context))
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 4, bottom: 96),
                  itemCount: lists.length,
                  itemBuilder: (_, i) => _ListCard(list: lists[i], onOpen: () => _openList(context, lists[i])),
                ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: lists.isEmpty
          ? null
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FloatingActionButton.small(
                    heroTag: 'voice',
                    tooltip: 'Добавить голосом',
                    onPressed: () => _quickVoice(context),
                    child: const Icon(Icons.mic_none),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FloatingActionButton.extended(
                      heroTag: 'new',
                      onPressed: () => _create(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Новый список'),
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: AdBanner(premium: premium),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate, required this.onVoice});
  final VoidCallback onCreate;
  final VoidCallback onVoice;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_basket_outlined, size: 96, color: t.colorScheme.primary),
            const SizedBox(height: 16),
            Text('Пока нет списков', style: t.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Создайте список для магазина или просто скажите, что купить — '
              'я сам разложу товары по магазинам.',
              textAlign: TextAlign.center,
              style: t.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(onPressed: onCreate, icon: const Icon(Icons.add), label: const Text('Создать список')),
            const SizedBox(height: 8),
            OutlinedButton.icon(onPressed: onVoice, icon: const Icon(Icons.mic_none), label: const Text('Надиктовать')),
          ],
        ),
      ),
    );
  }
}

class _ListCard extends StatelessWidget {
  const _ListCard({required this.list, required this.onOpen});
  final ShopList list;
  final VoidCallback onOpen;

  Future<void> _menu(BuildContext context) async {
    final store = context.read<ListsStore>();
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(leading: const Icon(Icons.share_outlined), title: const Text('Отправить список'), subtitle: const Text('Ссылкой в Telegram, WhatsApp…'), onTap: () => Navigator.pop(ctx, 'share')),
          ListTile(leading: const Icon(Icons.edit_outlined), title: const Text('Переименовать'), onTap: () => Navigator.pop(ctx, 'rename')),
          ListTile(leading: const Icon(Icons.copy_outlined), title: const Text('Повторить список'), subtitle: const Text('Копия без галочек'), onTap: () => Navigator.pop(ctx, 'dup')),
          ListTile(
              leading: Icon(Icons.delete_outline, color: Theme.of(ctx).colorScheme.error),
              title: const Text('Удалить'),
              onTap: () => Navigator.pop(ctx, 'delete')),
        ]),
      ),
    );
    if (!context.mounted) return;
    switch (action) {
      case 'share':
        await showShareSheet(context, list);
      case 'rename':
        await showEditListSheet(context, list);
      case 'dup':
        await store.duplicate(list);
      case 'delete':
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Удалить список?'),
            content: Text('«${list.name}» будет удалён без возможности восстановления.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Удалить')),
            ],
          ),
        );
        if (ok == true) await store.deleteList(list);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final c = list.category;
    final tint = c.tint(context);
    final subtitle = list.total == 0
        ? 'Пустой список'
        : list.isDone
            ? 'Всё куплено ✓'
            : 'Куплено ${list.checkedCount} из ${list.total}';
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        onLongPress: () => _menu(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
          child: Row(children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: tint.withValues(alpha: 0.15),
              child: Icon(c.icon, color: tint),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(list.name, style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(subtitle, style: t.textTheme.bodySmall),
                if (list.total > 0) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(value: list.progress, minHeight: 5, color: tint, backgroundColor: tint.withValues(alpha: 0.12)),
                  ),
                ],
              ]),
            ),
            IconButton(icon: const Icon(Icons.more_vert), onPressed: () => _menu(context)),
          ]),
        ),
      ),
    );
  }
}

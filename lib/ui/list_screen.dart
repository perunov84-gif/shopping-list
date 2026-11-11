import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../suggestions/suggestion.dart';
import '../suggestions/suggestion_engine.dart';
import '../data/catalog.dart';
import '../models/list_item.dart';
import '../models/shop_list.dart';
import '../monetization/ads.dart';
import '../monetization/premium.dart';
import '../state/lists_store.dart';
import '../state/settings_store.dart';
import 'theme.dart';
import 'widgets/add_bar.dart';
import 'widgets/new_list_sheet.dart';
import 'widgets/share_sheet.dart';
import 'widgets/suggestion_strip.dart';
import 'widgets/wide_button.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({super.key, required this.listId, this.initialShopMode = false, this.receivedNotice = false});
  final int listId;

  /// Присланный список открывается сразу в режиме «в магазине».
  final bool initialShopMode;
  final bool receivedNotice;

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  late bool _shopMode = widget.initialShopMode;
  bool _assistantHidden = false;
  bool _preShopShown = false;
  List<Suggestion> _suggestions = const [];
  String _signature = '';
  Timer? _debounce;
  late final ListsStore _store = context.read<ListsStore>();

  @override
  void initState() {
    super.initState();
    _store.addListener(_onStoreChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _onStoreChanged();
      if (widget.receivedNotice && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Вам прислали список покупок. Отмечайте купленное касанием ✓')),
        );
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _store.removeListener(_onStoreChanged);
    super.dispose();
  }

  ShopList? get _list => _store.byId(widget.listId);

  void _onStoreChanged() {
    final l = _list;
    if (l == null) return;
    final sig = l.items.where((i) => !i.checked).map((i) => i.key).join('|');
    if (sig == _signature) return;
    _signature = sig;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _refreshSuggestions);
  }

  Future<void> _refreshSuggestions() async {
    final l = _list;
    if (l == null || !mounted) return;
    final settings = context.read<SettingsStore>();
    if (!settings.suggestionsEnabled) {
      if (_suggestions.isNotEmpty) setState(() => _suggestions = const []);
      return;
    }
    final local = await context.read<SuggestionEngine>().local(l);
    if (!mounted) return;
    setState(() => _suggestions = local);
  }

  Future<void> _acceptSuggestion(ShopList l, Suggestion s) async {
    HapticFeedback.selectionClick();
    await _store.addItem(l, s.name, fromSuggestion: true);
  }

  void _dismissSuggestion(ShopList l, Suggestion s) {
    context.read<SuggestionEngine>().dismiss(l.id, s.name);
    _store.forgetSuggestion(l, s.name);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('«${s.name}» больше не будет предлагаться')));
    setState(() => _suggestions = _suggestions.where((x) => x != s).toList());
  }

  /// «Определённый этап»: перед походом в магазин ассистент один раз предлагает проверить список.
  Future<void> _enterShopMode(ShopList l) async {
    final settings = context.read<SettingsStore>();
    if (!_preShopShown && settings.suggestionsEnabled && _suggestions.isNotEmpty) {
      _preShopShown = true;
      final picked = await showModalBottomSheet<List<Suggestion>>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (_) => PreShopCheckSheet(suggestions: _suggestions.take(8).toList()),
      );
      if (!mounted) return;
      for (final s in picked ?? const <Suggestion>[]) {
        await _store.addItem(l, s.name, fromSuggestion: true);
      }
    }
    if (mounted) setState(() => _shopMode = true);
  }

  Future<void> _toggleInShop(ShopList l, ListItem item) async {
    HapticFeedback.lightImpact();
    final wasDone = l.isDone;
    await _store.toggle(l, item);
    if (!wasDone && l.isDone && mounted) await _onAllBought(l);
  }

  Future<void> _onAllBought(ShopList l) async {
    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.celebration_outlined, size: 40),
        title: const Text('Всё куплено!'),
        content: const Text('Отличная работа. Что сделать со списком?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, 'keep'), child: const Text('Оставить')),
          TextButton(onPressed: () => Navigator.pop(ctx, 'clear'), child: const Text('Очистить')),
          FilledButton(onPressed: () => Navigator.pop(ctx, 'close'), child: const Text('Готово')),
        ],
      ),
    );
    if (!mounted) return;
    if (action == 'clear') await _store.removeChecked(l);
    if (action == 'close' && mounted) Navigator.of(context).pop();
    if (mounted) await context.read<AdsService>().maybeShowInterstitial();
  }

  Future<void> _menu(ShopList l, String action) async {
    switch (action) {
      case 'share':
        await showShareSheet(context, l);
      case 'uncheck':
        await _store.uncheckAll(l);
      case 'clear':
        await _store.removeChecked(l);
      case 'edit':
        await showEditListSheet(context, l);
      case 'dup':
        final copy = await _store.duplicate(l);
        if (mounted) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => ListScreen(listId: copy.id)));
        }
    }
  }

  Future<void> _editItem(ShopList l, ListItem item) async {
    final name = TextEditingController(text: item.name);
    final qty = TextEditingController(text: item.quantity);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Позиция'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: name,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Название'),
          ),
          const SizedBox(height: 12),
          TextField(controller: qty, decoration: const InputDecoration(labelText: 'Количество', hintText: 'например, 2 кг')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Сохранить')),
        ],
      ),
    );
    if (ok == true && name.text.trim().isNotEmpty) {
      await _store.updateItem(l, item, name: name.text, quantity: qty.text);
    }
  }

  void _delete(ShopList l, ListItem item) {
    _store.removeItem(l, item);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('«${item.name}» удалено'),
        action: SnackBarAction(label: 'Вернуть', onPressed: () => _store.restoreItem(l, item)),
      ));
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ListsStore>();
    final premium = context.watch<Premium>();
    final l = _list;
    if (l == null) return const Scaffold(body: Center(child: Text('Список удалён')));
    final t = Theme.of(context);
    final c = l.category;

    return PopScope(
      canPop: !_shopMode,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _shopMode) setState(() => _shopMode = false);
      },
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          title: Row(children: [
            Icon(c.icon, color: c.tint(context)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(
                  _shopMode ? 'В магазине · ${l.checkedCount} из ${l.total}' : '${l.total} поз.',
                  style: t.textTheme.bodySmall,
                ),
              ]),
            ),
          ]),
          bottom: _shopMode
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(4),
                  child: LinearProgressIndicator(value: l.progress, color: c.tint(context), minHeight: 4),
                )
              : null,
          actions: [
            if (!_shopMode && l.items.isNotEmpty)
              IconButton(
                tooltip: 'Отправить список',
                icon: const Icon(Icons.share_outlined),
                onPressed: () => showShareSheet(context, l),
              ),
            if (_shopMode)
              IconButton(
                tooltip: 'Изменить список',
                onPressed: () => setState(() => _shopMode = false),
                icon: const Icon(Icons.edit_outlined),
              ),
            PopupMenuButton<String>(
              onSelected: (a) => _menu(l, a),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'share', child: ListTile(leading: Icon(Icons.share_outlined), title: Text('Отправить список'))),
                PopupMenuItem(value: 'uncheck', child: ListTile(leading: Icon(Icons.restart_alt), title: Text('Снять все галочки'))),
                PopupMenuItem(value: 'clear', child: ListTile(leading: Icon(Icons.playlist_remove), title: Text('Удалить купленное'))),
                PopupMenuItem(value: 'dup', child: ListTile(leading: Icon(Icons.copy_outlined), title: Text('Повторить список'))),
                PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.tune), title: Text('Название и магазин'))),
              ],
            ),
          ],
        ),
        body: _shopMode ? _ShopModeBody(list: l, onToggle: (i) => _toggleInShop(l, i)) : _editBody(l),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: !_shopMode && l.items.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: WideButton(
                  icon: Icons.shopping_cart_checkout,
                  label: 'В магазин',
                  onPressed: () => _enterShopMode(l),
                ),
              )
            : null,
        // В режиме магазина рекламы нет — ничего не должно мешать сверяться со списком.
        bottomNavigationBar: _shopMode ? null : AdBanner(premium: premium),
      ),
    );
  }

  Widget _editBody(ShopList l) {
    final settings = context.watch<SettingsStore>();
    final showAssistant = settings.suggestionsEnabled && !_assistantHidden && _suggestions.isNotEmpty;
    return Column(children: [
      AddBar(list: l),
      AnimatedSize(
        duration: const Duration(milliseconds: 250),
        child: showAssistant
            ? SuggestionStrip(
                suggestions: _suggestions,
                onAccept: (s) => _acceptSuggestion(l, s),
                onDismiss: (s) => _dismissSuggestion(l, s),
                onHide: () => setState(() => _assistantHidden = true),
              )
            : const SizedBox(width: double.infinity),
      ),
      Expanded(
        child: l.items.isEmpty
            ? const _EmptyList()
            : ReorderableListView.builder(
                padding: const EdgeInsets.only(bottom: 96),
                itemCount: l.items.length,
                onReorderItem: (a, b) => _store.reorder(l, a, b),
                itemBuilder: (_, i) {
                  final item = l.items[i];
                  return Dismissible(
                    key: ValueKey(item.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 24),
                      color: Theme.of(context).colorScheme.errorContainer,
                      child: const Icon(Icons.delete_outline),
                    ),
                    onDismissed: (_) => _delete(l, item),
                    child: _ItemTile(
                      item: item,
                      onToggle: () => _store.toggle(l, item),
                      onTap: () => _editItem(l, item),
                    ),
                  );
                },
              ),
      ),
    ]);
  }
}

class _EmptyList extends StatelessWidget {
  const _EmptyList();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'Добавьте товары: напишите через запятую,\nнажмите на частые товары выше\nили продиктуйте 🎤',
          textAlign: TextAlign.center,
          style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({required this.item, required this.onToggle, required this.onTap});
  final ListItem item;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final done = item.checked;
    return ListTile(
      onTap: onTap,
      leading: Checkbox(value: done, onChanged: (_) => onToggle()),
      title: Text(
        item.name,
        style: TextStyle(
          decoration: done ? TextDecoration.lineThrough : null,
          color: done ? t.colorScheme.onSurfaceVariant : null,
        ),
      ),
      subtitle: item.quantity.isEmpty ? null : Text(item.quantity),
      trailing: item.fromSuggestion
          ? Tooltip(message: 'Добавлено по подсказке', child: Icon(Icons.auto_awesome, size: 16, color: t.colorScheme.primary))
          : null,
    );
  }
}

/// Режим «в магазине»: крупные строки, группировка по отделам, купленное уходит вниз.
class _ShopModeBody extends StatelessWidget {
  const _ShopModeBody({required this.list, required this.onToggle});
  final ShopList list;
  final void Function(ListItem) onToggle;

  @override
  Widget build(BuildContext context) {
    final catalog = context.read<Catalog>();
    final t = Theme.of(context);
    final cc = catalog.of(list.category);
    final order = cc.sectionOrder;
    final todo = list.items.where((i) => !i.checked).toList();
    final done = list.items.where((i) => i.checked).toList();

    final groups = <String, List<ListItem>>{};
    for (final i in todo) {
      final s = catalog.sectionFor(list.category, i.name) ?? 'Прочее';
      groups.putIfAbsent(s, () => []).add(i);
    }
    final sections = groups.keys.toList()
      ..sort((a, b) {
        int idx(String s) => s == 'Прочее' ? 999 : (!order.contains(s) ? 998 : order.indexOf(s));
        return idx(a).compareTo(idx(b));
      });

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        if (todo.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(children: [
              Icon(Icons.check_circle_outline, size: 64, color: t.colorScheme.primary),
              const SizedBox(height: 8),
              Text('Всё в корзине!', style: t.textTheme.titleLarge),
            ]),
          ),
        for (final s in sections) ...[
          if (sections.length > 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Text(s.toUpperCase(),
                  style: t.textTheme.labelMedium?.copyWith(color: t.colorScheme.primary, letterSpacing: 1)),
            ),
          for (final i in groups[s]!) _ShopTile(item: i, onTap: () => onToggle(i)),
        ],
        if (done.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 4),
            child: Text('В КОРЗИНЕ · ${done.length}',
                style: t.textTheme.labelMedium?.copyWith(color: t.colorScheme.onSurfaceVariant, letterSpacing: 1)),
          ),
          for (final i in done) _ShopTile(item: i, onTap: () => onToggle(i)),
        ],
      ],
    );
  }
}

class _ShopTile extends StatelessWidget {
  const _ShopTile({required this.item, required this.onTap});
  final ListItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final done = item.checked;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? t.colorScheme.primary : Colors.transparent,
              border: Border.all(color: done ? t.colorScheme.primary : t.colorScheme.outline, width: 2),
            ),
            child: done ? Icon(Icons.check, size: 20, color: t.colorScheme.onPrimary) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              item.name,
              style: t.textTheme.titleMedium?.copyWith(
                fontSize: 19,
                decoration: done ? TextDecoration.lineThrough : null,
                color: done ? t.colorScheme.onSurfaceVariant : null,
              ),
            ),
          ),
          if (item.quantity.isNotEmpty)
            Text(item.quantity, style: t.textTheme.titleSmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
        ]),
      ),
    );
  }
}

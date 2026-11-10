import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/shop_list.dart';
import '../../state/lists_store.dart';

/// «Отправить список»: готовые фразы + ссылка, по которой у получателя
/// сразу откроется приложение с этим списком.
Future<void> showShareSheet(BuildContext context, ShopList list) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _ShareSheet(list: list),
  );
}

const _presets = [
  'Дорогой, по дороге домой заскочи в магазин и купи, пожалуйста, всё по этому списку ❤️',
  'Купи, пожалуйста, по списку 🙏',
  'Список покупок на сегодня 🛒',
  '',
];

class _ShareSheet extends StatefulWidget {
  const _ShareSheet({required this.list});
  final ShopList list;

  @override
  State<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<_ShareSheet> {
  late final TextEditingController _msg = TextEditingController(text: _presets.first);
  bool _withText = true;
  bool _busy = false;

  @override
  void dispose() {
    _msg.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _busy = true);
    final link = await context.read<ListsStore>().shareLink(widget.list);
    final l = widget.list;
    final todo = l.items.where((i) => !i.checked).toList();
    final b = StringBuffer();
    if (_msg.text.trim().isNotEmpty) b.writeln('${_msg.text.trim()}\n');
    b.writeln('🛒 «${l.name}» — ${todo.length} поз. Открыть список:');
    b.writeln(link);
    if (_withText && todo.isNotEmpty) {
      b.writeln();
      for (final i in todo) {
        b.writeln('• ${i.displayText}');
      }
    }
    await SharePlus.instance.share(ShareParams(text: b.toString().trimRight(), subject: l.name));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 16),
      child: SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Отправить список', style: t.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Получатель нажмёт на ссылку — и сразу увидит список в приложении. '
            'Если приложения нет, список откроется в браузере.',
            style: t.textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final p in _presets)
              ChoiceChip(
                label: Text(p.isEmpty ? 'Без сообщения' : (p.length > 28 ? '${p.substring(0, 28)}…' : p)),
                selected: _msg.text == p,
                onSelected: (_) => setState(() => _msg.text = p),
              ),
          ]),
          const SizedBox(height: 12),
          TextField(
            controller: _msg,
            minLines: 2,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Ваше сообщение',
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Добавить список текстом'),
            subtitle: const Text('Чтобы товары были видны прямо в чате'),
            value: _withText,
            onChanged: (v) => setState(() => _withText = v),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              onPressed: _busy ? null : _send,
              icon: const Icon(Icons.send),
              label: const Text('Отправить в Telegram, WhatsApp…'),
            ),
          ),
        ]),
      ),
    );
  }
}

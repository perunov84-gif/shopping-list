import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/shop_list.dart';
import '../../state/lists_store.dart';

/// «Отправить список»: сообщение получателю + ссылка, по которой у него
/// сразу откроется приложение с этим списком.
Future<void> showShareSheet(BuildContext context, ShopList list) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _ShareSheet(list: list),
  );
}

/// Сообщение по умолчанию: подсказка в поле ввода и текст, если поле оставили пустым.
const defaultShareMessage = 'Посмотри, вот что нужно купить:';

enum _Target { telegram, whatsapp, other }

class _ShareSheet extends StatefulWidget {
  const _ShareSheet({required this.list});
  final ShopList list;

  @override
  State<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<_ShareSheet> {
  final _msg = TextEditingController();
  bool _withText = true;
  bool _busy = false;

  @override
  void dispose() {
    _msg.dispose();
    super.dispose();
  }

  Future<(String text, String link)> _compose() async {
    final link = await context.read<ListsStore>().shareLink(widget.list);
    final l = widget.list;
    final todo = l.items.where((i) => !i.checked).toList();
    final message = _msg.text.trim().isEmpty ? defaultShareMessage : _msg.text.trim();
    final b = StringBuffer()
      ..writeln(message)
      ..writeln()
      ..writeln('🛒 «${l.name}» — ${todo.length} поз. Открыть список:')
      ..writeln(link);
    if (_withText && todo.isNotEmpty) {
      b.writeln();
      for (final i in todo) {
        b.writeln('• ${i.displayText}');
      }
    }
    return (b.toString().trimRight(), link);
  }

  Future<void> _send(_Target target) async {
    setState(() => _busy = true);
    final (text, link) = await _compose();
    var ok = false;
    switch (target) {
      case _Target.telegram:
        // Telegram сам покажет выбор чата. Текст без ссылки — ссылку он подставит отдельно.
        final withoutLink = text.replaceFirst('$link\n', '').replaceFirst(link, '');
        ok = await _open(Uri.parse(
                'tg://msg_url?url=${Uri.encodeComponent(link)}&text=${Uri.encodeComponent(withoutLink)}')) ||
            await _open(Uri.parse(
                'https://t.me/share/url?url=${Uri.encodeComponent(link)}&text=${Uri.encodeComponent(withoutLink)}'));
      case _Target.whatsapp:
        ok = await _open(Uri.parse('whatsapp://send?text=${Uri.encodeComponent(text)}')) ||
            await _open(Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}'));
      case _Target.other:
        break;
    }
    if (!ok) {
      // Мессенджер не установлен (или «Другое») — системное меню «Поделиться».
      await SharePlus.instance.share(ShareParams(text: text, subject: widget.list.name));
    }
    if (mounted) Navigator.pop(context);
  }

  Future<bool> _open(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final mq = MediaQuery.of(context);
    return Padding(
      // клавиатура + системная панель навигации снизу
      padding: EdgeInsets.fromLTRB(20, 0, 20, mq.viewInsets.bottom + mq.viewPadding.bottom + 16),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Отправить список', textAlign: TextAlign.center, style: t.textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            'Получатель нажмёт на ссылку — и сразу увидит список в приложении. '
            'Если приложения нет, список откроется в браузере.',
            textAlign: TextAlign.center,
            style: t.textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          Text('Добавить сообщение получателю', textAlign: TextAlign.center, style: t.textTheme.titleSmall),
          const SizedBox(height: 8),
          TextField(
            controller: _msg,
            minLines: 2,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: defaultShareMessage,
              hintStyle: TextStyle(color: t.colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
              border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
            ),
          ),
          const SizedBox(height: 16),
          Text('Добавить список текстом', textAlign: TextAlign.center, style: t.textTheme.titleSmall),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Flexible(
              child: Text('Чтобы товары были видны прямо в чате',
                  textAlign: TextAlign.center, style: t.textTheme.bodySmall),
            ),
            const SizedBox(width: 12),
            Switch(value: _withText, onChanged: (v) => setState(() => _withText = v)),
          ]),
          const SizedBox(height: 16),
          Text('Отправить', textAlign: TextAlign.center, style: t.textTheme.titleMedium),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _TargetButton(
              label: 'Telegram',
              color: const Color(0xFF229ED9),
              icon: Icons.telegram,
              onTap: _busy ? null : () => _send(_Target.telegram),
            ),
            _TargetButton(
              label: 'WhatsApp',
              color: const Color(0xFF25D366),
              icon: Icons.whatsapp,
              onTap: _busy ? null : () => _send(_Target.whatsapp),
            ),
            _TargetButton(
              label: 'Другое',
              color: t.colorScheme.primary,
              icon: Icons.share,
              onTap: _busy ? null : () => _send(_Target.other),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _TargetButton extends StatelessWidget {
  const _TargetButton({required this.label, required this.color, required this.icon, required this.onTap});
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Material(
        color: color,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(width: 64, height: 64, child: Icon(icon, color: Colors.white, size: 32)),
        ),
      ),
      const SizedBox(height: 6),
      Text(label, style: Theme.of(context).textTheme.labelMedium),
    ]);
  }
}

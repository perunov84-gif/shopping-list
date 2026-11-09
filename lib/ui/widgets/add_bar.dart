import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/shop_list.dart';
import '../../state/lists_store.dart';
import 'voice_sheet.dart';

/// Строка быстрого ввода: текст (можно сразу несколько через запятую), автодополнение,
/// «частые» товары одним касанием и диктовка.
class AddBar extends StatefulWidget {
  const AddBar({super.key, required this.list});
  final ShopList list;

  @override
  State<AddBar> createState() => _AddBarState();
}

class _AddBarState extends State<AddBar> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  List<String> _chips = const [];
  bool _typing = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
    _loadFrequent();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  ListsStore get _store => context.read<ListsStore>();

  Future<void> _loadFrequent() async {
    final f = await _store.frequent(widget.list);
    if (mounted && !_typing) setState(() => _chips = f);
  }

  void _onChanged() {
    final text = _controller.text;
    // автодополнение — по последнему фрагменту после запятой
    final last = text.split(',').last.trim();
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 120), () async {
      if (last.isEmpty) {
        _typing = false;
        await _loadFrequent();
        return;
      }
      _typing = true;
      final s = await _store.autocomplete(widget.list, last);
      if (mounted) setState(() => _chips = s);
    });
    setState(() {});
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    await _store.addFromText(widget.list, text);
    _controller.clear();
    _focus.requestFocus(); // остаёмся в поле — можно вводить дальше
  }

  Future<void> _pickChip(String name) async {
    HapticFeedback.selectionClick();
    final text = _controller.text;
    if (_typing && text.contains(',')) {
      // заменяем недописанный фрагмент и добавляем всё сразу
      final parts = text.split(',')..removeLast();
      await _store.addFromText(widget.list, [...parts, name].join(','));
    } else {
      await _store.addItem(widget.list, name);
    }
    _controller.clear();
    await _loadFrequent();
  }

  Future<void> _voice() async {
    final text = await showVoiceSheet(context, hint: 'Например: «два литра молока, хлеб и десяток яиц»');
    if (text == null || text.trim().isEmpty || !mounted) return;
    final added = await _store.addFromText(widget.list, text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(added.isEmpty ? 'Уже в списке' : 'Добавлено: ${added.map((e) => e.name).join(', ')}')),
    );
    await _loadFrequent();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final hasText = _controller.text.trim().isNotEmpty;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        child: TextField(
          controller: _controller,
          focusNode: _focus,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            hintText: 'Что купить? Можно через запятую',
            prefixIcon: const Icon(Icons.add),
            suffixIcon: hasText
                ? IconButton(icon: const Icon(Icons.send), tooltip: 'Добавить', onPressed: _submit)
                : IconButton(icon: const Icon(Icons.mic_none), tooltip: 'Надиктовать', onPressed: _voice),
          ),
        ),
      ),
      if (_chips.isNotEmpty)
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            itemCount: _chips.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (_, i) => ActionChip(
              label: Text(_chips[i]),
              avatar: Icon(_typing ? Icons.search : Icons.history, size: 16, color: t.colorScheme.primary),
              onPressed: () => _pickChip(_chips[i]),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ),
    ]);
  }
}

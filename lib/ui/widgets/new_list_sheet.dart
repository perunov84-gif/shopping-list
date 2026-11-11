import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/shop_list.dart';
import '../../models/store_category.dart';
import '../../state/lists_store.dart';
import '../theme.dart';

/// Создание списка в два касания: выбрать тип магазина — список сразу открыт.
Future<ShopList?> showNewListSheet(BuildContext context) {
  return showModalBottomSheet<ShopList>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _ListSheet(),
  );
}

Future<void> showEditListSheet(BuildContext context, ShopList list) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _ListSheet(editing: list),
  );
}

class _ListSheet extends StatefulWidget {
  const _ListSheet({this.editing});
  final ShopList? editing;

  @override
  State<_ListSheet> createState() => _ListSheetState();
}

class _ListSheetState extends State<_ListSheet> {
  late final TextEditingController _name = TextEditingController(text: widget.editing?.name ?? '');
  late StoreCategory _category = widget.editing?.category ?? StoreCategory.grocery;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit(StoreCategory c) async {
    final store = context.read<ListsStore>();
    final editing = widget.editing;
    if (editing != null) {
      await store.renameList(editing, _name.text, c);
      if (mounted) Navigator.pop(context);
    } else {
      final list = await store.createList(c, name: _name.text);
      if (mounted) Navigator.pop(context, list);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final isEdit = widget.editing != null;
    return Padding(
      // клавиатура + системная панель навигации (Android 15 рисует приложение под ней)
      padding: EdgeInsets.fromLTRB(
          16, 0, 16, MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).viewPadding.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isEdit ? 'Изменить список' : 'Куда идём за покупками?', style: t.textTheme.titleLarge),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'Название (необязательно)', prefixIcon: Icon(Icons.edit_note)),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.05,
            children: [
              for (final c in StoreCategory.values)
                _CategoryTile(
                  category: c,
                  selected: isEdit && c == _category,
                  onTap: () {
                    setState(() => _category = c);
                    if (!isEdit) _submit(c);
                  },
                ),
            ],
          ),
          if (isEdit) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: () => _submit(_category), child: const Text('Сохранить')),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.onTap, this.selected = false});
  final StoreCategory category;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = category.tint(context);
    return Material(
      color: c.withValues(alpha: selected ? 0.28 : 0.12),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(category.icon, color: c, size: 30),
            const SizedBox(height: 6),
            Text(category.title, textAlign: TextAlign.center, maxLines: 2, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ]),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// Единая большая кнопка приложения («Новый список», «В магазин», «Надиктовать», «Купить VIP»):
/// во всю ширину, высота 56, скругление 16, основной цвет темы.
class WideButton extends StatelessWidget {
  const WideButton({super.key, required this.icon, required this.label, required this.onPressed, this.busy = false});

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton.icon(
        onPressed: busy ? null : onPressed,
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 3,
          shadowColor: t.colorScheme.primary.withValues(alpha: 0.4),
          textStyle: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        icon: busy
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(icon, size: 24),
        label: Text(label),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/voice_service.dart';

/// Показывает окно диктовки и возвращает распознанную фразу (или null).
Future<String?> showVoiceSheet(BuildContext context, {String? hint}) {
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (_) => _VoiceSheet(hint: hint),
  );
}

class _VoiceSheet extends StatefulWidget {
  const _VoiceSheet({this.hint});
  final String? hint;

  @override
  State<_VoiceSheet> createState() => _VoiceSheetState();
}

class _VoiceSheetState extends State<_VoiceSheet> {
  late final VoiceService _voice = context.read<VoiceService>();
  bool _closed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    final ready = await _voice.ensureReady();
    if (!ready) {
      if (mounted) setState(() {});
      return;
    }
    await _voice.listen(onFinal: _finish);
  }

  void _finish(String text) {
    if (_closed || !mounted) return;
    _closed = true;
    Navigator.pop(context, text);
  }

  @override
  void dispose() {
    if (_voice.isListening) _voice.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final v = context.watch<VoiceService>();
    final unavailable = !v.isAvailable && v.error != null;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: EdgeInsets.all(v.isListening ? 22 : 16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: v.isListening ? t.colorScheme.primaryContainer : t.colorScheme.surfaceContainerHighest,
            ),
            child: Icon(v.isListening ? Icons.mic : Icons.mic_none, size: 40, color: t.colorScheme.primary),
          ),
          const SizedBox(height: 16),
          Text(
            unavailable
                ? 'Голосовой ввод недоступен. Проверьте разрешение на микрофон.'
                : v.partial.isNotEmpty
                    ? v.partial
                    : (v.isListening ? 'Говорите…' : 'Подготовка микрофона…'),
            textAlign: TextAlign.center,
            style: t.textTheme.titleMedium,
          ),
          if (widget.hint != null && v.partial.isEmpty) ...[
            const SizedBox(height: 8),
            Text(widget.hint!, textAlign: TextAlign.center, style: t.textTheme.bodySmall),
          ],
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: v.partial.trim().isEmpty
                  ? (unavailable ? null : () => _start())
                  : () async {
                      final text = v.partial;
                      await _voice.stop();
                      _finish(text);
                    },
              child: Text(v.partial.trim().isEmpty ? 'Ещё раз' : 'Готово'),
            ),
          ]),
        ]),
      ),
    );
  }
}

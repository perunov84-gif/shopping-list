import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Голосовой ввод через системное распознавание речи (Google на Android, Siri на iOS).
/// Бесплатно, без собственного сервера.
class VoiceService extends ChangeNotifier {
  final SpeechToText _stt = SpeechToText();
  bool _ready = false;
  bool _initTried = false;
  String? _localeId;

  String partial = '';
  String? error;

  bool get isListening => _stt.isListening;
  bool get isAvailable => _ready;

  Future<bool> ensureReady() async {
    if (_ready) return true;
    if (_initTried && !_ready) {
      // повторная попытка (например, пользователь выдал разрешение)
    }
    _initTried = true;
    try {
      _ready = await _stt.initialize(
        onError: (e) {
          error = e.errorMsg;
          notifyListeners();
        },
        onStatus: (_) => notifyListeners(),
      );
      if (_ready) {
        final locales = await _stt.locales();
        final ru = locales.where((l) => l.localeId.toLowerCase().startsWith('ru'));
        _localeId = ru.isNotEmpty ? ru.first.localeId : null;
      }
    } catch (e) {
      error = '$e';
      _ready = false;
    }
    notifyListeners();
    return _ready;
  }

  /// Начинает слушать. [onFinal] вызывается один раз с итоговой фразой.
  Future<void> listen({required void Function(String text) onFinal}) async {
    if (!await ensureReady()) return;
    partial = '';
    error = null;
    var delivered = false;
    await _stt.listen(
      onResult: (SpeechRecognitionResult r) {
        partial = r.recognizedWords;
        notifyListeners();
        if (r.finalResult && !delivered) {
          delivered = true;
          if (partial.trim().isNotEmpty) onFinal(partial);
        }
      },
      listenOptions: SpeechListenOptions(
        localeId: _localeId,
        listenMode: ListenMode.dictation,
        partialResults: true,
        cancelOnError: true,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 4),
      ),
    );
    notifyListeners();
  }

  Future<void> stop() async {
    await _stt.stop();
    notifyListeners();
  }

  Future<void> cancel() async {
    await _stt.cancel();
    partial = '';
    notifyListeners();
  }
}

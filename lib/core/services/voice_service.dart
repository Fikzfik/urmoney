import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VoiceService {
  final SpeechToText _speech = SpeechToText();
  bool _isAvailable = false;

  Future<bool> init() async {
    if (_isAvailable) return true;
    _isAvailable = await _speech.initialize(
      onError: (val) => debugPrint('STT Error: $val'),
      onStatus: (val) => debugPrint('STT Status: $val'),
    );
    return _isAvailable;
  }

  Future<void> listen({
    required Function(String) onResult,
    required VoidCallback onDone,
  }) async {
    if (!_isAvailable) {
      final ok = await init();
      if (!ok) return;
    }

    await _speech.listen(
      onResult: (val) {
        if (val.finalResult) {
          onResult(val.recognizedWords);
          onDone();
        }
      },
      localeId: 'id_ID', // Force Indonesian
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 5),
    );
  }

  Future<void> stop() async {
    await _speech.stop();
  }

  bool get isListening => _speech.isListening;
}

final voiceServiceProvider = Provider((ref) => VoiceService());

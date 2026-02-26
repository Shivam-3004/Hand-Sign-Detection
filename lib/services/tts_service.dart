import 'package:flutter_tts/flutter_tts.dart';

/// Wrapper around [FlutterTts] with sane defaults for our application.
class TtsService {
  final FlutterTts _tts = FlutterTts();

  TtsService() {
    _tts.setLanguage('en-US');
    _tts.setPitch(1.0);
  }

  Future<void> speak(String text) async {
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
  }
}

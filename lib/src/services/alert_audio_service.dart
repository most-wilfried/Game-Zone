import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

class AlertAudioService {
  AlertAudioService._internal() {
    _configure();
  }

  static final AlertAudioService instance = AlertAudioService._internal();

  final FlutterTts _tts = FlutterTts();
  bool _configured = false;

  Future<void> _configure() async {
    if (_configured) return;
    _configured = true;
    await _tts.setLanguage('fr-FR');
    await _tts.setSpeechRate(0.46);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    await _tts.awaitSpeakCompletion(true);
  }

  Future<void> playBell() async {
    try {
      await SystemSound.play(SystemSoundType.alert);
      await Future<void>.delayed(const Duration(milliseconds: 180));
      await SystemSound.play(SystemSoundType.alert);
    } catch (_) {
      // Ignore on platforms without system alert support.
    }
  }

  Future<void> speak({
    required String text,
    required String voiceGender,
  }) async {
    await _configure();
    await _tts.stop();
    await _tts.setPitch(voiceGender == 'female' ? 1.08 : 0.92);
    await _tts.speak(text);
  }

  Future<void> announceRemainingTime({
    required String stationName,
    required int minutesLeft,
    required String voiceGender,
  }) async {
    await speak(
      text:
          '$stationName, il vous reste $minutesLeft minute${minutesLeft > 1 ? 's' : ''}.',
      voiceGender: voiceGender,
    );
  }

  Future<void> announceSessionFinished({
    required String stationName,
    required String voiceGender,
  }) async {
    await speak(
      text: '$stationName, la session est terminée.',
      voiceGender: voiceGender,
    );
  }
}

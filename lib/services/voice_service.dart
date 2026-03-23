import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class VoiceService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;

  VoiceService() {
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.5); // normal speed
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0); // normal pitch

      // Web/Chrome loaded voices are asynchronous. We must wait briefly.
      if (kIsWeb) {
        await Future.delayed(const Duration(milliseconds: 500));
      }

      final voices = await _flutterTts.getVoices;
      bool femaleVoiceSet = false;

      debugPrint("--- Available TTS Voices ---");
      if (voices != null) {
        for (var voice in voices) {
          if (voice is Map) {
            final name = (voice["name"] as String).toLowerCase();
            final locale = (voice["locale"] as String).toLowerCase();
            
            // Temporary debug logging of all english voices
            if (locale.contains("en")) {
               debugPrint("Voice: $name | Locale: $locale");
            }

            if (locale.contains("en") && !femaleVoiceSet) {
              if (name.contains("network female") || 
                  name.contains("en-female") || 
                  name.contains("female") || 
                  name.contains("zira") || 
                  name.contains("samantha") || 
                  name.contains("victoria") ||
                  name.contains("google uk english female") ||
                  name.contains("karen")) {
                
                await _flutterTts.setVoice({"name": voice["name"], "locale": voice["locale"]});
                femaleVoiceSet = true;
                debugPrint(">>> Selected Female Voice: $name <<<");
              }
            }
          }
        }
      } else {
         debugPrint("TTS getVoices returned null.");
      }

      // Fallback if specific female keyword is not found
      if (!femaleVoiceSet) {
         debugPrint(">>> Female voice not explicitly found, falling back to default English en-US <<<");
         await _flutterTts.setLanguage("en-US"); // Usually defaults to a female voice on mobile
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint("Error initializing VoiceService: $e");
    }
  }

  // Helper for natural voice rhythm
  String _prepareForTts(String text) {
    // Systems handle . naturally; adding too many dots makes it too slow.
    // Just ensuring clean spacing.
    return text.trim();
  }

  Future<void> speak(String text) async {
    if (!_isInitialized) {
      debugPrint("VoiceService not fully initialized yet, waiting...");
      // Await briefly in case the async init is just finishing up
      await Future.delayed(const Duration(milliseconds: 500)); 
    }
    
    await stop(); // Stop any currently playing audio
    
    // Smart Speech Timing (Feels Premium)
    await Future.delayed(const Duration(milliseconds: 300)); // Precise 300ms delay before speaking
    
    final preparedText = _prepareForTts(text);
    await _flutterTts.speak(preparedText);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }
}

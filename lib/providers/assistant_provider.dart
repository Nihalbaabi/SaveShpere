import 'package:flutter/material.dart' hide Intent;
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/energy_models.dart';
import '../models/water_models.dart';
import '../models/assistant.dart';
import '../services/ai/time_parser.dart';
import '../services/ai/intent_detector.dart';
import '../services/ai/anomaly_engine.dart';
import '../services/ai/suggestion_engine.dart';
import '../services/ai/response_builder.dart';
import '../services/ai/context_manager.dart';
import '../services/voice_service.dart';
import 'theme_provider.dart';
import 'energy_provider.dart';
import 'water_provider.dart';

class ChatMessage {
  final String id;
  final String sender; // 'user' | 'ai'
  final String text;
  final AssistantResponse? responseMeta;

  ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    this.responseMeta,
  });
}

class AssistantProvider extends ChangeNotifier {
  final SpeechToText _speechToText = SpeechToText();
  final VoiceService _voiceService = VoiceService();
  
  bool _isSpeechSupported = false;
  bool get isSpeechSupported => _isSpeechSupported;

  String _state = 'idle'; // idle, listening, processing
  String get state => _state;

  List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => _messages;

  String _lastTranscript = "";
  String get lastTranscript => _lastTranscript;

  ConversationContext _context = createInitialContext();

  // History for suggestion rotation
  final List<String> _recentSuggestions = [];

  AssistantProvider() {
    _initSpeech();
  }

  AssistantMode _currentMode = AssistantMode.balanced;
  AssistantMode get currentMode => _currentMode;

  void setMode(AssistantMode mode) {
    _currentMode = mode;
    notifyListeners();
  }

  void _initSpeech() async {
    // Request microphone permission first
    PermissionStatus status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      debugPrint("Microphone permission denied");
      _isSpeechSupported = false;
      notifyListeners();
      return;
    }

    _isSpeechSupported = await _speechToText.initialize(
      onStatus: (status) {
        debugPrint("Speech status: $status");
        if (status == "done" || status == "notListening") {
            _state = 'idle';
            notifyListeners();
        }
      },
      onError: (error) {
        debugPrint("Speech error: $error");
        _state = 'idle';
        notifyListeners();
      },
    );
    
    if (!_isSpeechSupported) {
        debugPrint("Speech recognition not available on this device.");
    }

    if (!_isSpeechSupported) {
        debugPrint("Speech recognition not available on this device.");
    }

    notifyListeners();
  }

  void startListening(EnergyDataProvider energyProvider, WaterDataProvider waterProvider, ThemeProvider themeProvider) async {
    final data = energyProvider.energyMetrics;
    if (data == null) return;
    
    if (!_isSpeechSupported) {
        debugPrint("Microphone not supported or permission denied.");
        return;
    }

    // Stop TTS if speaking
    await _voiceService.stop();

    _state = 'listening';
    _lastTranscript = "";
    notifyListeners();
    
    await _speechToText.listen(
      onResult: (result) async {
        _lastTranscript = result.recognizedWords;
        notifyListeners();

        if (result.finalResult && _lastTranscript.isNotEmpty) {
          _state = 'processing';
          notifyListeners();
          
          await _speechToText.stop();
          // Process the recognized query
          await processQuery(_lastTranscript, energyProvider, waterProvider, themeProvider);
        }
      },
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      cancelOnError: true,
      listenMode: ListenMode.confirmation,
    );
  }

  void stopListening(EnergyDataProvider energyProvider, WaterDataProvider waterProvider, ThemeProvider themeProvider) async {
    await _speechToText.stop();
    
    // If we have words, trigger processing manually if the onResult didn't already
    if (_lastTranscript.isNotEmpty && _state == 'listening') {
       final transcript = _lastTranscript;
       _state = 'processing';
       notifyListeners();
       await processQuery(transcript, energyProvider, waterProvider, themeProvider);
    } else {
      _state = 'idle';
      _lastTranscript = "";
      notifyListeners();
    }
  }

  Future<void> processQuery(String query, EnergyDataProvider energyProvider, WaterDataProvider waterProvider, ThemeProvider themeProvider) async {
    final energyData = energyProvider.energyMetrics;
    final waterData = waterProvider.waterMetrics;
    if (energyData == null || waterData == null) return;

    _state = 'processing';
    notifyListeners();

    final lowerMsg = query.toLowerCase();
    bool isWaterReq = lowerMsg.contains("water") || lowerMsg.contains("leak") || lowerMsg.contains("tank") || lowerMsg.contains("flow") || lowerMsg.contains("liter") || lowerMsg.contains("pump") || lowerMsg.contains("motor");

    // 1. Time Parsing
    final timeRef = parseTimeReference(query);

    // 2. Intent Detection
    final intentRes = detectIntent(query);
    final intent = intentRes.intent;
    final confidence = intentRes.confidence;

    // 3. Merging with Context (Checking Expiry FIRST)
    final isExpired = isContextExpired(_context);
    Intent activeIntent = intent;
    if (intent == Intent.unknown && _context.lastIntent != null && confidence < 0.3 && !isExpired) {
        activeIntent = _context.lastIntent!;
    }

    // 4 & 5. Data & Anomaly Engine
    final severity = isWaterReq ? detectWaterAnomaly(waterData) : detectAnomaly(energyData);

    // Topic Modifier detection (e.g. least vs most, dark vs light, daily vs monthly)
    String? topicModifier;
    if (lowerMsg.contains("least") || lowerMsg.contains("less")) {
        topicModifier = "least";
    } else if (activeIntent == Intent.comparison) {
        if (lowerMsg.contains("yesterday") || lowerMsg.contains("today") || lowerMsg.contains("daily") || lowerMsg.contains("day")) {
            topicModifier = "daily";
        } else if (lowerMsg.contains("week")) {
            topicModifier = "weekly";
        } else {
            topicModifier = "monthly";
        }
    } else if (activeIntent == Intent.themeChange) {
        if (lowerMsg.contains("dark")) topicModifier = "dark";
        else if (lowerMsg.contains("light")) topicModifier = "light";
        else topicModifier = "system";
    } else if (activeIntent == Intent.powerControl) {
        final isOff = lowerMsg.contains("off") || lowerMsg.contains("shutdown") || lowerMsg.contains("disable");
        final isOn = lowerMsg.contains("on") || lowerMsg.contains("enable");
        final state = !isOff; // Default to on if not explicitly off

        bool targetAll = lowerMsg.contains("all") || lowerMsg.contains("everything") ||
            (!lowerMsg.contains("bedroom") && !lowerMsg.contains("living") && !lowerMsg.contains("kitchen"));

        if (targetAll) {
            await energyProvider.toggleRoom('bedroom', state);
            await energyProvider.toggleRoom('livingRoom', state);
            await energyProvider.toggleRoom('kitchen', state);
            topicModifier = state ? "all_on" : "all_off";
        } else if (lowerMsg.contains("bedroom")) {
            await energyProvider.toggleRoom('bedroom', state);
            topicModifier = state ? "bedroom_on" : "bedroom_off";
        } else if (lowerMsg.contains("living")) {
            await energyProvider.toggleRoom('livingRoom', state);
            topicModifier = state ? "living_on" : "living_off";
        } else if (lowerMsg.contains("kitchen")) {
            await energyProvider.toggleRoom('kitchen', state);
            topicModifier = state ? "kitchen_on" : "kitchen_off";
        }
    }
    
    // Water Power Control
    if (isWaterReq && activeIntent == Intent.powerControl) {
        if (lowerMsg.contains("motor") || lowerMsg.contains("pump") || lowerMsg.contains("tank")) {
            await waterProvider.toggleMotor();
            final isOff = lowerMsg.contains("off") || lowerMsg.contains("shutdown") || lowerMsg.contains("stop");
            topicModifier = !isOff ? "all_on" : "all_off";
        }
    }

    // Override severity to normal globally as the user explicitly requested NO visual icons/warnings for both Energy & Water.
    final displaySeverity = Severity.normal;

    // 6. Response Construction & enforce wording limits
    String text;
    if (isWaterReq) {
      text = buildWaterResponse(
        activeIntent,
        confidence,
        displaySeverity,
        waterData,
        timeRef ?? _context.lastTimeReference,
        topicModifier,
      );
    } else {
      text = buildResponse(
        activeIntent,
        confidence,
        displaySeverity,
        energyData,
        timeRef ?? _context.lastTimeReference,
        topicModifier,
      );
    }

    // 7. Suggestions
    List<String> suggestions;
    if (isWaterReq) {
      suggestions = generateWaterSuggestions(
        intent: activeIntent,
        severity: severity,
        data: waterData,
      );
    } else {
      suggestions = generateSuggestions(
        intent: activeIntent,
        severity: severity,
        data: energyData,
      );
    }

    // 8. Update context
    _context = updateContext(_context, activeIntent, timeRef);

    String? action;
    if (activeIntent == Intent.themeChange) {
      if (topicModifier == "dark") action = "set_dark_mode";
      else if (topicModifier == "light") action = "set_light_mode";
      else action = "set_system_theme";
    }

    // 9. Structured output (and App Logic side-effects)
    final response = AssistantResponse(
      text: text,
      intent: activeIntent,
      confidence: confidence,
      severity: displaySeverity,
      suggestions: suggestions,
      action: action,
    );

    // Messages array updating
    final userMsg = ChatMessage(id: DateTime.now().millisecondsSinceEpoch.toString(), sender: 'user', text: query);
    final aiMsg = ChatMessage(id: (DateTime.now().millisecondsSinceEpoch + 1).toString(), sender: 'ai', text: text, responseMeta: response);

    _messages.add(userMsg);
    _messages.add(aiMsg);

    // Trigger App Side effects
    if (action == "set_dark_mode") themeProvider.setTheme(ThemeMode.dark);
    if (action == "set_light_mode") themeProvider.setTheme(ThemeMode.light);
    if (action == "set_system_theme") themeProvider.setTheme(ThemeMode.system);

    _state = 'idle';
    notifyListeners();

    // Use VoiceService to speak the response
    await _voiceService.speak(text);
  }
}





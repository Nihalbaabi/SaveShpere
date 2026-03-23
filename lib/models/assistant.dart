enum Intent {
  realTime,
  dailyUsage,
  weeklyUsage,
  monthlyUsage,
  billPrediction,
  currentBill,
  comparison,
  savingsTips,
  roomComparison,
  peakHour,
  themeChange,
  powerControl,
  greeting,
  thanks,
  bye,
  zoneDistribution,
  dailyReport,
  weeklyReport,
  monthlyReport,
  highestConsumption,
  averageConsumption,
  unknown
}

enum Severity { normal, warning, alert }

enum AssistantMode {
  coach,
  analytical,
  balanced
}

class AssistantResponse {
  final String text;
  final Intent intent;
  final double confidence;
  final Severity severity;
  final List<String> suggestions;
  final String? action; // set_dark_mode, set_light_mode, set_system_theme
  final Map<String, dynamic>? metadata;

  AssistantResponse({
    required this.text,
    required this.intent,
    required this.confidence,
    required this.severity,
    required this.suggestions,
    this.action,
    this.metadata,
  });
}

class ConversationContext {
  Intent? lastIntent;
  String? lastTopic;
  String? lastTimeReference;
  int lastUpdatedTimestamp;
  int messageCount;

  ConversationContext({
    this.lastIntent,
    this.lastTopic,
    this.lastTimeReference,
    required this.lastUpdatedTimestamp,
    this.messageCount = 0,
  });
}

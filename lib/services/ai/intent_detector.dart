import '../../models/energy_models.dart';
import '../../models/assistant.dart';
import '../../config/assistant_config.dart';

class IntentMatch {
  final Intent intent;
  final int matches;

  IntentMatch(this.intent, this.matches);
}

const Map<Intent, List<String>> _intentKeywords = {
  Intent.realTime: [
    "now", "current", "currently", "using", "right now", "live",
    "current power", "live power", "power usage", "real time", "real-time",
    "what is my power", "how much power"
  ],
  Intent.dailyUsage: [
    "today", "yesterday", "day", "electricity today", "power today",
    "todays power", "today's power", "usage today", "todays usage",
    "today's usage", "how much energy today", "energy today",
    "how much did i use today"
  ],
  Intent.weeklyUsage: [
    "week", "this week", "weekly", "weekly consumption",
    "show weekly", "week's usage", "this week's usage",
    "weekly energy", "show my weekly"
  ],
  Intent.monthlyUsage: [
    "month", "this month", "monthly", "units", "total units",
    "how many units", "how much", "monthly consumption",
    "show monthly", "this month's usage", "show my monthly",
    "monthly energy"
  ],
  Intent.billPrediction: [
    "expected bill", "prediction", "predict", "predict bill",
    "future bill", "how much will i pay"
  ],
  Intent.currentBill: [
    "bill as of now", "bill till now", "bill so far", "current bill",
    "bill", "cost", "pay", "money", "amount", "charge", "my bill"
  ],
  Intent.comparison: [
    "compare", "difference", "vs", "versus"
  ],
  Intent.savingsTips: [
    "save", "tip", "tips", "reduce", "lower", "efficiency"
  ],
  Intent.roomComparison: [
    "room", "bedroom", "living room", "kitchen", "where",
    "which room", "consumes", "consumes the most", "consumes the least",
    "major consumption", "highest room", "highest source"
  ],
  Intent.peakHour: [
    "peak", "time", "timing", "record", "max", "highest day",
    "which day", "day was higher", "busiest day", "peak hour",
    "peak time", "when is peak"
  ],
  Intent.zoneDistribution: [
    "zone", "zones", "distribution", "breakdown", "zone distribution",
    "room distribution", "energy mix"
  ],
  Intent.themeChange: [
    "theme", "dark mode", "light mode", "dark", "light", "display",
    "appearance", "background", "color"
  ],
  Intent.powerControl: [
    "turn on", "switch on", "enable", "shutdown", "turn off", "switch off",
    "disable", "lights", "power"
  ],
  Intent.greeting: [
    "hi", "hello", "hey", "greetings", "good morning", "good afternoon",
    "good evening"
  ],
  Intent.thanks: ["thanks", "thank you", "thnk u", "helpful", "great"],
  Intent.bye: ["bye", "goodbye", "see you", "later", "stop", "exit"],

  // New report intents
  Intent.dailyReport: [
    "daily report", "report today", "today's report", "generate daily",
    "generate report", "energy report today", "report for today"
  ],
  Intent.weeklyReport: [
    "weekly report", "report this week", "generate weekly", "weekly summary",
    "energy report week", "week summary", "report for this week"
  ],
  Intent.monthlyReport: [
    "monthly report", "report this month", "generate monthly",
    "monthly summary", "energy report month", "month summary",
    "report for this month"
  ],
  Intent.highestConsumption: [
    "highest month", "most electricity", "which month", "peak month",
    "highest consumption", "most energy", "most consumed",
    "which month consumed the most", "max month", "maximum month"
  ],
  Intent.averageConsumption: [
    "average", "avg", "average daily", "daily average", "mean usage",
    "average consumption", "what is average", "average power",
    "average energy", "per day"
  ],

  Intent.unknown: [] // fallback
};

class IntentResult {
  final Intent intent;
  final double confidence;
  
  IntentResult(this.intent, this.confidence);
}

IntentResult detectIntent(String message) {
  final cleanMessage = message.toLowerCase().replaceAll(RegExp(r'[?,.]'), '');
  final words = cleanMessage.split(RegExp(r'\s+'));

  if (words.isEmpty || cleanMessage.isEmpty) {
    return IntentResult(Intent.unknown, 0);
  }

  List<IntentMatch> scores = [];

  _intentKeywords.forEach((intentKey, keywords) {
    if (intentKey == Intent.unknown) {
      scores.add(IntentMatch(intentKey, 0));
      return;
    }

    int matches = 0;
    final fullMessageLower = message.toLowerCase();

    for (var keyword in keywords) {
      if (keyword.contains(" ")) {
        if (fullMessageLower.contains(keyword)) {
          matches += 3;
          // Boost power control actions
          if (intentKey == Intent.powerControl &&
              ["turn on", "turn off", "switch on", "switch off"].contains(keyword)) {
            matches += 5;
          }
          // Boost report intents for multi-word matches
          if ([Intent.dailyReport, Intent.weeklyReport, Intent.monthlyReport,
               Intent.highestConsumption, Intent.averageConsumption].contains(intentKey)) {
            matches += 2;
          }
        }
      } else {
        if (words.contains(keyword)) {
          matches += 1;
          if (intentKey == Intent.powerControl &&
              ["shutdown", "enable", "disable"].contains(keyword)) {
            matches += 5;
          }
        }
      }
    }

    scores.add(IntentMatch(intentKey, matches));
  });

  scores.sort((a, b) => b.matches.compareTo(a.matches));
  final bestMatch = scores.first;

  double confidence = 0;
  if (bestMatch.matches == 1) confidence = 0.5;
  if (bestMatch.matches >= 2) confidence = 0.8;
  if (bestMatch.matches > 3) confidence = 0.95;

  if (confidence < AssistantConfig.confidenceThreshold) {
    return IntentResult(Intent.unknown, confidence);
  }

  return IntentResult(bestMatch.intent, confidence);
}

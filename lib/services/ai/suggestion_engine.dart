import 'dart:math';
import '../../models/energy_models.dart';
import '../../models/assistant.dart';

const List<String> _generalTips = [
  "Replace old bulbs with LED alternatives.",
  "Limit the usage of high-power appliances during peak evening hours.",
  "Keep your AC temperature at 24°C for optimal energy savings.",
  "Unplug devices that are not in use to avoid phantom energy drain.",
  "Use natural light during the day instead of artificial lighting.",
  "Regularly clean your AC filters to maintain efficiency.",
  "Use energy-efficient 5-star rated appliances for long-term savings.",
  "Close curtains during hot afternoons to keep rooms cooler without AC.",
  "Use microwave ovens instead of conventional ovens when possible.",
  "Ensure your refrigerator seal is tight to prevent cold air from escaping.",
  "Wash full loads of laundry to maximize washer and dryer efficiency.",
  "Consider installing a programmable thermostat."
];

List<String> _getRandomTips(int count, {List<String> exclude = const []}) {
  final available = _generalTips.where((tip) => !exclude.contains(tip)).toList();
  available.shuffle(Random());
  return available.take(count).toList();
}

List<String> generateSuggestions({
  required Intent intent,
  required Severity severity,
  required EnergyMetrics data,
  int currentHour = 0,
  List<String> recentTips = const [],
}) {
  List<String> suggestions = [];

  if (severity == Severity.alert || severity == Severity.warning) {
    suggestions.add("Consider turning off appliances in the ${data.peakRoom.isNotEmpty ? data.peakRoom : 'heaviest rooms'} to reduce load.");
    suggestions.add("Check your live usage graph to identify the power spike.");
    return suggestions;
  }

  if (intent == Intent.billPrediction) {
    if (data.monthlyTotalKwh > 200) {
      suggestions.add("You are approaching a higher billing slab. Reducing AC usage could save significant money.");
    }
    suggestions.add("Check the Analytics tab to view your detailed monthly breakdown.");
  }

  if (intent == Intent.realTime) {
    suggestions.add("Ask me 'Which room consumes the most?' to find high usage spots.");
  }

  if (intent == Intent.dailyUsage) {
    suggestions.add("Try asking 'Compare my usage today versus yesterday'.");
  }

  if (intent == Intent.roomComparison) {
    suggestions.add("Switch off appliances in the highest consuming room if not in use.");
  }

  if (intent == Intent.peakHour) {
    suggestions.add("Shift heavy appliance usage away from ${data.peakTime.isNotEmpty ? data.peakTime : 'peak hours'} to lower bills.");
  }

  if (intent == Intent.comparison && data.monthlyTotalKwh < data.lastMonthTotalKwh) {
    suggestions.add("Great job! Try to maintain this trend to keep your next bill low.");
  }

  if (intent == Intent.savingsTips) {
    return _getRandomTips(3, exclude: suggestions);
  }

  if (suggestions.length < 2) {
    final extraHints = _getRandomTips(2 - suggestions.length, exclude: suggestions);
    suggestions.addAll(extraHints);
  }

  return suggestions.take(2).toList();
}

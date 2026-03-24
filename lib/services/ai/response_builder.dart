import 'dart:math';
import '../../models/energy_models.dart';
import '../../models/water_models.dart';
import '../../models/assistant.dart';
import '../../config/assistant_config.dart';
import '../../utils/analytics.dart';
import '../billing_calculator.dart';

String trimToWordLimit(String text, int maxWords) {
  final words = text.split(" ");
  if (words.length <= maxWords) return text;

  // Try to find the last punctuation mark within the limit
  final cutText = words.take(maxWords).join(" ");
  final lastPunctuationIndex = cutText.lastIndexOf(RegExp(r'[.!?]'));

  // If we found a punctuation mark reasonably close to the end, cut there
  if (lastPunctuationIndex > cutText.length * 0.5) {
    return cutText.substring(0, lastPunctuationIndex + 1);
  }

  // Fallback if no good sentence boundary is found
  return cutText + "...";
}

String pickRandomVariant(List<String> variants) {
  final idx = Random().nextInt(variants.length);
  return variants[idx];
}

/// Formats a BucketData-like object's label+total for report listings.
String _formatBucketLine(dynamic bucket) {
  final label = (bucket as BucketData).label;
  final total = bucket.total.toStringAsFixed(2);
  return "$label: ${total} kWh";
}

String buildResponse(
    Intent intent,
    double confidence,
    Severity severity,
    EnergyMetrics data,
    String? timeReference,
    String? contextTopic
) {
  if (intent == Intent.unknown || confidence < AssistantConfig.confidenceThreshold) {
    return pickRandomVariant(AssistantConfig.variants['unknown']!);
  }

  String baseResponse = "";
  final currencySymbol = AssistantConfig.tone['currencySymbol'];

  switch (intent) {
    case Intent.realTime:
      final kw = data.currentPowerKw.toStringAsFixed(2);
      final currentBillAmount = calculateSlabBill(data.monthlyTotalKwh, tariff: data.tariff);
      baseResponse = "Current power usage is $kw kW. "
          "Your bill is $currencySymbol${currentBillAmount.toStringAsFixed(2)} "
          "for ${data.monthlyTotalKwh.toStringAsFixed(1)} kWh this month.";
      break;

    case Intent.dailyUsage:
      baseResponse = "Today's usage is ${data.todayUsageKwh.toStringAsFixed(2)} kWh.";
      if (timeReference == "yesterday") {
        baseResponse = "Yesterday's usage was ${data.yesterdayUsageKwh.toStringAsFixed(2)} kWh.";
      } else {
        baseResponse += " Active load is ${data.currentPowerKw.toStringAsFixed(2)} kW.";
      }
      break;

    case Intent.weeklyUsage:
      if (data.weeklyBuckets.isNotEmpty) {
        final buckets = data.weeklyBuckets.cast<BucketData>();
        final lines = buckets.map((b) => "${b.label}: ${b.total.toStringAsFixed(2)} kWh").join(", ");
        baseResponse = "Weekly breakdown: $lines. "
            "Your daily average this month is ${data.dailyAverageKwh.toStringAsFixed(2)} kWh.";
      } else {
        baseResponse = "Your weekly average is about ${data.weeklyAverageKwh.toStringAsFixed(2)} kWh per day.";
      }
      break;

    case Intent.monthlyUsage:
      final currentBillAmount = calculateSlabBill(data.monthlyTotalKwh, tariff: data.tariff);
      baseResponse = "You've used ${data.monthlyTotalKwh.toStringAsFixed(1)} units this month. "
          "Your current bill is $currencySymbol${currentBillAmount.toStringAsFixed(2)}.";
      break;

    case Intent.currentBill:
      final currentBillAmount = calculateSlabBill(data.monthlyTotalKwh, tariff: data.tariff);
      baseResponse = "Current bill: $currencySymbol${currentBillAmount.toStringAsFixed(2)} "
          "(${data.monthlyTotalKwh.toStringAsFixed(1)} kWh).";
      break;

    case Intent.billPrediction:
      final dt = DateTime.now();
      final prediction = predictMonthlyBill(data.monthlyTotalKwh, dt.day, getDaysInMonth(dt.year, dt.month), tariff: data.tariff);
      baseResponse = "Expected monthly bill: $currencySymbol${prediction.predictedBill.toStringAsFixed(2)}.";
      break;

    case Intent.comparison:
      if (contextTopic == "daily") {
        final diffDaily = data.todayUsageKwh - data.yesterdayUsageKwh;
        if (diffDaily > 0) {
          baseResponse = "Today vs Yesterday: you've used ${diffDaily.toStringAsFixed(2)} MORE kWh today. "
              "(Today: ${data.todayUsageKwh.toStringAsFixed(2)}, Yesterday: ${data.yesterdayUsageKwh.toStringAsFixed(2)} kWh).";
        } else if (diffDaily < 0) {
          baseResponse = "Great job! Today vs Yesterday: you've used ${diffDaily.abs().toStringAsFixed(2)} FEWER kWh today. "
              "(Today: ${data.todayUsageKwh.toStringAsFixed(2)}, Yesterday: ${data.yesterdayUsageKwh.toStringAsFixed(2)} kWh).";
        } else {
          baseResponse = "Your usage today is exactly the same as yesterday: ${data.todayUsageKwh.toStringAsFixed(2)} kWh.";
        }
      } else if (contextTopic == "weekly") {
        baseResponse = "Your daily average this week sits around ${data.dailyAverageKwh.toStringAsFixed(2)} kWh per day. "
            "Check the Analytics tab for detailed trends.";
      } else {
        final diff = data.monthlyTotalKwh - data.lastMonthTotalKwh;
        if (diff > 0) {
          baseResponse = "This month vs last month: you've used ${diff.toStringAsFixed(1)} MORE units this month.";
        } else if (diff < 0) {
          baseResponse = "Great job! You've used ${diff.abs().toStringAsFixed(1)} FEWER units compared to last month.";
        } else {
          baseResponse = "Your usage this month is exactly the same as last month: ${data.monthlyTotalKwh.toStringAsFixed(1)} units.";
        }
      }
      break;

    case Intent.roomComparison:
      final roomsList = [
        {'name': "Bedroom", 'power': data.rooms.bedroomPowerW},
        {'name': "Kitchen", 'power': data.rooms.kitchenPowerW},
        {'name': "Living Room", 'power': data.rooms.livingRoomPowerW}
      ];
      roomsList.sort((a, b) => (b['power'] as double).compareTo(a['power'] as double));
      final highestRoom = roomsList.first;
      final lowestRoom = roomsList.last;

      if (highestRoom['power'] == 0 && lowestRoom['power'] == 0) {
        baseResponse = "Currently, all monitored rooms are drawing zero power.";
      } else if (contextTopic == "least" || contextTopic == "less") {
        baseResponse = "The ${lowestRoom['name']} is consuming the least power: "
            "${(lowestRoom['power'] as double).toStringAsFixed(2)} kW.";
      } else {
        baseResponse = "The ${highestRoom['name']} is consuming the most power: "
            "${(highestRoom['power'] as double).toStringAsFixed(2)} kW.";
      }
      break;

    case Intent.peakHour:
      if (data.peakTime.isNotEmpty) {
        baseResponse = "Your peak usage is around ${data.peakTime}. "
            "The highest-consuming room is ${data.peakRoom}. "
            "Your busiest day overall is ${data.peakDay}.";
      } else {
        baseResponse = "Not enough data yet to determine your peak timing. "
            "Your busiest day so far has been ${data.peakDay}.";
      }
      break;

    case Intent.zoneDistribution:
      final total = data.roomMonthlyEnergy.values.reduce((a, b) => a + b);
      if (total == 0) {
        baseResponse = "Not enough data to show zone distribution for this month yet.";
      } else {
        final br = ((data.roomMonthlyEnergy['Bedroom'] ?? 0) / total * 100).toStringAsFixed(0);
        final lr = ((data.roomMonthlyEnergy['Living Room'] ?? 0) / total * 100).toStringAsFixed(0);
        final kt = ((data.roomMonthlyEnergy['Kitchen'] ?? 0) / total * 100).toStringAsFixed(0);
        baseResponse = "Zone distribution: Bedroom ($br%), Living Room ($lr%), Kitchen ($kt%). "
            "Total: ${total.toStringAsFixed(1)} units.";
      }
      break;

    case Intent.savingsTips:
      baseResponse = "Here are some energy tips: ";
      break;

    case Intent.themeChange:
      if (contextTopic == "dark") {
        baseResponse = "Switching to dark mode.";
      } else if (contextTopic == "light") {
        baseResponse = "Switching to light mode.";
      } else {
        baseResponse = "Changing display theme.";
      }
      break;
    
    case Intent.powerControl:
      if (contextTopic == "all_on") baseResponse = "All rooms turned ON.";
      else if (contextTopic == "all_off") baseResponse = "All rooms turned OFF.";
      else if (contextTopic == "bedroom_on") baseResponse = "Bedroom turned ON.";
      else if (contextTopic == "bedroom_off") baseResponse = "Bedroom turned OFF.";
      else if (contextTopic == "living_on") baseResponse = "Living Room turned ON.";
      else if (contextTopic == "living_off") baseResponse = "Living Room turned OFF.";
      else if (contextTopic == "kitchen_on") baseResponse = "Kitchen turned ON.";
      else if (contextTopic == "kitchen_off") baseResponse = "Kitchen turned OFF.";
      else baseResponse = "I've updated the room status for you.";
      break;

    // ── NEW REPORT INTENTS ─────────────────────────────────────────────────

    case Intent.dailyReport:
      final kw = data.currentPowerKw.toStringAsFixed(2);
      final monthBill = calculateSlabBill(data.monthlyTotalKwh, tariff: data.tariff);
      baseResponse = "Daily Report: "
          "Live load: $kw kW. "
          "Today's usage: ${data.todayUsageKwh.toStringAsFixed(2)} kWh. "
          "Monthly total: ${data.monthlyTotalKwh.toStringAsFixed(1)} kWh "
          "($currencySymbol${monthBill.toStringAsFixed(2)}).";
      break;

    case Intent.weeklyReport:
      final avgKwh = data.dailyAverageKwh.toStringAsFixed(2);
      baseResponse = "Weekly Report: "
          "Daily average: $avgKwh kWh/day. "
          "Monthly total: ${data.monthlyTotalKwh.toStringAsFixed(1)} kWh.";
      break;

    case Intent.monthlyReport:
      final monthBill = calculateSlabBill(data.monthlyTotalKwh, tariff: data.tariff);
      final dt = DateTime.now();
      final prediction = predictMonthlyBill(data.monthlyTotalKwh, dt.day, getDaysInMonth(dt.year, dt.month), tariff: data.tariff);
      baseResponse = "Monthly Report: "
          "This month: ${data.monthlyTotalKwh.toStringAsFixed(1)} kWh, "
          "bill: $currencySymbol${monthBill.toStringAsFixed(2)}. "
          "Projected: $currencySymbol${prediction.predictedBill.toStringAsFixed(2)}.";
      break;

    case Intent.highestConsumption:
      if (data.monthlyBuckets.isNotEmpty) {
        final buckets = data.monthlyBuckets.cast<BucketData>();
        BucketData peak = buckets.reduce((a, b) => a.total > b.total ? a : b);
        baseResponse = "The highest consuming month is ${peak.label} with "
            "${peak.total.toStringAsFixed(1)} kWh. "
            "This month (current) you've used ${data.monthlyTotalKwh.toStringAsFixed(1)} units.";
      } else {
        baseResponse = "Not enough monthly data yet to compare. "
            "This month you've used ${data.monthlyTotalKwh.toStringAsFixed(1)} units.";
      }
      break;

    case Intent.averageConsumption:
      baseResponse = "Your average daily consumption this month is "
          "${data.dailyAverageKwh.toStringAsFixed(2)} kWh/day. "
          "Weekly average: ${data.weeklyAverageKwh.toStringAsFixed(2)} kWh. "
          "Monthly total: ${data.monthlyTotalKwh.toStringAsFixed(1)} units.";
      break;
    
    case Intent.greeting:
      baseResponse = pickRandomVariant(AssistantConfig.variants['greeting']!);
      break;

    case Intent.thanks:
      baseResponse = pickRandomVariant(AssistantConfig.variants['thanks']!);
      break;

    case Intent.bye:
      baseResponse = pickRandomVariant(AssistantConfig.variants['bye']!);
      break;

    default:
      baseResponse = pickRandomVariant(AssistantConfig.variants['unknown']!);
  }

  return trimToWordLimit(baseResponse, AssistantConfig.tone['maxWords']);
}

String buildWaterResponse(
    Intent intent,
    double confidence,
    Severity severity,
    WaterMetrics data,
    String? timeReference,
    String? contextTopic
) {
  if (intent == Intent.unknown || confidence < AssistantConfig.confidenceThreshold) {
    return pickRandomVariant(AssistantConfig.variants['unknown']!);
  }

  String baseResponse = "";
  final currencySymbol = AssistantConfig.tone['currencySymbol'];

  switch (intent) {
    case Intent.realTime:
      final lpm = data.currentFlowLpm.toStringAsFixed(1);
      final currentBillAmount = calculateWaterBill(data.monthlyTotalL, tariff: data.tariff);
      baseResponse = "Flow is $lpm L/min. "
          "Current bill is $currencySymbol${currentBillAmount.toStringAsFixed(2)} "
          "for ${data.monthlyTotalL.toStringAsFixed(1)} Liters.";
      break;

    case Intent.dailyUsage:
      baseResponse = "Today's usage is ${data.todayUsageL.toStringAsFixed(1)} L.";
      if (timeReference == "yesterday") {
        baseResponse = "Yesterday's usage was ${data.yesterdayUsageL.toStringAsFixed(1)} L.";
      } else if (data.currentFlowLpm > 0) {
        baseResponse += " Current flow: ${data.currentFlowLpm.toStringAsFixed(1)} L/min.";
      }
      break;

    case Intent.weeklyUsage:
      baseResponse = "Daily average: ${data.dailyAverageL.toStringAsFixed(1)} L. "
          "Weekly average: ${data.weeklyAverageL.toStringAsFixed(1)} L.";
      break;

    case Intent.monthlyUsage:
      final currentBillAmount = calculateWaterBill(data.monthlyTotalL, tariff: data.tariff);
      baseResponse = "Monthly usage: ${data.monthlyTotalL.toStringAsFixed(1)} L. "
          "Bill: $currencySymbol${currentBillAmount.toStringAsFixed(2)}.";
      break;

    case Intent.currentBill:
      final currentBillAmount = calculateWaterBill(data.monthlyTotalL, tariff: data.tariff);
      baseResponse = "Current bill: $currencySymbol${currentBillAmount.toStringAsFixed(2)} "
          "(${data.monthlyTotalL.toStringAsFixed(1)} L).";
      break;

    case Intent.billPrediction:
      final dt = DateTime.now();
      final prediction = predictWaterBill(data.monthlyTotalL, dt.day, getDaysInMonth(dt.year, dt.month), tariff: data.tariff);
      baseResponse = "Expected monthly bill: $currencySymbol${prediction.predictedBill.toStringAsFixed(2)}.";
      break;

    case Intent.comparison:
      if (contextTopic == "daily") {
        final diffDaily = data.todayUsageL - data.yesterdayUsageL;
        if (diffDaily >= 0) {
          baseResponse = "You used ${diffDaily.toStringAsFixed(1)} MORE Liters today.";
        } else {
          baseResponse = "You used ${diffDaily.abs().toStringAsFixed(1)} FEWER Liters today.";
        }
      } else {
        final diff = data.monthlyTotalL - data.lastMonthTotalL;
        if (diff >= 0) {
          baseResponse = "You used ${diff.toStringAsFixed(1)} MORE Liters this month.";
        } else {
          baseResponse = "You used ${diff.abs().toStringAsFixed(1)} FEWER Liters this month.";
        }
      }
      break;

    case Intent.roomComparison:
      final roomsList = [
        {'name': "Bedroom", 'flow': data.rooms.bedroomFlowLpm},
        {'name': "Kitchen", 'flow': data.rooms.kitchenFlowLpm},
        {'name': "Living Room", 'flow': data.rooms.livingRoomFlowLpm}
      ];
      roomsList.sort((a, b) => (b['flow'] as double).compareTo(a['flow'] as double));
      final highestRoom = roomsList.first;
      final lowestRoom = roomsList.last;

      if (highestRoom['flow'] == 0 && lowestRoom['flow'] == 0) {
        baseResponse = "Currently, all monitored room taps are completely off.";
      } else if (contextTopic == "least" || contextTopic == "less") {
        baseResponse = "The ${lowestRoom['name']} tap is draining the least water: "
            "${(lowestRoom['flow'] as double).toStringAsFixed(1)} L/min.";
      } else {
        baseResponse = "The ${highestRoom['name']} tap is draining the most water right now: "
            "${(highestRoom['flow'] as double).toStringAsFixed(1)} L/min.";
      }
      break;

    case Intent.peakHour:
      if (data.peakTime.isNotEmpty) {
        baseResponse = "Peak usage: ${data.peakTime} in ${data.peakRoom}.";
      } else {
        baseResponse = "Busiest day: ${data.peakDay}.";
      }
      break;

    case Intent.savingsTips:
      baseResponse = "Here are some water tips: ";
      break;

    case Intent.powerControl:
      if (contextTopic == "all_on") baseResponse = "Motor pump turned ON.";
      else if (contextTopic == "all_off") baseResponse = "Motor pump turned OFF.";
      else if (contextTopic == "bedroom_on" || contextTopic == "living_on" || contextTopic == "kitchen_on") baseResponse = "Water outlet opened.";
      else if (contextTopic == "bedroom_off" || contextTopic == "living_off" || contextTopic == "kitchen_off") baseResponse = "Water outlet closed.";
      else baseResponse = "Valve state updated.";
      break;

    // ── NEW REPORT INTENTS ─────────────────────────────────────────────────

    case Intent.dailyReport:
      final lpm = data.currentFlowLpm.toStringAsFixed(1);
      final monthBill = calculateWaterBill(data.monthlyTotalL, tariff: data.tariff);
      baseResponse = "📊 Daily Report: Flow $lpm L/min | Today ${data.todayUsageL.toStringAsFixed(1)} L | Month $currencySymbol${monthBill.toStringAsFixed(2)}.";
      break;

    case Intent.weeklyReport:
      final avgL = data.dailyAverageL.toStringAsFixed(1);
      baseResponse = "📊 Weekly Water Report: "
          "Daily average: $avgL Liters/day. "
          "Monthly total so far: ${data.monthlyTotalL.toStringAsFixed(1)} Liters.";
      break;

    case Intent.monthlyReport:
      final monthBill = calculateWaterBill(data.monthlyTotalL, tariff: data.tariff);
      final dt = DateTime.now();
      final prediction = predictWaterBill(data.monthlyTotalL, dt.day, getDaysInMonth(dt.year, dt.month), tariff: data.tariff);
      baseResponse = "📊 Monthly Report: ${data.monthlyTotalL.toStringAsFixed(1)} L ($currencySymbol${monthBill.toStringAsFixed(2)}). "
          "Projected: $currencySymbol${prediction.predictedBill.toStringAsFixed(2)}.";
      break;

    case Intent.highestConsumption:
      baseResponse = "Check your analytics graph to review your highest consuming months.";
      break;

    case Intent.averageConsumption:
      baseResponse = "Your average daily water consumption this month is "
          "${data.dailyAverageL.toStringAsFixed(1)} Liters/day. "
          "Weekly average: ${data.weeklyAverageL.toStringAsFixed(1)} Liters. "
          "Monthly total: ${data.monthlyTotalL.toStringAsFixed(1)} Liters.";
      break;
    
    case Intent.greeting:
      baseResponse = pickRandomVariant(AssistantConfig.variants['greeting']!);
      break;

    case Intent.thanks:
      baseResponse = pickRandomVariant(AssistantConfig.variants['thanks']!);
      break;

    case Intent.bye:
      baseResponse = pickRandomVariant(AssistantConfig.variants['bye']!);
      break;

    default:
      baseResponse = pickRandomVariant(AssistantConfig.variants['unknown']!);
  }

  return trimToWordLimit(baseResponse, AssistantConfig.tone['maxWords']);
}

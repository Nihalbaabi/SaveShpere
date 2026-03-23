import '../services/firebase_service.dart';
import 'mock_data.dart';

class BucketData {
  final String label;
  double bedroom;
  double livingRoom;
  double kitchen;
  double total;

  BucketData({
    required this.label,
    this.bedroom = 0,
    this.livingRoom = 0,
    this.kitchen = 0,
    this.total = 0,
  });
}

class HourlyPeak {
  final String hour;
  final double total;
  final String topRoom;
  final double topRoomValue;

  HourlyPeak({
    required this.hour,
    required this.total,
    required this.topRoom,
    required this.topRoomValue,
  });
}

// Convert cumulative energy logs into delta energy array.
List<DeltaLog> computeDeltas(List<EnergyLog> logs) {
  List<DeltaLog> deltas = [];
  for (int i = 1; i < logs.length; i++) {
    final prev = logs[i - 1];
    final curr = logs[i];

    double db = curr.energy['bedroom']! - prev.energy['bedroom']!;
    double dl = curr.energy['livingRoom']! - prev.energy['livingRoom']!;
    double dk = curr.energy['kitchen']! - prev.energy['kitchen']!;

    // If any delta is negative, the ESP32 counter was reset.
    // Treat the current reading as the delta itself (fresh start after reset).
    // This ensures the monthly total never DECREASES after a device reboot.
    if (db < 0) db = curr.energy['bedroom']!;
    if (dl < 0) dl = curr.energy['livingRoom']!;
    if (dk < 0) dk = curr.energy['kitchen']!;

    // Skip completely zero-delta readings (no consumption) to avoid noise
    if (db == 0 && dl == 0 && dk == 0) continue;

    String date = "";
    int hour = 0;

    if (curr.timestamp.contains("_")) {
      final parts = curr.timestamp.split("_");
      date = parts[0];
      final timePart = parts.length > 1 ? parts[1] : "00-00-00";
      hour = int.tryParse(timePart.split("-")[0]) ?? 0;
    } else {
      final parts = curr.timestamp.split(" ");
      date = parts[0];
      final timePart = parts.length > 1 ? parts[1] : "00:00:00";
      hour = int.tryParse(timePart.split(":")[0]) ?? 0;
    }

    deltas.add(DeltaLog(
      timestamp: curr.timestamp,
      date: date,
      hour: hour,
      deltaBedroom: db,
      deltaLivingRoom: dl,
      deltaKitchen: dk,
      deltaTotal: db + dl + dk,
      power: curr.power,
    ));
  }
  return deltas;
}

// Filter deltas for current month
List<DeltaLog> filterCurrentMonth(List<DeltaLog> deltas) {
  final now = DateTime.now();
  final padMonth = now.month.toString().padLeft(2, '0');
  final prefix = "${now.year}-$padMonth";
  return deltas.where((d) => d.date.startsWith(prefix)).toList();
}

// Live Hourly graph: 24 hourly buckets (12 AM to 11 PM) for CURRENT day ONLY
List<BucketData> groupHourlyLive(List<DeltaLog> deltas) {
  List<BucketData> buckets = List.generate(24, (i) {
    final ampm = i >= 12 ? "PM" : "AM";
    final h12 = i == 0 ? 12 : i > 12 ? i - 12 : i;
    return BucketData(label: "$h12$ampm");
  });

  final now = DateTime.now();
  final yyyy = now.year.toString();
  final mm = now.month.toString().padLeft(2, '0');
  final dd = now.day.toString().padLeft(2, '0');
  final todayStr = "$yyyy-$mm-$dd";

  for (final d in deltas) {
    if (d.date != todayStr) continue;

    if (d.hour >= 0 && d.hour < 24) {
      buckets[d.hour].bedroom += d.deltaBedroom;
      buckets[d.hour].livingRoom += d.deltaLivingRoom;
      buckets[d.hour].kitchen += d.deltaKitchen;
      buckets[d.hour].total += d.deltaTotal;
    }
  }
  return buckets;
}

// Daily graph (Mon-Sun): Dynamic up to last 7 days filtering from March 1st
List<BucketData> groupDailyMonToSun(List<DeltaLog> deltas) {
  const startDate = "2026-03-01";
  const daysStr = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];

  final now = DateTime.now();
  final yyyy = now.year.toString();
  final mm = now.month.toString().padLeft(2, '0');
  final dd = now.day.toString().padLeft(2, '0');
  final todayStr = "$yyyy-$mm-$dd";

  final cutoff = now.subtract(const Duration(days: 6));
  final cutoffStr = "${cutoff.year}-${cutoff.month.toString().padLeft(2, '0')}-${cutoff.day.toString().padLeft(2, '0')}";

  final effectiveStart = startDate.compareTo(cutoffStr) > 0 ? startDate : cutoffStr;

  Map<String, BucketData> dateMap = {};

  for (final d in deltas) {
    if (d.date.compareTo(effectiveStart) < 0) continue;
    if (d.date.compareTo(todayStr) > 0) continue;

    if (!dateMap.containsKey(d.date)) {
      final parts = d.date.split("-").map((e) => int.parse(e)).toList();
      final dt = DateTime(parts[0], parts[1], parts[2]);
      dateMap[d.date] = BucketData(label: daysStr[dt.weekday % 7]);
    }

    final b = dateMap[d.date]!;
    b.bedroom += d.deltaBedroom;
    b.livingRoom += d.deltaLivingRoom;
    b.kitchen += d.deltaKitchen;
    b.total += d.deltaTotal;
  }

  List<BucketData> result = [];
  final sparts = effectiveStart.split("-").map((e) => int.parse(e)).toList();
  DateTime startDt = DateTime(sparts[0], sparts[1], sparts[2]);
  
  final eparts = todayStr.split("-").map((e) => int.parse(e)).toList();
  DateTime endDt = DateTime(eparts[0], eparts[1], eparts[2]);

  // Always render every day from start to today (even zero-data days show as empty bars)
  for (DateTime dt = startDt; !dt.isAfter(endDt); dt = dt.add(const Duration(days: 1))) {
    final dStr = "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";

    if (dateMap.containsKey(dStr)) {
      result.add(dateMap[dStr]!);
    } else {
      // No data for this day — add an empty bucket so it still appears on the graph
      result.add(BucketData(label: daysStr[dt.weekday % 7]));
    }
  }

  return result;
}

// Weekly graph (W1-W4): 4 week buckets for current month
List<BucketData> groupWeeklyW1ToW4(List<DeltaLog> deltas) {
  final monthDeltas = filterCurrentMonth(deltas);
  List<BucketData> buckets = [
    BucketData(label: "Week 1"),
    BucketData(label: "Week 2"),
    BucketData(label: "Week 3"),
    BucketData(label: "Week 4"),
  ];

  for (final d in monthDeltas) {
    int day = int.tryParse(d.date.split("-")[2]) ?? 1;
    int idx;
    if (day <= 7) idx = 0;
    else if (day <= 14) idx = 1;
    else if (day <= 21) idx = 2;
    else idx = 3;

    buckets[idx].bedroom += d.deltaBedroom;
    buckets[idx].livingRoom += d.deltaLivingRoom;
    buckets[idx].kitchen += d.deltaKitchen;
    buckets[idx].total += d.deltaTotal;
  }

  return buckets;
}

// Monthly graph (Jan-Dec): 12 month buckets for current year
List<BucketData> groupMonthlyJanToDec(List<DeltaLog> deltas) {
  const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
  List<BucketData> buckets = months.map((m) => BucketData(label: m)).toList();

  final currentYearStr = DateTime.now().year.toString();

  for (final d in deltas) {
    if (!d.date.startsWith(currentYearStr)) continue;

    final monthStr = d.date.split("-")[1];
    final monthIndex = (int.tryParse(monthStr) ?? 1) - 1;
    
    if (monthIndex >= 0 && monthIndex < 12) {
      buckets[monthIndex].bedroom += d.deltaBedroom;
      buckets[monthIndex].livingRoom += d.deltaLivingRoom;
      buckets[monthIndex].kitchen += d.deltaKitchen;
      buckets[monthIndex].total += d.deltaTotal;
    }
  }

  return buckets;
}

// Current month total delta energy
Map<String, double> getMonthTotalEnergy(List<DeltaLog> deltas) {
  Map<String, double> result = {'bedroom': 0, 'livingRoom': 0, 'kitchen': 0, 'total': 0};
  if (deltas.isEmpty) return result;
  
  final monthDeltas = filterCurrentMonth(deltas);
  for (final d in monthDeltas) {
    result['bedroom'] = result['bedroom']! + d.deltaBedroom;
    result['livingRoom'] = result['livingRoom']! + d.deltaLivingRoom;
    result['kitchen'] = result['kitchen']! + d.deltaKitchen;
    result['total'] = result['total']! + d.deltaTotal;
  }
  return result;
}

// Peak usage: find the hour with max delta energy this month, and top room
HourlyPeak? findPeakUsage(List<DeltaLog> deltas) {
  final monthDeltas = filterCurrentMonth(deltas);
  Map<int, Map<String, double>> hourMap = {};

  for (final d in monthDeltas) {
    hourMap.putIfAbsent(d.hour, () => {'bedroom': 0, 'livingRoom': 0, 'kitchen': 0, 'total': 0});
    hourMap[d.hour]!['bedroom'] = hourMap[d.hour]!['bedroom']! + d.deltaBedroom;
    hourMap[d.hour]!['livingRoom'] = hourMap[d.hour]!['livingRoom']! + d.deltaLivingRoom;
    hourMap[d.hour]!['kitchen'] = hourMap[d.hour]!['kitchen']! + d.deltaKitchen;
    hourMap[d.hour]!['total'] = hourMap[d.hour]!['total']! + d.deltaTotal;
  }

  HourlyPeak? peak;
  double maxTotal = 0;

  hourMap.forEach((hour, data) {
    if (data['total']! > maxTotal) {
      maxTotal = data['total']!;
      List<Map<String, dynamic>> rooms = [
        {"name": "Bedroom", "val": data['bedroom']},
        {"name": "Living Room", "val": data['livingRoom']},
        {"name": "Kitchen", "val": data['kitchen']},
      ];
      rooms.sort((a, b) => (b["val"] as double).compareTo(a["val"] as double));
      
      final ampm = hour >= 12 ? "PM" : "AM";
      final h12 = (hour % 12 == 0) ? 12 : hour % 12;
      
      final nextHour = (hour + 1) % 24;
      final nextAmpm = nextHour >= 12 ? "PM" : "AM";
      final nextH12 = (nextHour % 12 == 0) ? 12 : nextHour % 12;
      
      peak = HourlyPeak(
        hour: "$h12 $ampm – $nextH12 $nextAmpm",
        total: double.parse((data['total']!).toStringAsFixed(4)),
        topRoom: rooms[0]["name"] as String,
        topRoomValue: double.parse((rooms[0]["val"]).toStringAsFixed(4)),
      );
    }
  });

  return peak;
}

// Peak Usage Day: find the day of the week with highest cumulative usage this month
String findPeakUsageDay(List<DeltaLog> deltas) {
  final monthDeltas = filterCurrentMonth(deltas);
  if (monthDeltas.isEmpty) return "Analyzing...";

  const daysStr = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
  Map<int, double> weekdayUsage = {}; // weekday (0-6) -> total consumption

  for (final d in monthDeltas) {
    if (d.date.isEmpty) continue;
    final parts = d.date.split("-").map((e) => int.parse(e)).toList();
    if (parts.length < 3) continue;
    
    final dt = DateTime(parts[0], parts[1], parts[2]);
    final weekday = dt.weekday % 7; // Sunday = 0, Monday = 1...
    
    weekdayUsage[weekday] = (weekdayUsage[weekday] ?? 0) + d.deltaTotal;
  }

  if (weekdayUsage.isEmpty) return "Analyzing...";

  int peakDayIndex = 0;
  double maxUsage = -1.0;

  weekdayUsage.forEach((day, usage) {
    if (usage > maxUsage) {
      maxUsage = usage;
      peakDayIndex = day;
    }
  });

  return daysStr[peakDayIndex];
}

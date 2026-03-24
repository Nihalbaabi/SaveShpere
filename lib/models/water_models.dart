import '../utils/analytics.dart';

class RoomWaterMetrics {
  final double bedroomFlowLpm;
  final double kitchenFlowLpm;
  final double livingRoomFlowLpm;

  RoomWaterMetrics({
    required this.bedroomFlowLpm,
    required this.kitchenFlowLpm,
    required this.livingRoomFlowLpm,
  });
}

class WaterMetrics {
  final double currentFlowLpm;
  final double tankLevel;          // current liters in tank
  final double tankCapacity;       // max liters
  final bool motorStatus;          // is motor (refill) ON?
  final bool outletOn;             // is outlet (drain) ON?
  final double todayUsageL;
  final double yesterdayUsageL;
  final double weeklyAverageL;
  final double monthlyTotalL;
  final double lastMonthTotalL;
  final double dailyAverageL;
  final String peakTime;
  final String peakRoom;
  final String peakDay;
  final double estimatedMonthlyLiters;
  final dynamic tariff;
  final RoomWaterMetrics rooms;
  final List<BucketData> weeklyBuckets;
  final List<BucketData> monthlyBuckets;
  final List<BucketData> dailyBuckets;
  final Map<String, double> roomMonthlyWater;

  WaterMetrics({
    required this.currentFlowLpm,
    this.tankLevel = 1000,
    this.tankCapacity = 1000,
    this.motorStatus = false,
    this.outletOn = false,
    required this.todayUsageL,
    required this.yesterdayUsageL,
    required this.weeklyAverageL,
    required this.monthlyTotalL,
    required this.lastMonthTotalL,
    required this.dailyAverageL,
    required this.peakTime,
    required this.peakRoom,
    required this.peakDay,
    required this.estimatedMonthlyLiters,
    required this.tariff,
    required this.rooms,
    required this.weeklyBuckets,
    required this.monthlyBuckets,
    required this.dailyBuckets,
    required this.roomMonthlyWater,
  });

  double get tankPercent => (tankLevel / tankCapacity).clamp(0.0, 1.0);
  bool get isTankLow => tankLevel < 250;
}

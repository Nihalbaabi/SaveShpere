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
}

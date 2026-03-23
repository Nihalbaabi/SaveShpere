import '../utils/analytics.dart';

class RoomMetrics {
  final double bedroomPowerW;
  final double kitchenPowerW;
  final double livingRoomPowerW;

  RoomMetrics({
    required this.bedroomPowerW,
    required this.kitchenPowerW,
    required this.livingRoomPowerW,
  });
}

class EnergyMetrics {
  final double currentPowerKw;
  final double todayUsageKwh;
  final double yesterdayUsageKwh;
  final double weeklyAverageKwh;
  final double monthlyTotalKwh;
  final double lastMonthTotalKwh;
  final double dailyAverageKwh;
  final String peakTime;
  final String peakRoom;
  final String peakDay;
  final double estimatedMonthlyUnits;
  final dynamic tariff;
  final RoomMetrics rooms;
  final List<BucketData> weeklyBuckets;
  final List<BucketData> monthlyBuckets;
  final List<BucketData> dailyBuckets;
  final Map<String, double> roomMonthlyEnergy;

  EnergyMetrics({
    required this.currentPowerKw,
    required this.todayUsageKwh,
    required this.yesterdayUsageKwh,
    required this.weeklyAverageKwh,
    required this.monthlyTotalKwh,
    required this.lastMonthTotalKwh,
    required this.dailyAverageKwh,
    required this.peakTime,
    required this.peakRoom,
    required this.peakDay,
    required this.estimatedMonthlyUnits,
    required this.tariff,
    required this.rooms,
    required this.weeklyBuckets,
    required this.monthlyBuckets,
    required this.dailyBuckets,
    required this.roomMonthlyEnergy,
  });
}

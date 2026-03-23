import 'dart:async';
import 'package:flutter/material.dart';
import '../models/water_models.dart';
import '../services/firebase_service.dart';
import '../utils/analytics.dart';
import '../utils/water_mock_data.dart';
import '../utils/mock_data.dart';

class WaterDataProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  
  EnergyLog? _liveData;
  EnergyLog? get liveData => _liveData;

  List<EnergyLog> _historicalLogs = [];
  List<EnergyLog> get historicalLogs => _historicalLogs;

  List<DeltaLog> _deltas = [];
  List<DeltaLog> get deltas => _deltas;

  List<BucketData> _hourlyLive = [];
  List<BucketData> get hourlyLive => _hourlyLive;

  List<BucketData> _daily = [];
  List<BucketData> get daily => _daily;

  List<BucketData> _weekly = [];
  List<BucketData> get weekly => _weekly;

  List<BucketData> _monthly = [];
  List<BucketData> get monthly => _monthly;

  StreamSubscription? _liveSubscription;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  WaterDataProvider() {
    _init();
  }

  void _init() async {
    try {
      _historicalLogs = await _firebaseService.fetchWaterLogs();
      _processAnalytics();
      
      _liveSubscription = _firebaseService.getWaterLiveStream().listen((log) {
        if (log != null) {
          _liveData = log;
          bool isNew = true;
          if (_historicalLogs.isNotEmpty) {
            final lastLog = _historicalLogs.last;
            if (lastLog.timestamp == log.timestamp) {
              isNew = false;
            }
          }

          if (isNew) {
            _historicalLogs.add(log);
            _processAnalytics();
          }
          notifyListeners();
        }
      });
    } catch (e) {
      print("Error fetching Water data: \$e");
      _processAnalytics();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _processAnalytics() {
    final computedDeltas = computeDeltas(_historicalLogs);
    final mockDeltas = getJanFebMockWaterDeltas();
    
    final now = DateTime.now();
    final historicalMockData = mockDeltas.where((m) {
      final parts = m.date.split("-");
      final mMonth = int.tryParse(parts[1]) ?? 0;
      return mMonth < now.month;
    }).toList();

    _deltas = [
      ...historicalMockData,
      ...computedDeltas
    ];
    
    _hourlyLive = groupHourlyLive(_deltas);
    _daily = groupDailyMonToSun(_deltas);
    _weekly = groupWeeklyW1ToW4(_deltas);
    _monthly = groupMonthlyJanToDec(_deltas);
  }

  WaterMetrics? get waterMetrics {
    if (_liveData == null && _historicalLogs.isEmpty && _deltas.isEmpty) return null;

    final monthWaterMap = getMonthTotalEnergy(_deltas); 
    
    double liveBedroomLiters = _liveData?.energy['bedroom'] ?? 0.0;
    double liveKitchenLiters = _liveData?.energy['kitchen'] ?? 0.0;
    double liveLivingRoomLiters = _liveData?.energy['livingRoom'] ?? 0.0;
    double liveTotalLiters = liveBedroomLiters + liveKitchenLiters + liveLivingRoomLiters;

    final currentMonthLiters = liveTotalLiters > 0 ? liveTotalLiters : (monthWaterMap['total'] ?? 0.0);
    
    double todayLiters = 0;
    double yesterdayLiters = 0;
    
    if (_daily.isNotEmpty) {
       todayLiters = _daily.last.total;
       if (_daily.length > 1) {
          yesterdayLiters = _daily[_daily.length - 2].total;
       }
    }

    final daysPassed = DateTime.now().day > 0 ? DateTime.now().day : 1;
    final dailyAvg = currentMonthLiters / daysPassed;

    final lastPower = _liveData?.power ?? {
       'bedroom': 0.0,
       'livingRoom': 0.0,
       'kitchen': 0.0,
       'total': 0.0,
    };

    final peak = findPeakUsage(_deltas);
    final peakDay = findPeakUsageDay(_deltas);
    
    final now = DateTime.now();
    final totalDays = getDaysInMonth(now.year, now.month);
    final estimatedLiters = dailyAvg * totalDays;

    List<Map<String, dynamic>> roomTotals = [
      {"name": "Bedroom", "val": liveBedroomLiters > 0 ? liveBedroomLiters : (monthWaterMap['bedroom'] ?? 0.0)},
      {"name": "Living Room", "val": liveLivingRoomLiters > 0 ? liveLivingRoomLiters : (monthWaterMap['livingRoom'] ?? 0.0)},
      {"name": "Kitchen", "val": liveKitchenLiters > 0 ? liveKitchenLiters : (monthWaterMap['kitchen'] ?? 0.0)},
    ];
    roomTotals.sort((a, b) => (b["val"] as double).compareTo(a["val"] as double));
    final monthlyTopRoom = roomTotals[0]["name"] as String;

    return WaterMetrics(
      currentFlowLpm: (lastPower['total'] as num).toDouble(),
      todayUsageL: todayLiters,
      yesterdayUsageL: yesterdayLiters,
      weeklyAverageL: dailyAvg * 7,
      monthlyTotalL: currentMonthLiters,
      lastMonthTotalL: currentMonthLiters * 0.9,
      dailyAverageL: dailyAvg,
      peakTime: peak?.hour ?? "",
      peakRoom: monthlyTopRoom,
      peakDay: peakDay,
      estimatedMonthlyLiters: estimatedLiters,
      tariff: null,
      rooms: RoomWaterMetrics(
        bedroomFlowLpm: (lastPower['bedroom'] as num).toDouble(),
        kitchenFlowLpm: (lastPower['kitchen'] as num).toDouble(),
        livingRoomFlowLpm: (lastPower['livingRoom'] as num).toDouble(),
      ),
      weeklyBuckets: _weekly,
      monthlyBuckets: _monthly,
      dailyBuckets: _hourlyLive,
      roomMonthlyWater: {
        'Bedroom': liveBedroomLiters > 0 ? liveBedroomLiters : (monthWaterMap['bedroom'] ?? 0.0),
        'Living Room': liveLivingRoomLiters > 0 ? liveLivingRoomLiters : (monthWaterMap['livingRoom'] ?? 0.0),
        'Kitchen': liveKitchenLiters > 0 ? liveKitchenLiters : (monthWaterMap['kitchen'] ?? 0.0),
      },
    );
  }

  int getDaysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;
  
  @override
  void dispose() {
    _liveSubscription?.cancel();
    super.dispose();
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';
import '../services/notification_tracker.dart';
import '../services/billing_calculator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/energy_models.dart';
import '../utils/analytics.dart';
import '../utils/mock_data.dart';

class EnergyDataProvider extends ChangeNotifier {
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

  Map<String, double> get monthEnergy {
    if (_deltas.isEmpty) return {'total': 0.0, 'bedroom': 0.0, 'livingRoom': 0.0, 'kitchen': 0.0};
    return getMonthTotalEnergy(_deltas);
  }

  HourlyPeak? get peak {
    return findPeakUsage(_deltas);
  }

  Map<String, dynamic> _roomsData = {};
  Map<String, dynamic> get roomsData => _roomsData;

  dynamic _tariffData;
  
  StreamSubscription? _liveSubscription;
  StreamSubscription? _controlSubscription;
  StreamSubscription? _roomsSubscription;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  EnergyDataProvider() {
    _init();
  }

  void _init() async {
    try {
      _tariffData = await _firebaseService.fetchSettings();
      _historicalLogs = await _firebaseService.fetchLogs();
      
      _processAnalytics();
      
      // Request permissions on init
      await NotificationService().requestPermission();

      // Subscribe to live
      _liveSubscription = _firebaseService.getLiveStream().listen((log) {
        if (log != null) {
          // CRITICAL FIX: Preserve switch states from the control stream — do NOT
          // let the /live telemetry (sent every 60s by ESP32) overwrite the current
          // toggle states that the user may have just changed.
          if (_liveData != null) {
            log.switches.addAll(_liveData!.switches); // Keep latest control states
          }

          _liveData = log;

          // Check if it's a new log before appending
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

      // Subscribe to control
      _controlSubscription = _firebaseService.getControlStream().listen((switches) {
        if (_liveData != null) {
          _liveData!.switches.addAll(switches);
          notifyListeners();
        } else {
          // If live data hasn't arrived yet, create a dummy log to hold switches
          _liveData = EnergyLog(
            timestamp: DateTime.now().toString(),
            power: {'bedroom': 0, 'livingRoom': 0, 'kitchen': 0, 'total': 0},
            energy: {'bedroom': 0, 'livingRoom': 0, 'kitchen': 0},
            switches: Map.from(switches),
          );
          notifyListeners();
        }
      });

      // Subscribe to simplified room-level state (AGGREGATED)
      _roomsSubscription = _firebaseService.getRoomsStream().listen((data) {
        _roomsData = data;
        notifyListeners();
      });
    } catch (e) {
      print("Error fetching from Firebase: $e");
      // Continue with mock data already initialized
      _processAnalytics();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _processAnalytics() async {
    final computedDeltas = computeDeltas(_historicalLogs);
    final mockDeltas = getJanFebMockDeltas();
    
    // Filter mock data: only keep data from PREVIOUS months.
    // Current month (March) will be real-only.
    final now = DateTime.now();
    final historicalMockData = mockDeltas.where((m) {
      final parts = m.date.split("-");
      final mMonth = int.tryParse(parts[1]) ?? 0;
      return mMonth < now.month;
    }).toList();

    // Combine: Mock data for Jan/Feb + Real data for March
    _deltas = [
      ...historicalMockData,
      ...computedDeltas
    ];
    
    _hourlyLive = groupHourlyLive(_deltas);
    _daily = groupDailyMonToSun(_deltas);
    _weekly = groupWeeklyW1ToW4(_deltas);
    _monthly = groupMonthlyJanToDec(_deltas);

    // Notification Triggers
    _checkNotificationTriggers();
  }

  Future<void> _checkNotificationTriggers() async {
    final metrics = energyMetrics;
    if (metrics == null) return;

    final tracker = NotificationTracker();
    final notifier = NotificationService();
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Budget Alerts
    final budget = prefs.getDouble('monthly_budget') ?? 0.0;
    if (budget > 0) {
      final currentBill = calculateSlabBill(metrics.monthlyTotalKwh, tariff: metrics.tariff ?? defaultTariff);
      final percent = (currentBill / budget) * 100;

      if (percent >= 100) {
        if (await tracker.shouldNotifyBudget(100)) {
          notifier.showNotification("Budget Limit Reached", "Your energy budget has been fully used.", type: 'budget');
        }
      } else if (percent >= 75) {
        if (await tracker.shouldNotifyBudget(75)) {
          notifier.showNotification("High Usage Warning", "You have reached 75% of your energy budget.", type: 'budget');
        }
      } else if (percent >= 50) {
        if (await tracker.shouldNotifyBudget(50)) {
          notifier.showNotification("Budget Usage Alert", "You have used 50% of your monthly energy budget.", type: 'budget');
        }
      }
    }

    // 2. Power Usage Alerts (Expected usage)
    // Assuming expected usage is stored or calculated. Let's use 1000 units as default if not set.
    final expectedUsage = prefs.getDouble('expected_monthly_usage') ?? 300.0;
    final usagePercent = (metrics.monthlyTotalKwh / expectedUsage) * 100;
    
    if (usagePercent >= 100) {
      if (await tracker.shouldNotifyPower(100)) {
        notifier.showNotification("⚡ Energy Usage Alert", "Your power consumption has reached 100% of your expected usage.", type: 'power');
      }
    } else if (usagePercent >= 75) {
      if (await tracker.shouldNotifyPower(75)) {
        notifier.showNotification("⚡ Energy Usage Alert", "Your power consumption has reached 75% of your expected usage.", type: 'power');
      }
    } else if (usagePercent >= 50) {
      if (await tracker.shouldNotifyPower(50)) {
        notifier.showNotification("⚡ Energy Usage Alert", "Your power consumption has reached 50% of your expected usage.", type: 'power');
      }
    }

    // 3. Slab Change Alert
    final currentUnits = metrics.monthlyTotalKwh;
    String currentSlab = "Slab 1";
    if (currentUnits > 250) {
      currentSlab = "Slab 6";
    } else if (currentUnits > 200) currentSlab = "Slab 5";
    else if (currentUnits > 150) currentSlab = "Slab 4";
    else if (currentUnits > 100) currentSlab = "Slab 3";
    else if (currentUnits > 50) currentSlab = "Slab 2";

    if (await tracker.shouldNotifySlabChange(currentSlab)) {
      notifier.showNotification("⚡ Electricity Slab Changed", "Your electricity usage has entered a new billing slab ($currentSlab).", type: 'slab');
    }

    // 4. Peak Hour Warning (6 PM - 10 PM)
    final now = DateTime.now();
    if (now.hour >= 18 && now.hour < 22) {
      if (await tracker.shouldNotifyPeakHour()) {
        notifier.showNotification("⚡ Peak Hour Warning", "Electricity demand is currently at peak levels. Try to reduce heavy appliance usage.", type: 'peak');
      }
    }
  }

  EnergyMetrics? get energyMetrics {
    if (_liveData == null && _historicalLogs.isEmpty) return null;

    final monthEnergyMap = getMonthTotalEnergy(_deltas);

    // Use the live cumulative energy counters from Firebase as the primary source
    // of truth for "Total Units This Month". These are the actual ESP32 accumulators
    // and are always accurate — unlike the delta-computed sum which can miss data
    // due to the 500-log fetch limit and counter resets.
    double liveBedroomEnergy = _liveData?.energy['bedroom'] ?? 0.0;
    double liveKitchenEnergy = _liveData?.energy['kitchen'] ?? 0.0;
    double liveLivingRoomEnergy = _liveData?.energy['livingRoom'] ?? 0.0;
    double liveTotalEnergy = liveBedroomEnergy + liveKitchenEnergy + liveLivingRoomEnergy;

    // Fallback: if live data isn't yet available, use delta-based total
    final currentMonthUnits = liveTotalEnergy > 0 ? liveTotalEnergy : (monthEnergyMap['total'] ?? 0.0);
    
    double todayUnits = 0;
    double yesterdayUnits = 0;
    
    if (_daily.isNotEmpty) {
       todayUnits = _daily.last.total;
       if (_daily.length > 1) {
          yesterdayUnits = _daily[_daily.length - 2].total;
       }
    }

    final daysPassed = DateTime.now().day > 0 ? DateTime.now().day : 1;
    final dailyAvg = currentMonthUnits / daysPassed;

    // Firebase stores power in kW units directly (e.g. 1.2 means 1.2 kW)
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
    final estimatedUnits = dailyAvg * totalDays;

    // Calculate monthly top room using live energy counters
    List<Map<String, dynamic>> roomTotals = [
      {"name": "Bedroom", "val": liveBedroomEnergy > 0 ? liveBedroomEnergy : (monthEnergyMap['bedroom'] ?? 0.0)},
      {"name": "Living Room", "val": liveLivingRoomEnergy > 0 ? liveLivingRoomEnergy : (monthEnergyMap['livingRoom'] ?? 0.0)},
      {"name": "Kitchen", "val": liveKitchenEnergy > 0 ? liveKitchenEnergy : (monthEnergyMap['kitchen'] ?? 0.0)},
    ];
    roomTotals.sort((a, b) => (b["val"] as double).compareTo(a["val"] as double));
    final monthlyTopRoom = roomTotals[0]["name"] as String;

    return EnergyMetrics(
      // Firebase power values are already in kW — store as-is (no /1000 needed)
      currentPowerKw: (lastPower['total'] as num).toDouble(),
      todayUsageKwh: todayUnits,
      yesterdayUsageKwh: yesterdayUnits,
      weeklyAverageKwh: dailyAvg * 7,
      monthlyTotalKwh: currentMonthUnits,
      lastMonthTotalKwh: currentMonthUnits * 0.9,
      dailyAverageKwh: dailyAvg,
      peakTime: peak?.hour ?? "",
      peakRoom: monthlyTopRoom,
      peakDay: peakDay,
      estimatedMonthlyUnits: estimatedUnits,
      tariff: _tariffData,
      rooms: RoomMetrics(
        bedroomPowerW: (lastPower['bedroom'] as num).toDouble(),
        kitchenPowerW: (lastPower['kitchen'] as num).toDouble(),
        livingRoomPowerW: (lastPower['livingRoom'] as num).toDouble(),
      ),
      weeklyBuckets: _weekly,
      monthlyBuckets: _monthly,
      dailyBuckets: _hourlyLive,
      roomMonthlyEnergy: {
        'Bedroom': liveBedroomEnergy > 0 ? liveBedroomEnergy : (monthEnergyMap['bedroom'] ?? 0.0),
        'Living Room': liveLivingRoomEnergy > 0 ? liveLivingRoomEnergy : (monthEnergyMap['livingRoom'] ?? 0.0),
        'Kitchen': liveKitchenEnergy > 0 ? liveKitchenEnergy : (monthEnergyMap['kitchen'] ?? 0.0),
      },
    );
  }

  Future<void> toggleRoom(String roomKey, bool isOn) async {
    print("EnergyDataProvider: Toggling room $roomKey to $isOn");
    // HomeSimulation will listen to this change and update all internal device switches
    try {
      await _firebaseService.updateRoomStatus(roomKey, isOn);
    } catch (e) {
      print("EnergyDataProvider Error: Failed to update room status: $e");
    }
  }

  @override
  void dispose() {
    _liveSubscription?.cancel();
    _controlSubscription?.cancel();
    _roomsSubscription?.cancel();
    super.dispose();
  }
}

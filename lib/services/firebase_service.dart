import 'package:firebase_database/firebase_database.dart';
import 'billing_calculator.dart';
import 'auth_service.dart';

class EnergyLog {
  String timestamp;
  Map<String, double> power;
  Map<String, double> energy;
  Map<String, bool> switches;

  EnergyLog({required this.timestamp, required this.power, required this.energy, required this.switches});

  factory EnergyLog.fromJson(Map<dynamic, dynamic> json, String key) {
    String ts = json['timestamp'] ?? key;
    if (json['timestamp'] == null && key.contains('_')) {
      final parts = key.split('_');
      if (parts.length == 2) {
        ts = "${parts[0]} ${parts[1].replaceAll('-', ':')}";
      }
    }
    
    return EnergyLog(
      timestamp: ts,
      power: {
        'bedroom': (json['power']?['bedroom'] ?? 0).toDouble(),
        'livingRoom': (json['power']?['livingRoom'] ?? 0).toDouble(),
        'kitchen': (json['power']?['kitchen'] ?? 0).toDouble(),
        'total': (json['power']?['total'] ?? 0).toDouble(),
      },
      energy: {
        'bedroom': (json['energy']?['bedroom'] ?? 0).toDouble(),
        'livingRoom': (json['energy']?['livingRoom'] ?? 0).toDouble(),
        'kitchen': (json['energy']?['kitchen'] ?? 0).toDouble(),
      },
      switches: {
        'bedroom': (json['state']?['bedroom'] ?? json['switches']?['bedroom'] ?? json['bedroom']) ?? false,
        'lrLight': (json['state']?['living'] ?? json['switches']?['lrLight'] ?? json['lrLight']) ?? false,
        'lrTV': (json['state']?['living'] ?? json['switches']?['lrTV'] ?? json['lrTV']) ?? false,
        'kitchen': (json['state']?['kitchen'] ?? json['switches']?['kitchen'] ?? json['kitchen']) ?? false,
      },
    );
  }
}

/// Represents a real-time snapshot from users/{userId}/water/live
/// Matches the homesimulation WaterTankPayload structure.
class WaterLiveData {
  final String timestamp;
  final double tankLevel;   // Liters remaining in tank
  final double flowRate;    // Liters per minute (in/out)
  final bool motorStatus;   // true = motor ON (refilling)
  final bool outletOn;      // true = outlet is draining

  const WaterLiveData({
    required this.timestamp,
    required this.tankLevel,
    required this.flowRate,
    required this.motorStatus,
    required this.outletOn,
  });

  factory WaterLiveData.fromJson(Map<dynamic, dynamic> json, String key) {
    final ts = json['timestamp']?.toString() ?? key;
    // Support both old (waterLevel) and new (tankLevel) field names
    final level = (json['tankLevel'] ?? json['waterLevel'] ?? 1000).toDouble();
    final flow  = (json['flowRate'] ?? 0).toDouble();
    final motor = (json['motorStatus'] ?? json['refillOn'] ?? false) as bool;
    final outlet = (json['outletOn'] ?? false) as bool;
    return WaterLiveData(
      timestamp: ts,
      tankLevel: level,
      flowRate: flow,
      motorStatus: motor,
      outletOn: outlet,
    );
  }
}

class FirebaseService {
  static final FirebaseService instance = FirebaseService._internal();
  factory FirebaseService() => instance;
  FirebaseService._internal();

  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  
  String get _userId {
    final uid = AuthService.instance.currentUser;
    if (uid == null || uid.isEmpty || uid == 'undefined' || uid == 'null') {
      throw Exception("Invalid User ID. Cannot access database.");
    }
    return uid;
  }

  DatabaseReference get _userEnergyRef {
    return _dbRef.child('users').child(_userId).child('energy');
  }

  DatabaseReference get _userWaterRef {
    return _dbRef.child('users').child(_userId).child('water');
  }

  DatabaseReference get _userRoomsRef {
    return _dbRef.child('users').child(_userId).child('rooms');
  }
  
  Future<void> writeUserData(String pathSegment, dynamic data) async {
    try {
      final uid = _userId; // throws if invalid
      await _userEnergyRef.child(pathSegment).set(data);
    } catch (e) {
      print("Blocked invalid Firebase write: $e");
    }
  }

  Stream<EnergyLog?> getLiveStream() {
    return _userEnergyRef.child('live').onValue.map((event) {
      if (event.snapshot.value == null) return null;
      return EnergyLog.fromJson(event.snapshot.value as Map<dynamic, dynamic>, 'live');
    });
  }

  Stream<Map<String, dynamic>> getRoomsStream() {
    return _userRoomsRef.onValue.map((event) {
      if (event.snapshot.value == null) return {};
      return Map<String, dynamic>.from(event.snapshot.value as Map);
    });
  }

  Future<void> updateRoomStatus(String roomId, bool status) async {
    try {
      await _userRoomsRef.child(roomId).update({
        'status': status,
      });
    } catch (e) {
      print('FirebaseService: Failed to update room status: $e');
    }
  }

  Stream<WaterLiveData?> getWaterLiveStream() {
    return _userWaterRef.child('live').onValue.map((event) {
      if (event.snapshot.value == null) return null;
      try {
        return WaterLiveData.fromJson(
          event.snapshot.value as Map<dynamic, dynamic>, 'live');
      } catch (e) {
        print('WaterLiveData parse error: $e');
        return null;
      }
    });
  }

  Stream<Map<String, bool>> getControlStream() {
    return _userEnergyRef.child('control').onValue.map((event) {
      if (event.snapshot.value == null) return {};
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      return {
        'bedroom': data['bedroom'] ?? false,
        'lrLight': data['lrLight'] ?? false,
        'lrTV': data['lrTV'] ?? false,
        'kitchen': data['kitchen'] ?? false,
      };
    });
  }

  Future<List<EnergyLog>> fetchLogs() async {
    final snapshot = await _userEnergyRef.child('logs').orderByKey().limitToLast(5000).get();
    if (!snapshot.exists) return [];
    
    final data = snapshot.value as Map<dynamic, dynamic>;
    final logs = data.entries.map((e) => EnergyLog.fromJson(e.value as Map<dynamic, dynamic>, e.key as String)).toList();
    
    logs.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return logs;
  }

  /// Fetch water logs as WaterLiveData objects (structured water format)
  Future<List<WaterLiveData>> fetchWaterDataLogs() async {
    final snapshot = await _userWaterRef.child('logs').orderByKey().limitToLast(2000).get();
    if (!snapshot.exists) return [];
    
    final data = snapshot.value as Map<dynamic, dynamic>;
    final logs = <WaterLiveData>[];
    for (final entry in data.entries) {
      try {
        logs.add(WaterLiveData.fromJson(entry.value as Map<dynamic, dynamic>, entry.key as String));
      } catch (_) {}
    }
    logs.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return logs;
  }

  /// Legacy — kept for backward compat with old water data format
  Future<List<EnergyLog>> fetchWaterLogs() async {
    final snapshot = await _userWaterRef.child('logs').orderByKey().limitToLast(5000).get();
    if (!snapshot.exists) return [];
    
    final data = snapshot.value as Map<dynamic, dynamic>;
    final logs = data.entries.map((e) => EnergyLog.fromJson(e.value as Map<dynamic, dynamic>, e.key as String)).toList();
    
    logs.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return logs;
  }

  /// Push motor state to Firebase water/control node
  Future<void> updateWaterMotorState(bool isOn) async {
    try {
      final uid = _userId;
      await _dbRef.child('users').child(uid).child('water').child('control').update({
        'motorStatus': isOn,
        'refillOn': isOn,
      });
    } catch (e) {
      print('FirebaseService: Failed to update water motor: $e');
    }
  }
  
  Future<TariffSlabs> fetchSettings() async {
    final snapshot = await _userEnergyRef.child('settings').get();
    if (!snapshot.exists) return defaultTariff;
    final data = snapshot.value as Map<dynamic, dynamic>;
    if (data['tariff'] != null) {
      return TariffSlabs.fromJson(data['tariff']);
    }
    return defaultTariff;
  }

  Future<void> updateControlState(String roomKey, bool value) async {
    try {
      print("FirebaseService: Setting control/$roomKey to $value");
      await writeUserData('control/$roomKey', value);
      print("FirebaseService: Successfully updated control/$roomKey");
    } catch (e) {
      print("FirebaseService Error: Failed to update control/$roomKey: $e");
    }
  }

  Future<void> updateMultipleStates(Map<String, bool> updates) async {
    try {
       print("FirebaseService: Updating multiple control states: $updates");
       // _userEnergyRef doesn't have an update wrapper in writeUserData, so do it manually after validation
       final uid = _userId; 
       await _userEnergyRef.child('control').update(updates);
       print("FirebaseService: Successfully updated multiple control states");
    } catch (e) {
       print("FirebaseService Error: Failed to update multiple control states: $e");
    }
  }
}

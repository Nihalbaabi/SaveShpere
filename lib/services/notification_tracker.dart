import 'package:shared_preferences/shared_preferences.dart';

class NotificationTracker {
  static final NotificationTracker _instance = NotificationTracker._internal();
  factory NotificationTracker() => _instance;
  NotificationTracker._internal();

  static const String _keyBudget50 = 'budget_50_sent';
  static const String _keyBudget75 = 'budget_75_sent';
  static const String _keyBudget100 = 'budget_100_sent';
  static const String _keyPower50 = 'power_50_sent';
  static const String _keyPower75 = 'power_75_sent';
  static const String _keyPower100 = 'power_100_sent';
  static const String _keyPeakHour = 'peak_hour_sent';
  static const String _keyLastSlab = 'last_known_slab';
  static const String _keyLastResetDate = 'last_reset_date';

  Future<void> _checkAndResetMonthly() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final lastReset = prefs.getString(_keyLastResetDate);
    
    if (lastReset == null || _isNewMonth(lastReset)) {
      await prefs.setBool(_keyBudget50, false);
      await prefs.setBool(_keyBudget75, false);
      await prefs.setBool(_keyBudget100, false);
      await prefs.setBool(_keyPower50, false);
      await prefs.setBool(_keyPower75, false);
      await prefs.setBool(_keyPower100, false);
      await prefs.setString(_keyLastResetDate, now.toIso8601String());
    }
  }

  Future<void> _checkAndResetDaily() async {
     final prefs = await SharedPreferences.getInstance();
     final now = DateTime.now();
     final lastReset = prefs.getString('last_daily_reset_date');
     
     if (lastReset == null || _isNewDay(lastReset)) {
        await prefs.setBool(_keyPeakHour, false);
        await prefs.setString('last_daily_reset_date', now.toIso8601String());
     }
  }

  bool _isNewMonth(String dateIso) {
    final date = DateTime.parse(dateIso);
    final now = DateTime.now();
    return date.month != now.month || date.year != now.year;
  }

  bool _isNewDay(String dateIso) {
    final date = DateTime.parse(dateIso);
    final now = DateTime.now();
    return date.day != now.day || date.month != now.month || date.year != now.year;
  }

  Future<bool> shouldNotifyBudget(int percentage) async {
    await _checkAndResetMonthly();
    final prefs = await SharedPreferences.getInstance();
    String key = '';
    if (percentage == 50) key = _keyBudget50;
    else if (percentage == 75) key = _keyBudget75;
    else if (percentage == 100) key = _keyBudget100;
    
    if (key.isEmpty) return false;
    bool alreadySent = prefs.getBool(key) ?? false;
    if (!alreadySent) {
      await prefs.setBool(key, true);
      return true;
    }
    return false;
  }

  Future<bool> shouldNotifyPower(int percentage) async {
    await _checkAndResetMonthly();
    final prefs = await SharedPreferences.getInstance();
    String key = '';
    if (percentage == 50) key = _keyPower50;
    else if (percentage == 75) key = _keyPower75;
    else if (percentage == 100) key = _keyPower100;
    
    if (key.isEmpty) return false;
    bool alreadySent = prefs.getBool(key) ?? false;
    if (!alreadySent) {
      await prefs.setBool(key, true);
      return true;
    }
    return false;
  }

  Future<bool> shouldNotifyPeakHour() async {
    await _checkAndResetDaily();
    final prefs = await SharedPreferences.getInstance();
    bool alreadySent = prefs.getBool(_keyPeakHour) ?? false;
    if (!alreadySent) {
      await prefs.setBool(_keyPeakHour, true);
      return true;
    }
    return false;
  }

  Future<bool> shouldNotifySlabChange(String currentSlab) async {
    final prefs = await SharedPreferences.getInstance();
    String? lastSlab = prefs.getString(_keyLastSlab);
    if (lastSlab == null || lastSlab != currentSlab) {
      await prefs.setString(_keyLastSlab, currentSlab);
      return lastSlab != null; // Only notify if it's a real change, not first time init
    }
    return false;
  }

  /// Throttle water-low alerts to once every 30 minutes
  Future<bool> shouldNotifyWaterLow() async {
    final prefs = await SharedPreferences.getInstance();
    const key = 'water_low_last_sent';
    final lastSentIso = prefs.getString(key);
    if (lastSentIso != null) {
      final lastSent = DateTime.tryParse(lastSentIso);
      if (lastSent != null &&
          DateTime.now().difference(lastSent).inMinutes < 30) {
        return false; // too soon
      }
    }
    await prefs.setString(key, DateTime.now().toIso8601String());
    return true;
  }
}

import '../utils/mock_data.dart'; // For DeltaLog

List<DeltaLog> getJanFebMockWaterDeltas() {
  List<DeltaLog> mockDeltas = [];

  final now = DateTime.now();
  final year = 2026;
  final months = [1, 2, 3]; // Jan, Feb, Mar

  // Deterministic random to ensure consistency
  double seed = 987654321.0;
  double random() {
    seed = (seed * 9301.0 + 49297.0) % 233280.0;
    return seed / 233280.0;
  }

  for (int month in months) {
    int daysInMonth = (month == 2) ? 28 : 31;
    for (int day = 1; day <= daysInMonth; day++) {
      if (month == now.month && day > now.day) break;

      String dateStr = "$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";

      // Realistic daily total water usage (Liters): ~200 to 400 Liters
      double dailyTotalTarget = 200.0 + random() * 200.0;

      for (int hour = 0; hour < 24; hour++) {
        double hourFactor = 0.2; // Base flow (leaks/night)

        if (hour >= 6 && hour <= 9) hourFactor = 2.5; // Morning peak (showers)
        if (hour >= 18 && hour <= 21) hourFactor = 1.5; // Evening peak (cooking/dishes)

        hourFactor *= (0.8 + random() * 0.4);

        double deltaTotal = (dailyTotalTarget / 24.0) * hourFactor;

        // Kitchen usually uses more water than bedroom(bathroom attached) or livingroom
        double kitchenP = 0.50 + random() * 0.1;
        double bedroomP = 0.35 + random() * 0.1;
        double livingRoomP = 1.0 - kitchenP - bedroomP;

        double deltaKitchen = deltaTotal * kitchenP;
        double deltaBedroom = deltaTotal * bedroomP;
        double deltaLivingRoom = deltaTotal * livingRoomP;

        // Dummy flow rate snapshot for the hour based on the delta 
        // L/h to L/min approx
        double flowRateTot = deltaTotal / 60.0; 

        String timestamp = "$dateStr ${hour.toString().padLeft(2, '0')}:30:00";

        mockDeltas.add(DeltaLog(
          timestamp: timestamp,
          date: dateStr,
          hour: hour,
          deltaBedroom: deltaBedroom,
          deltaLivingRoom: deltaLivingRoom,
          deltaKitchen: deltaKitchen,
          deltaTotal: deltaTotal,
          power: {
            'bedroom': flowRateTot * bedroomP,
            'livingRoom': flowRateTot * livingRoomP,
            'kitchen': flowRateTot * kitchenP,
            'total': flowRateTot,
          },
        ));
      }
    }
  }

  return mockDeltas;
}

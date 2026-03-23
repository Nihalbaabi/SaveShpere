List<DeltaLog> getJanFebMockDeltas() {
  List<DeltaLog> mockDeltas = [];

  final now = DateTime.now();
  final year = 2026;
  final months = [1, 2, 3]; // Jan, Feb, Mar

  // Deterministic random to ensure consistency
  double seed = 123456789.0;
  double random() {
    seed = (seed * 9301.0 + 49297.0) % 233280.0;
    return seed / 233280.0;
  }

  for (int month in months) {
    int daysInMonth = (month == 2) ? 28 : 31;
    for (int day = 1; day <= daysInMonth; day++) {
      // If current month, only add mock data up to yesterday
      if (month == now.month && day >= now.day) break;

      String dateStr = "$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";

      // Distribute a realistic daily total (~5 to 10 units) across hours
      double dailyTotalTarget = 5.0 + random() * 5.0;

      // Realistic hourly distribution
      for (int hour = 0; hour < 24; hour++) {
        double hourFactor = 0.5; // Base load (night)

        if (hour >= 6 && hour <= 9) hourFactor = 1.5; // Morning peak
        if (hour >= 18 && hour <= 22) hourFactor = 2.5; // Evening peak

        // Minor variation
        hourFactor *= (0.8 + random() * 0.4);

        // Calculate delta for this hour
        double deltaTotal = (dailyTotalTarget / 24.0) * hourFactor;

        // Split among rooms (Realistic: LivingRoom > Bedroom > Kitchen usually)
        double livingRoomP = 0.45 + random() * 0.1;
        double bedroomP = 0.35 + random() * 0.1;
        double kitchenP = 1.0 - livingRoomP - bedroomP;

        double deltaLivingRoom = deltaTotal * livingRoomP;
        double deltaBedroom = deltaTotal * bedroomP;
        double deltaKitchen = deltaTotal * kitchenP;

        // Dummy power snapshot for the hour based on the delta 
        // (1 hour * x units = x kW = 1000 * x Watts)
        double wattsTot = deltaTotal * 1000.0;

        String timestamp = "\$dateStr \${hour.toString().padLeft(2, '0')}:30:00";

        mockDeltas.add(DeltaLog(
          timestamp: timestamp,
          date: dateStr,
          hour: hour,
          deltaBedroom: deltaBedroom,
          deltaLivingRoom: deltaLivingRoom,
          deltaKitchen: deltaKitchen,
          deltaTotal: deltaTotal,
          power: {
            'bedroom': wattsTot * bedroomP,
            'livingRoom': wattsTot * livingRoomP,
            'kitchen': wattsTot * kitchenP,
            'total': wattsTot,
          },
        ));
      }
    }
  }

  return mockDeltas;
}

class DeltaLog {
  final String timestamp;
  final String date;
  final int hour;
  final double deltaBedroom;
  final double deltaLivingRoom;
  final double deltaKitchen;
  final double deltaTotal;
  final Map<String, dynamic> power;

  DeltaLog({
    required this.timestamp,
    required this.date,
    required this.hour,
    required this.deltaBedroom,
    required this.deltaLivingRoom,
    required this.deltaKitchen,
    required this.deltaTotal,
    required this.power,
  });
}

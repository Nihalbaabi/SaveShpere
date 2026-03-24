class TariffSlabs {
  final double slab1;
  final double slab2;
  final double slab3;
  final double slab4;
  final double slab5;
  final double slab6;
  final double fixedCharge;
  final double dutyPercent;
  final double surcharge;

  TariffSlabs({
    required this.slab1,
    required this.slab2,
    required this.slab3,
    required this.slab4,
    required this.slab5,
    required this.slab6,
    required this.fixedCharge,
    required this.dutyPercent,
    required this.surcharge,
  });

  factory TariffSlabs.fromJson(Map<dynamic, dynamic> json) {
    return TariffSlabs(
      slab1: (json['slab1'] ?? 3.30).toDouble(),
      slab2: (json['slab2'] ?? 4.20).toDouble(),
      slab3: (json['slab3'] ?? 4.85).toDouble(),
      slab4: (json['slab4'] ?? 6.50).toDouble(),
      slab5: (json['slab5'] ?? 7.60).toDouble(),
      slab6: (json['slab6'] ?? 8.70).toDouble(),
      fixedCharge: (json['fixedCharge'] ?? 25.0).toDouble(),
      dutyPercent: (json['dutyPercent'] ?? 15.0).toDouble(),
      surcharge: (json['surcharge'] ?? 0.10).toDouble(),
    );
  }
}

final TariffSlabs defaultTariff = TariffSlabs(
  slab1: 3.30,
  slab2: 4.20,
  slab3: 4.85,
  slab4: 6.50,
  slab5: 7.60,
  slab6: 8.70,
  fixedCharge: 25.0,
  dutyPercent: 15.0,
  surcharge: 0.10,
);

double calculateSlabBill(double units, {dynamic tariff}) {
  final t = (tariff is TariffSlabs) ? tariff : defaultTariff;
  double bill = 0;
  double remaining = units;

  final slabs = [
    {'limit': 50.0, 'rate': t.slab1},
    {'limit': 50.0, 'rate': t.slab2},
    {'limit': 50.0, 'rate': t.slab3},
    {'limit': 50.0, 'rate': t.slab4},
    {'limit': 50.0, 'rate': t.slab5},
    {'limit': double.infinity, 'rate': t.slab6},
  ];

  for (final slab in slabs) {
    if (remaining <= 0) break;
    double consumed = (remaining < slab['limit']!) ? remaining : slab['limit']!;
    bill += consumed * slab['rate']!;
    remaining -= consumed;
  }

  bill += t.fixedCharge;
  bill += bill * (t.dutyPercent / 100);
  bill += units * t.surcharge;

  return (bill * 100).round() / 100;
}

Map<String, double> getBillBreakdown(double units, {dynamic tariff}) {
  final t = (tariff is TariffSlabs) ? tariff : defaultTariff;
  double energyCharges = 0;
  double remaining = units;

  final slabs = [
    {'limit': 50.0, 'rate': t.slab1},
    {'limit': 50.0, 'rate': t.slab2},
    {'limit': 50.0, 'rate': t.slab3},
    {'limit': 50.0, 'rate': t.slab4},
    {'limit': 50.0, 'rate': t.slab5},
    {'limit': double.infinity, 'rate': t.slab6},
  ];

  for (final slab in slabs) {
    if (remaining <= 0) break;
    double consumed = (remaining < slab['limit']!) ? remaining : slab['limit']!;
    energyCharges += consumed * slab['rate']!;
    remaining -= consumed;
  }

  double fixedCharges = t.fixedCharge;
  double duty = (energyCharges + fixedCharges) * (t.dutyPercent / 100);
  double surcharge = units * t.surcharge;
  double total = energyCharges + fixedCharges + duty + surcharge;

  return {
    'energyCharges': (energyCharges * 100).round() / 100,
    'fixedCharges': (fixedCharges * 100).round() / 100,
    'duty': (duty * 100).round() / 100,
    'surcharge': (surcharge * 100).round() / 100,
    'total': (total * 100).round() / 100,
  };
}

class BillPrediction {
  final double predictedUnits;
  final double predictedBill;
  final double dailyAvg;

  BillPrediction(this.predictedUnits, this.predictedBill, this.dailyAvg);
}

BillPrediction predictMonthlyBill(double currentUnits, int daysPassed, int totalDaysInMonth, {dynamic tariff}) {
  double dailyAvg = daysPassed > 0 ? currentUnits / daysPassed : 0;
  double predictedUnits = (dailyAvg * totalDaysInMonth * 100).round() / 100;
  double predictedBill = calculateSlabBill(predictedUnits, tariff: tariff);
  return BillPrediction(predictedUnits, predictedBill, (dailyAvg * 100).round() / 100);
}

int getDaysInMonth(int year, int month) {
  return DateTime(year, month + 1, 0).day;
}

class WaterTariff {
  final double s1; // 0-5 KL
  final double s2; // 5-10 KL
  final double s3; // 10-15 KL
  final double s4; // 15-20 KL
  final double s5; // 20-25 KL
  final double s6; // 25-30 KL
  final double s7; // 30-40 KL
  final double s8; // 40-50 KL
  final double s9; // >50 KL
  final double minCharge;

  WaterTariff({
    required this.s1, required this.s2, required this.s3,
    required this.s4, required this.s5, required this.s6,
    required this.s7, required this.s8, required this.s9,
    required this.minCharge,
  });
}

final WaterTariff defaultWaterTariff = WaterTariff(
  s1: 14.41, s2: 14.41, s3: 15.51, s4: 16.62,
  s5: 17.72, s6: 19.92, s7: 23.23, s8: 25.44, s9: 54.10,
  minCharge: 72.05,
);

/// Kerala Water Authority (KWA) Tariff logic
double calculateWaterBill(double liters, {dynamic tariff}) {
  final t = (tariff is WaterTariff) ? tariff : defaultWaterTariff;
  double kl = liters / 1000.0;
  double bill = 0.0;

  if (kl <= 5) {
    bill = kl * t.s1;
    if (bill < t.minCharge) bill = t.minCharge;
  } else if (kl <= 10) {
    bill = t.minCharge + ((kl - 5) * t.s2);
  } else if (kl <= 15) {
    double base = t.minCharge + (5 * t.s2);
    bill = base + ((kl - 10) * t.s3);
  } else if (kl <= 20) {
    bill = kl * t.s4;
  } else if (kl <= 25) {
    bill = kl * t.s5;
  } else if (kl <= 30) {
    bill = kl * t.s6;
  } else if (kl <= 40) {
    bill = kl * t.s7;
  } else if (kl <= 50) {
    bill = kl * t.s8;
  } else {
    bill = (50 * t.s8) + ((kl - 50) * t.s9);
  }

  return (bill * 100).round() / 100;
}

BillPrediction predictWaterBill(double currentLiters, int daysPassed, int totalDaysInMonth, {dynamic tariff}) {
  double dailyAvg = daysPassed > 0 ? currentLiters / daysPassed : 0;
  double predictedLiters = (dailyAvg * totalDaysInMonth * 100).round() / 100;
  double predictedBill = calculateWaterBill(predictedLiters, tariff: tariff);
  return BillPrediction(predictedLiters, predictedBill, (dailyAvg * 100).round() / 100);
}

Map<String, double> getWaterBillBreakdown(double liters, {dynamic tariff}) {
  double bill = calculateWaterBill(liters, tariff: tariff);
  return {
    'waterCharges': bill,
    'fixedCharges': 0.0,
    'duty': 0.0,
    'surcharge': 0.0,
    'total': bill,
  };
}

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/billing_calculator.dart';
import '../theme/app_theme.dart';

class BillCard extends StatelessWidget {
  final double currentUnits;
  final TariffSlabs tariff;
  final bool compact;
  final bool isWater;

  const BillCard({
    Key? key,
    required this.currentUnits,
    required this.tariff,
    this.compact = false,
    this.isWater = false,
  }) : super(key: key);

  Map<String, dynamic> _getCurrentSlab(double units) {
    if (units <= 50) return {'slabNumber': 1, 'rate': 3.30};
    if (units <= 100) return {'slabNumber': 2, 'rate': 4.20};
    if (units <= 150) return {'slabNumber': 3, 'rate': 4.85};
    if (units <= 200) return {'slabNumber': 4, 'rate': 6.50};
    if (units <= 250) return {'slabNumber': 5, 'rate': 7.60};
    return {'slabNumber': 6, 'rate': 8.70};
  }

  Map<String, dynamic> _getWaterSlab(double liters) {
    double kl = liters / 1000.0;
    if (kl <= 5) return {'slabNumber': '1 (0-5 KL)', 'rate': '14.41/KL'};
    if (kl <= 10) return {'slabNumber': '2 (5-10 KL)', 'rate': '14.41/KL'};
    if (kl <= 15) return {'slabNumber': '3 (10-15 KL)', 'rate': '15.51/KL'};
    if (kl <= 20) return {'slabNumber': '4 (15-20 KL)', 'rate': '16.62 flat'};
    if (kl <= 25) return {'slabNumber': '5 (20-25 KL)', 'rate': '17.72 flat'};
    if (kl <= 30) return {'slabNumber': '6 (25-30 KL)', 'rate': '19.92 flat'};
    if (kl <= 40) return {'slabNumber': '7 (30-40 KL)', 'rate': '23.23 flat'};
    if (kl <= 50) return {'slabNumber': '8 (40-50 KL)', 'rate': '25.44 flat'};
    return {'slabNumber': '9 (>50 KL)', 'rate': '54.10/KL'};
  }

  @override
  Widget build(BuildContext context) {
    final currentBill = isWater 
        ? calculateWaterBill(currentUnits) 
        : calculateSlabBill(currentUnits, tariff: tariff);
    final slab = isWater 
        ? _getWaterSlab(currentUnits) 
        : _getCurrentSlab(currentUnits);
    final appColors = context.appColors;

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '₹${currentBill.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              fontFamily: 'JetBrains Mono',
              color: isWater ? Colors.lightBlue : AppTheme.electricGreen,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: appColors.secondary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Slab ${slab['slabNumber']}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: appColors.mutedForeground,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${currentUnits.toStringAsFixed(1)} ${isWater ? 'Liters' : 'units'}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: appColors.mutedForeground,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: appColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: appColors.border.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(LucideIcons.indianRupee, size: 20, color: Color(0xFFF59E0B)),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    isWater ? 'Estimated Cost' : 'Current Bill',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: appColors.foreground,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: appColors.secondary,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  'Slab ${slab['slabNumber']}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: appColors.mutedForeground,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '₹${currentBill.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'JetBrains Mono',
                  color: isWater ? Colors.lightBlue : AppTheme.electricGreen,
                  letterSpacing: -1.5,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Estimated',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: appColors.mutedForeground.withOpacity(0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: appColors.secondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.activity, size: 14, color: appColors.mutedForeground),
                const SizedBox(width: 8),
                Text(
                  '${currentUnits.toStringAsFixed(2)} total ${isWater ? 'Liters' : 'units'} used this cycle',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: appColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

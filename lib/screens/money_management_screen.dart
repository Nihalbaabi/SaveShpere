import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/energy_provider.dart';
import '../providers/water_provider.dart';
import '../models/water_models.dart';
import '../theme/app_theme.dart';
import '../services/billing_calculator.dart';

class MoneyManagementScreen extends StatefulWidget {
  const MoneyManagementScreen({super.key});

  @override
  State<MoneyManagementScreen> createState() => _MoneyManagementScreenState();
}

class _MoneyManagementScreenState extends State<MoneyManagementScreen> {
  final TextEditingController _budgetController = TextEditingController();
  double _activeBudget = 0.0;
  bool _savingBudget = false;
  bool _isWaterMode = false;

  @override
  void initState() {
    super.initState();
    _loadBudget();
  }

  Future<void> _loadBudget() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _activeBudget = prefs.getDouble('monthly_budget') ?? 0.0;
    });
  }

  Future<void> _handleSaveBudget(double currentBill) async {
    final text = _budgetController.text;
    final val = double.tryParse(text);
    if (val == null || val <= 0) return;

    setState(() => _savingBudget = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('monthly_budget', val);

    if (currentBill >= val && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Budget exceeded! Your bill ₹${currentBill.toStringAsFixed(2)} has crossed your budget of ₹${val.toStringAsFixed(2)}.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
    
    setState(() {
      _savingBudget = false;
      _activeBudget = val;
      _budgetController.clear();
    });
  }

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
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  Widget _buildDashboardToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.appColors.card,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: context.appColors.border.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton(
            title: 'Energy',
            icon: LucideIcons.zap,
            isSelected: !_isWaterMode,
            onTap: () => setState(() => _isWaterMode = false),
          ),
          _buildToggleButton(
            title: 'Water',
            icon: LucideIcons.droplets,
            isSelected: _isWaterMode,
            onTap: () => setState(() => _isWaterMode = true),
            isWater: true,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({required String title, required IconData icon, required bool isSelected, required VoidCallback onTap, bool isWater = false}) {
    final activeColor = isWater ? Colors.lightBlue : AppTheme.electricGreen;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isSelected ? activeColor : context.appColors.mutedForeground),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(fontSize: 14, fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, color: isSelected ? activeColor : context.appColors.mutedForeground)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Money Management", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: context.appColors.foreground, letterSpacing: -1.0)),
            const SizedBox(height: 4),
            Text("Track bills, predictions & budget", style: TextStyle(fontSize: 14, color: context.appColors.mutedForeground, fontWeight: FontWeight.w500)),
            const SizedBox(height: 24),
            _buildDashboardToggle(),
            const SizedBox(height: 24),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(opacity: animation, child: SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0.0, 0.05), end: Offset.zero).animate(animation), child: child,
                ));
              },
              child: _isWaterMode ? _buildWaterView(context) : _buildEnergyView(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaterView(BuildContext context) {
    return Consumer<WaterDataProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) return Center(child: CircularProgressIndicator(color: Colors.lightBlue));
        final metrics = provider.waterMetrics;
        if (metrics == null) return Center(child: Text("No data available", style: TextStyle(color: context.appColors.mutedForeground)));

        final now = DateTime.now();
        final daysPassed = now.day;
        final totalDays = getDaysInMonth(now.year, now.month);
        final currentLiters = metrics.monthlyTotalL;
        
        final currentBill = calculateWaterBill(currentLiters);
        final prediction = predictWaterBill(currentLiters, daysPassed, totalDays);
        final slab = _getWaterSlab(currentLiters);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBillAsOfNowCard(context, currentBill, currentLiters, slab, isWater: true),
            const SizedBox(height: 16),
            _buildExpectedBillCard(context, prediction, daysPassed, totalDays, null, isWater: true),
            const SizedBox(height: 80),
          ],
        );
      },
    );
  }

  Widget _buildEnergyView(BuildContext context) {
    return Consumer<EnergyDataProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) return Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor));
        final metrics = provider.energyMetrics;
        if (metrics == null) return Center(child: Text("No data available", style: TextStyle(color: context.appColors.mutedForeground)));

        final now = DateTime.now();
        final daysPassed = now.day;
        final totalDays = getDaysInMonth(now.year, now.month);
        final currentMonthTotal = metrics.monthlyTotalKwh;
        final tariff = metrics.tariff ?? defaultTariff;
        
        final currentBill = calculateSlabBill(currentMonthTotal, tariff: tariff);
        final prediction = predictMonthlyBill(currentMonthTotal, daysPassed, totalDays, tariff: tariff);
        final slab = _getCurrentSlab(currentMonthTotal);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBillAsOfNowCard(context, currentBill, currentMonthTotal, slab),
            const SizedBox(height: 16),
            _buildExpectedBillCard(context, prediction, daysPassed, totalDays, tariff),
            const SizedBox(height: 16),
            _buildBudgetSystemCard(context, currentBill),
            const SizedBox(height: 80),
          ],
        );
      },
    );
  }

  Widget _buildBillAsOfNowCard(BuildContext context, double currentBill, double currentUnits, Map<String, dynamic> slab, {bool isWater = false}) {
    final appColors = context.appColors;
    final primaryColor = isWater ? Colors.lightBlue : AppTheme.electricGreen;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: appColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: appColors.border.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(isWater ? LucideIcons.droplets : LucideIcons.indianRupee, size: 20, color: primaryColor),
              ),
              const SizedBox(width: 14),
              Text(
                isWater ? "Current Water Bill" : "Current Energy Bill",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: appColors.foreground, letterSpacing: -0.5),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            "₹${currentBill.toStringAsFixed(2)}",
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, fontFamily: 'JetBrains Mono', color: appColors.foreground),
          ),
          const SizedBox(height: 8),
          Text(
            isWater 
              ? "${currentUnits.toStringAsFixed(1)} L · Slab ${slab['slabNumber']} (₹${slab['rate']})"
              : "${currentUnits.toStringAsFixed(2)} units · Slab ${slab['slabNumber']} (₹${slab['rate']}/unit)",
            style: TextStyle(fontSize: 13, color: appColors.mutedForeground, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildExpectedBillCard(BuildContext context, BillPrediction prediction, int daysPassed, int totalDays, dynamic tariff, {bool isWater = false}) {
    final appColors = context.appColors;
    final primaryColor = isWater ? Colors.lightBlue : const Color(0xFFF59E0B);
    return GestureDetector(
      onTap: () => _showMonthlyReportModal(context, prediction, tariff, isWater: isWater),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: appColors.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: appColors.border.withOpacity(0.5), width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))
          ]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(LucideIcons.trendingUp, size: 20, color: primaryColor),
                ),
                const SizedBox(width: 14),
                Text(
                  isWater ? "Expected Water Bill" : "Expected Energy Bill",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: appColors.foreground, letterSpacing: -0.5),
                ),
                const Spacer(),
                Icon(LucideIcons.chevronRight, size: 18, color: appColors.mutedForeground.withOpacity(0.5)),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              "₹${prediction.predictedBill.toStringAsFixed(2)}",
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, fontFamily: 'JetBrains Mono', color: primaryColor),
            ),
            const SizedBox(height: 24),
            _buildInfoRow(context, "Predicted Load", isWater ? "${prediction.predictedUnits.toStringAsFixed(1)} L" : "${prediction.predictedUnits.toStringAsFixed(2)} kWh"),
            const SizedBox(height: 12),
            _buildInfoRow(context, "Daily Rhythm", isWater ? "${prediction.dailyAvg.toStringAsFixed(1)} L/day" : "${prediction.dailyAvg.toStringAsFixed(2)} kWh/day"),
            const SizedBox(height: 12),
            _buildInfoRow(context, "Cycle Days Left", "${totalDays - daysPassed} Days"),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: context.appColors.mutedForeground)),
        Text(value, style: TextStyle(fontSize: 12, fontFamily: 'JetBrains Mono', color: Theme.of(context).textTheme.bodyLarge?.color)),
      ],
    );
  }

  void _showMonthlyReportModal(BuildContext context, BillPrediction prediction, dynamic tariff, {bool isWater = false}) {
    final breakdown = isWater 
        ? getWaterBillBreakdown(prediction.predictedUnits, tariff: tariff) 
        : getBillBreakdown(prediction.predictedUnits, tariff: tariff);
    final appColors = context.appColors;
    
    final pieData = isWater ? [
      {'name': 'Water Charges', 'value': breakdown['waterCharges']!, 'color': Colors.lightBlue},
    ] : [
      {'name': 'Energy Charges', 'value': breakdown['energyCharges']!, 'color': const Color(0xFF3B82F6)},
      {'name': 'Fixed Charges', 'value': breakdown['fixedCharges']!, 'color': const Color(0xFFF97316)},
      {'name': 'Electricity Duty', 'value': breakdown['duty']!, 'color': const Color(0xFFEAB308)},
      {'name': 'Fuel Surcharge', 'value': breakdown['surcharge']!, 'color': const Color(0xFFEF4444)},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: appColors.border)),
                ),
                child: Center(
                  child: Text(
                    isWater ? "Monthly Water Report" : "Monthly Energy Report",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text("Predicted Total Bill", style: TextStyle(fontSize: 14, color: appColors.mutedForeground)),
                      const SizedBox(height: 4),
                      Text("₹${prediction.predictedBill.toStringAsFixed(2)}", style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
                      const SizedBox(height: 24),
                      
                      SizedBox(
                        height: 200,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 60,
                            sections: pieData.map((data) {
                              return PieChartSectionData(
                                color: data['color'] as Color,
                                value: data['value'] as double,
                                title: '',
                                radius: 20,
                              );
                            }).toList(),
                          )
                        )
                      ),
                      
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: appColors.secondary.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Smart Bill Breakdown", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color)),
                            const SizedBox(height: 8),
                            const Divider(),
                            const SizedBox(height: 8),
                            ...pieData.map((item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 8, height: 8,
                                            decoration: BoxDecoration(color: item['color'] as Color, shape: BoxShape.circle),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(item['name'] as String, style: TextStyle(fontSize: 14, color: appColors.mutedForeground)),
                                        ],
                                      ),
                                      Text("₹${(item['value'] as double).toStringAsFixed(2)}", style: TextStyle(fontSize: 14, fontFamily: 'JetBrains Mono', color: Theme.of(context).textTheme.bodyLarge?.color)),
                                    ],
                                  ),
                                )).toList()
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: appColors.secondary.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Report Summary", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color)),
                            const SizedBox(height: 8),
                            const Divider(),
                            const SizedBox(height: 8),
                            _buildSummaryRow(context, isWater ? "Total Liters Consumed" : "Total Units Consumed", isWater ? "${prediction.predictedUnits.toStringAsFixed(1)} L" : "${prediction.predictedUnits.toStringAsFixed(2)} kWh"),
                            _buildSummaryRow(context, isWater ? "KWA Slab Status" : "KSEB Slab Status", isWater ? "Slab ${_getWaterSlab(prediction.predictedUnits)['slabNumber']}" : "Slab ${_getCurrentSlab(prediction.predictedUnits)['slabNumber']}"),
                            if (!isWater) _buildSummaryRow(context, "Carbon Estimate", "${(prediction.predictedUnits * 0.82).toStringAsFixed(2)} kg CO₂"),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Smart Suggestions", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isWater ? Colors.lightBlue : Theme.of(context).primaryColor)),
                          const SizedBox(height: 8),
                          if (!isWater && prediction.predictedUnits > 150)
                            _buildSuggestionItem(context, "Consider running heavy appliances during off-peak hours to drop below the 150-unit slab."),
                          if (!isWater && (breakdown['surcharge'] as double) > 0)
                            _buildSuggestionItem(context, "High base usage is adding fuel surcharges. Optimize AC usage."),
                          if (!isWater)
                            _buildSuggestionItem(context, "Switch to LED bulbs throughout the house to save roughly 10-15% on energy charges."),
                          if (isWater)
                            _buildSuggestionItem(context, "Fixing dripping taps can save up to 15 Liters of water daily."),
                          if (isWater && prediction.predictedUnits > 15000)
                            _buildSuggestionItem(context, "High water usage detected. Consider taking shorter showers and using eco mode on your washing machine."),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: appColors.border)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report download started')));
                        },
                        icon: const Icon(LucideIcons.download, size: 16),
                        label: const Text('Download PDF'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: appColors.border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sharing coming soon...')));
                        },
                        icon: const Icon(LucideIcons.share2, size: 16),
                        label: Text('Share', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        );
      }
    );
  }

  Widget _buildSummaryRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: context.appColors.mutedForeground)),
          Text(value, style: TextStyle(fontSize: 14, fontFamily: 'JetBrains Mono', color: Theme.of(context).textTheme.bodyLarge?.color)),
        ],
      ),
    );
  }

  Widget _buildSuggestionItem(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6.0, right: 8.0),
            child: Container(width: 4, height: 4, decoration: BoxDecoration(color: context.appColors.mutedForeground, shape: BoxShape.circle)),
          ),
          Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: context.appColors.mutedForeground))),
        ],
      ),
    );
  }

  Widget _buildBudgetSystemCard(BuildContext context, double currentBill, {bool isWater = false}) {
    final appColors = context.appColors;
    final primaryColor = isWater ? Colors.lightBlue : const Color(0xFF3B82F6);
    final budgetUsedPercent = _activeBudget > 0 ? (currentBill / _activeBudget).clamp(0.0, 1.0) : 0.0;
    final remaining = _activeBudget > 0 ? (_activeBudget - currentBill).clamp(0.0, double.infinity) : 0.0;
    final exceeded = _activeBudget > 0 && currentBill >= _activeBudget;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: appColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: appColors.border.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(LucideIcons.target, size: 20, color: primaryColor),
                ),
                const SizedBox(width: 14),
                Text(
                  isWater ? "Water Budget Limit" : "Power Budget Limit",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: appColors.foreground, letterSpacing: -0.5),
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (_activeBudget > 0) ...[
            if (exceeded)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error.withOpacity(0.08),
                  border: Border.all(color: Theme.of(context).colorScheme.error.withOpacity(0.2)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.alertTriangle, size: 18, color: Theme.of(context).colorScheme.error),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text("Budget limit exceeded. Consider optimization strategies.", 
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.error)),
                    ),
                  ],
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("₹${currentBill.toStringAsFixed(2)} / ₹${_activeBudget.toStringAsFixed(0)}", 
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'JetBrains Mono', color: appColors.foreground)),
                Text("${(budgetUsedPercent * 100).toStringAsFixed(0)}%", 
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'JetBrains Mono', color: Color(0xFF3B82F6))),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: budgetUsedPercent,
                minHeight: 12,
                backgroundColor: appColors.secondary,
                valueColor: AlwaysStoppedAnimation<Color>(exceeded ? Theme.of(context).colorScheme.error : primaryColor),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Allowance Remaining", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: appColors.mutedForeground)),
                Text("₹${remaining.toStringAsFixed(2)}", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'JetBrains Mono', color: AppTheme.electricGreen)),
              ],
            ),
            const SizedBox(height: 24),
          ] else
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Text("Set a monthly expenditure limit to monitor efficiency.", style: TextStyle(fontSize: 14, color: appColors.mutedForeground, fontWeight: FontWeight.w500)),
            ),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _budgetController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'JetBrains Mono', color: appColors.foreground),
                  decoration: InputDecoration(
                    hintText: _activeBudget > 0 ? "Cur: ₹${_activeBudget.toStringAsFixed(0)}" : "Cap (₹)",
                    hintStyle: TextStyle(fontSize: 14, color: appColors.mutedForeground),
                    filled: true,
                    fillColor: appColors.secondary,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor, width: 2)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _savingBudget ? null : () => _handleSaveBudget(currentBill),
                child: Text(_savingBudget ? "..." : "Set Budget", style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          )
        ],
      ),
    );
  }
}

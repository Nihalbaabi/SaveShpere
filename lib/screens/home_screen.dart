import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/energy_provider.dart';
import '../providers/water_provider.dart';
import '../widgets/stat_card.dart';
import '../widgets/bill_card.dart';
import '../widgets/live_usage_chart.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  final Function(String) onNavigate;

  const HomeScreen({Key? key, required this.onNavigate}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isWaterMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildDashboardToggle(),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, 0.05),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: _isWaterMode 
                ? _buildWaterDashboard(context) 
                : _buildEnergyDashboard(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Dashboard",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _isWaterMode ? "Real-time water monitoring" : "Real-time energy monitoring",
          style: TextStyle(
            fontSize: 14,
            color: context.appColors.mutedForeground,
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.appColors.card,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: context.appColors.border.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _isWaterMode = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_isWaterMode ? AppTheme.electricGreen.withOpacity(0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("⚡", style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text("Energy", style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: !_isWaterMode ? AppTheme.electricGreen : context.appColors.mutedForeground,
                    )),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _isWaterMode = true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _isWaterMode ? Colors.lightBlue.withOpacity(0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("💧", style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text("Water", style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _isWaterMode ? Colors.lightBlue : context.appColors.mutedForeground,
                    )),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnergyDashboard(BuildContext context) {
    return Consumer<EnergyDataProvider>(
      key: const ValueKey('energy'),
      builder: (context, provider, child) {
        if (provider.isLoading) return _buildLoading(AppTheme.electricGreen);
        final metrics = provider.energyMetrics;
        if (metrics == null) return _buildEmpty();

        return Column(
          children: [
            LiveUsageChart(
              data: provider.hourlyLive,
              isWater: false,
              themeColor: AppTheme.electricGreen,
              title: 'Energy Consumption Profile',
              subtitle: 'Real-time total hourly usage',
              unit: 'kW',
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 600) {
                  return Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          title: "Total Units This Month",
                          value: "${metrics.monthlyTotalKwh.toStringAsFixed(1)} kWh",
                          subtitle: "Sum of delta energy",
                          icon: LucideIcons.activity,
                          color: StatColor.teal,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildBillSection(metrics.monthlyTotalKwh, metrics.tariff, false),
                      ),
                    ],
                  );
                }
                return Column(
                  children: [
                    StatCard(
                      title: "Total Units",
                      value: "${metrics.monthlyTotalKwh.toStringAsFixed(1)} kWh",
                      subtitle: "This Month",
                      icon: LucideIcons.activity,
                      color: StatColor.teal,
                    ),
                    const SizedBox(height: 16),
                    _buildBillSection(metrics.monthlyTotalKwh, metrics.tariff, false),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            _buildMonthlyInsights(metrics.peakTime, metrics.peakRoom, false),
            const SizedBox(height: 16),
            _buildLiveUsageSection(
              title: "Real-Time Load",
              subtitle: "Live consumption across all zones",
              totalValue: metrics.currentPowerKw,
              unit: "kW/h",
              themeColor: AppTheme.electricGreen,
              isWater: false,
              rooms: [
                {'name': 'Bedroom', 'icon': LucideIcons.bedDouble, 'value': metrics.rooms.bedroomPowerW, 'color': AppTheme.electricGreen, 'on': provider.liveData?.switches['bedroom'] ?? false},
                {'name': 'Living', 'icon': LucideIcons.sofa, 'value': metrics.rooms.livingRoomPowerW, 'color': AppTheme.neonGreen, 'on': (provider.liveData?.switches['lrLight'] ?? false) || (provider.liveData?.switches['lrTV'] ?? false)},
                {'name': 'Kitchen', 'icon': LucideIcons.utensils, 'value': metrics.rooms.kitchenPowerW, 'color': const Color(0xFF10B981), 'on': provider.liveData?.switches['kitchen'] ?? false},
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildWaterDashboard(BuildContext context) {
    return Consumer<WaterDataProvider>(
      key: const ValueKey('water'),
      builder: (context, provider, child) {
        if (provider.isLoading) return _buildLoading(Colors.lightBlue);
        final metrics = provider.waterMetrics;
        if (metrics == null) return _buildEmpty();

        return Column(
          children: [
            LiveUsageChart(
              data: provider.hourlyLive,
              isWater: true,
              themeColor: Colors.lightBlue,
              title: 'Water Flow Profile',
              subtitle: 'Real-time total hourly usage',
              unit: 'Liters',
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 600) {
                  return Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          title: "Total Water Used",
                          value: "${metrics.monthlyTotalL.toStringAsFixed(1)} Liters",
                          subtitle: "This Month",
                          icon: LucideIcons.droplet,
                          color: StatColor.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Since water isn't fully integrated with the dynamic bill, we just
                      // pass a dummy tariff for the bill estimation, or zero
                      Expanded(
                        child: _buildBillSection(metrics.monthlyTotalL, null, true),
                      ),
                    ],
                  );
                }
                return Column(
                  children: [
                    StatCard(
                      title: "Total Water Used",
                      value: "${metrics.monthlyTotalL.toStringAsFixed(1)} Liters",
                      subtitle: "This Month",
                      icon: LucideIcons.droplet,
                      color: StatColor.blue, // Requires blue styling in StatCard but teal fits for now.
                    ),
                    const SizedBox(height: 16),
                    _buildBillSection(metrics.monthlyTotalL, null, true),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            _buildMonthlyInsights(metrics.peakTime, metrics.peakRoom, true),
            const SizedBox(height: 16),
            _buildLiveUsageSection(
              title: "Current Water Flow",
              subtitle: "Live water usage across all zones",
              totalValue: metrics.currentFlowLpm,
              unit: "LPM",
              themeColor: Colors.lightBlue,
              isWater: true,
              rooms: [
                {'name': 'Bathroom', 'icon': LucideIcons.bath, 'value': metrics.rooms.bedroomFlowLpm, 'color': Colors.lightBlue, 'on': metrics.rooms.bedroomFlowLpm > 0.1},
                {'name': 'Garden', 'icon': LucideIcons.sprout, 'value': metrics.rooms.livingRoomFlowLpm, 'color': Colors.blueAccent, 'on': metrics.rooms.livingRoomFlowLpm > 0.1},
                {'name': 'Kitchen', 'icon': LucideIcons.utensils, 'value': metrics.rooms.kitchenFlowLpm, 'color': Colors.cyan, 'on': metrics.rooms.kitchenFlowLpm > 0.1},
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoading(Color color) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            CircularProgressIndicator(color: color),
            const SizedBox(height: 16),
            Text("Loading data...", style: TextStyle(color: context.appColors.mutedForeground)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Text("No data available", style: TextStyle(color: context.appColors.mutedForeground)),
      ),
    );
  }

  Widget _buildBillSection(double units, dynamic tariff, bool isWater) {
    final appColors = context.appColors;
    return Container(
      decoration: BoxDecoration(
        color: appColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: appColors.border.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isWater ? "Estimated Water Bill" : "Estimated Bill",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: appColors.foreground,
                  letterSpacing: -0.5,
                ),
              ),
              GestureDetector(
                onTap: () => widget.onNavigate('/settings'),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: appColors.secondary, shape: BoxShape.circle),
                  child: Icon(LucideIcons.settings, size: 14, color: appColors.mutedForeground),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          BillCard(
            currentUnits: units,
            tariff: tariff,
            compact: true,
            isWater: isWater,
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyInsights(String peakTime, String peakRoom, bool isWater) {
    final appColors = context.appColors;
    return Container(
      decoration: BoxDecoration(
        color: appColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: appColors.border.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.sparkles, color: const Color(0xFFF59E0B), size: 20),
              const SizedBox(width: 10),
              Text(
                "Daily Insights",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: appColors.foreground,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Peak Usage Hour",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: appColors.mutedForeground),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    peakTime.isNotEmpty ? peakTime : "Analyzing...",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: appColors.foreground),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "High Usage Room",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: appColors.mutedForeground),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    peakRoom.isNotEmpty ? peakRoom : "Analyzing...",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isWater ? Colors.lightBlue : AppTheme.electricGreen),
                  ),
                ],
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildLiveUsageSection({
    required String title,
    required String subtitle,
    required double totalValue,
    required String unit,
    required Color themeColor,
    required bool isWater,
    required List<Map<String, dynamic>> rooms,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: context.appColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.appColors.border.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(isWater ? LucideIcons.droplet : LucideIcons.zap, size: 22, color: themeColor),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: context.appColors.foreground,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: context.appColors.mutedForeground,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                totalValue.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'JetBrains Mono',
                  color: themeColor,
                  letterSpacing: -2,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.appColors.mutedForeground.withOpacity(0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Divider(color: context.appColors.border.withOpacity(0.5), height: 1),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: rooms.map((r) => _buildRoomMetric(
              icon: r['icon'],
              name: r['name'],
              value: r['value'],
              color: r['color'],
              isOn: r['on'],
              themeColor: themeColor,
              unit: isWater ? "L" : "kW",
            )).toList(),
          )
        ],
      ),
    );
  }

  Widget _buildRoomMetric({
    required IconData icon,
    required String name,
    required double value,
    required Color color,
    required bool isOn,
    required Color themeColor,
    required String unit,
  }) {
    final appColors = context.appColors;
    return Column(
      children: [
        Stack(
          alignment: Alignment.topRight,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 22, color: color),
            ),
            if (isOn)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: themeColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: appColors.card, width: 2),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          name,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: appColors.mutedForeground,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "${value.toStringAsFixed(1)} $unit",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFamily: 'JetBrains Mono',
            color: appColors.foreground,
          ),
        ),
      ],
    );
  }
}

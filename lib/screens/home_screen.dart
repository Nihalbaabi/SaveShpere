import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/energy_provider.dart';
import '../providers/water_provider.dart';
import '../models/water_models.dart';
import '../services/billing_calculator.dart';
import '../widgets/stat_card.dart';
import '../widgets/bill_card.dart';
import '../widgets/live_usage_chart.dart';
import '../theme/app_theme.dart';
import '../widgets/smart_assistant.dart';

class HomeScreen extends StatefulWidget {
  final Function(String) onNavigate;

  const HomeScreen({super.key, required this.onNavigate});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isWaterMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          SingleChildScrollView(
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
                const SizedBox(height: 80), // Padding for Floating Action Button
              ],
            ),
          ),
          Positioned(
            bottom: 24,
            right: 24,
            child: Consumer<EnergyDataProvider>(
              builder: (context, provider, child) {
                final metrics = provider.energyMetrics;
                if (metrics == null) return const SizedBox.shrink();
                return SmartAssistantWidget(energyData: metrics);
              },
            ),
          ),
        ],
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
                {'id': 'bedroom', 'name': 'Bedroom', 'icon': LucideIcons.bedDouble, 'value': metrics.rooms.bedroomPowerW, 'color': AppTheme.electricGreen, 'on': provider.roomsData['bedroom']?['status'] ?? false},
                {'id': 'livingRoom', 'name': 'Living', 'icon': LucideIcons.sofa, 'value': metrics.rooms.livingRoomPowerW, 'color': AppTheme.neonGreen, 'on': provider.roomsData['livingRoom']?['status'] ?? false},
                {'id': 'kitchen', 'name': 'Kitchen', 'icon': LucideIcons.utensils, 'value': metrics.rooms.kitchenPowerW, 'color': const Color(0xFF10B981), 'on': provider.roomsData['kitchen']?['status'] ?? false},
              ],
              onToggle: (id, val) => provider.toggleRoom(id, val),
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
        if (metrics == null) return _buildWaterEmptyState(provider);

        return Column(
          children: [
            // ─── 1. Low Tank Alert ────────────────────────────────────────
            if (metrics.isTankLow)
              _buildWaterAlert(
                icon: '⚠️',
                title: 'Water Tank Low',
                message:
                    'Tank is below 250L (${metrics.tankLevel.toStringAsFixed(0)}L remaining). Please turn ON the motor.',
                color: const Color(0xFFEF4444),
                bgColor: const Color(0xFFEF4444).withOpacity(0.08),
              ),

            // ─── Leak Alert ───────────────────────────────────────────────
            if (provider.leakDetected)
              _buildWaterAlert(
                icon: '🚨',
                title: 'Leakage Detected!',
                message:
                    'Flow rate: ${provider.liveWater?.flowRate.toStringAsFixed(1) ?? "0.0"} L/min continuously for over 2 minutes! Approx ${provider.leakedWaterL.toStringAsFixed(1)}L wasted so far.',
                color: const Color(0xFFF97316),
                bgColor: const Color(0xFFF97316).withOpacity(0.08),
              ),

            const SizedBox(height: 4),

            // ─── 2. Tank Level Gauge ──────────────────────────────────────
            _buildTankGauge(context, metrics, provider),
            const SizedBox(height: 16),

            // ─── Flow Rate + Today's Usage ────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Current Flow Rate',
                    value:
                        '${metrics.currentFlowLpm.toStringAsFixed(1)} L/min',
                    subtitle: metrics.outletOn
                        ? 'Draining'
                        : (metrics.motorStatus ? 'Motor filling' : 'Idle'),
                    icon: LucideIcons.droplets,
                    color: StatColor.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    title: "Today's Usage",
                    value:
                        '${metrics.todayUsageL.toStringAsFixed(1)} L',
                    subtitle: 'Daily water consumed',
                    icon: LucideIcons.calendar,
                    color: StatColor.teal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ─── 2c. Usage Trend Chart ──────────────────────────────────
            LiveUsageChart(
              data: provider.hourlyLive,
              isWater: true,
              themeColor: Colors.lightBlue,
              title: 'Water Flow Profile',
              subtitle: 'Hourly usage trend (Liters)',
              unit: 'L',
            ),
            const SizedBox(height: 16),

            // ─── Total Water + Sleep Mode in same row ────────────────────
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 600) {
                  return Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          title: 'Total Water Used',
                          value:
                              '${metrics.monthlyTotalL.toStringAsFixed(1)} L',
                          subtitle: 'This Month',
                          icon: LucideIcons.droplet,
                          color: StatColor.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildBillSection(
                            metrics.monthlyTotalL, null, true),
                      ),
                    ],
                  );
                }
                return Column(
                  children: [
                    StatCard(
                      title: 'Total Water Used',
                      value: '${metrics.monthlyTotalL.toStringAsFixed(1)} L',
                      subtitle: 'This Month',
                      icon: LucideIcons.droplet,
                      color: StatColor.blue,
                    ),
                    const SizedBox(height: 16),
                    _buildBillSection(metrics.monthlyTotalL, null, true),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            // ─── 3. Sleep Mode Toggle ─────────────────────────────────────
            _buildSleepModeCard(context, provider),
            const SizedBox(height: 16),

            // ─── 2d. Consumption Insights ────────────────────────────────
            _buildWaterInsights(metrics),
          ],
        );
      },
    );
  }

  /// Alert banner (low water / leak detected)
  Widget _buildWaterAlert({
    required String icon,
    required String title,
    required String message,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                        fontSize: 14)),
                const SizedBox(height: 2),
                Text(message,
                    style: TextStyle(
                        color: color.withOpacity(0.85), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Animated water tank gauge
  Widget _buildTankGauge(
      BuildContext context, WaterMetrics metrics, WaterDataProvider provider) {
    final appColors = context.appColors;
    final pct = metrics.tankPercent;
    final Color fillColor = pct < 0.25
        ? const Color(0xFFEF4444) // red
        : pct < 0.5
            ? const Color(0xFFF59E0B) // amber
            : const Color(0xFF3B82F6); // blue
    final Color fillColorEnd = pct < 0.25
        ? const Color(0xFFF87171)
        : pct < 0.5
            ? const Color(0xFFFBBF24)
            : const Color(0xFF06B6D4); // cyan

    return Container(
      decoration: BoxDecoration(
        color: appColors.card,
        borderRadius: BorderRadius.circular(24),
        border:
            Border.all(color: appColors.border.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.lightBlue.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.droplets,
                    size: 20, color: Colors.lightBlue),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Water Tank Level',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: appColors.foreground,
                          letterSpacing: -0.5)),
                  Text('Capacity: 1000 L',
                      style: TextStyle(
                          fontSize: 12,
                          color: appColors.mutedForeground)),
                ],
              ),
              const Spacer(),
              // Motor toggle button
              GestureDetector(
                onTap: () => provider.toggleMotor(),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: metrics.motorStatus
                        ? Colors.lightBlue.withOpacity(0.15)
                        : appColors.secondary,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                        color: metrics.motorStatus
                            ? Colors.lightBlue.withOpacity(0.5)
                            : appColors.border,
                        width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.refreshCw,
                          size: 14,
                          color: metrics.motorStatus
                              ? Colors.lightBlue
                              : appColors.mutedForeground),
                      const SizedBox(width: 6),
                      Text(
                        metrics.motorStatus ? 'Motor ON' : 'Motor OFF',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: metrics.motorStatus
                                ? Colors.lightBlue
                                : appColors.mutedForeground),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // Tank visual
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Bar chart representation
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${metrics.tankLevel.toStringAsFixed(0)} L',
                          style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: fillColor,
                              fontFamily: 'JetBrains Mono',
                              letterSpacing: -1.5),
                        ),
                        Text(
                          '${(pct * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: appColors.mutedForeground),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Progress bar
                    Container(
                      height: 20,
                      decoration: BoxDecoration(
                        color: appColors.secondary,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: pct,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 700),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [fillColor, fillColorEnd],
                            ),
                            borderRadius: BorderRadius.circular(100),
                            boxShadow: [
                              BoxShadow(
                                  color: fillColor.withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2))
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Water marks
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('0',
                            style: TextStyle(
                                fontSize: 10,
                                color: appColors.mutedForeground)),
                        Text('250L ⚠️',
                            style: TextStyle(
                                fontSize: 10,
                                color: pct < 0.25
                                    ? const Color(0xFFEF4444)
                                    : appColors.mutedForeground)),
                        Text('500L',
                            style: TextStyle(
                                fontSize: 10,
                                color: appColors.mutedForeground)),
                        Text('1000L',
                            style: TextStyle(
                                fontSize: 10,
                                color: appColors.mutedForeground)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Status column
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildStatusPill(
                      label: metrics.outletOn ? 'Draining' : 'Idle',
                      color: metrics.outletOn
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF6B7280),
                      icon: metrics.outletOn
                          ? LucideIcons.arrowDownCircle
                          : LucideIcons.pause),
                  const SizedBox(height: 6),
                  _buildStatusPill(
                      label: metrics.motorStatus ? 'Filling' : 'Motor Off',
                      color: metrics.motorStatus
                          ? Colors.lightBlue
                          : const Color(0xFF6B7280),
                      icon: metrics.motorStatus
                          ? LucideIcons.refreshCw
                          : LucideIcons.x),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(
      {required String label, required Color color, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  /// Sleep Mode Card with toggle and leak info
  Widget _buildSleepModeCard(BuildContext context, WaterDataProvider provider) {
    final appColors = context.appColors;
    final isSleep = provider.sleepMode;
    final isLeaking = provider.leakDetected;
    final flowSecs = provider.continuousFlowSeconds;

    return Container(
      decoration: BoxDecoration(
        color: appColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: isSleep
                ? const Color(0xFF6366F1).withOpacity(0.4)
                : appColors.border.withOpacity(0.5),
            width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.moonStar,
                    size: 20, color: Color(0xFF6366F1)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sleep Mode',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: appColors.foreground)),
                    Text(
                        isSleep
                            ? 'Monitoring for leaks…'
                            : 'Toggle to detect overnight leaks',
                        style: TextStyle(
                            fontSize: 12,
                            color: appColors.mutedForeground)),
                  ],
                ),
              ),
              // Toggle switch
              GestureDetector(
                onTap: () => provider.toggleSleepMode(),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 50,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isSleep
                        ? const Color(0xFF6366F1)
                        : appColors.secondary,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                        color: isSleep
                            ? const Color(0xFF6366F1)
                            : appColors.border,
                        width: 1.5),
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    alignment: isSleep
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (isSleep) ...
            [
              const SizedBox(height: 14),
              Divider(
                  color: appColors.border.withOpacity(0.4), height: 1),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(
                    isLeaking ? LucideIcons.alertTriangle : LucideIcons.shieldCheck,
                    size: 16,
                    color: isLeaking
                        ? const Color(0xFFF97316)
                        : const Color(0xFF22C55E),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isLeaking
                        ? '🚨 Leak! ${provider.leakedWaterL.toStringAsFixed(1)}L wasted'
                        : flowSecs > 0
                            ? 'Flow detected!'
                            : 'No flow detected · Safe ✓',
                    style: TextStyle(
                        fontSize: 13,
                        color: isLeaking
                            ? const Color(0xFFF97316)
                            : flowSecs > 0
                                ? const Color(0xFFF59E0B)
                                : const Color(0xFF22C55E),
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
        ],
      ),
    );
  }

  /// 2d. Consumption insights panel
  Widget _buildWaterInsights(WaterMetrics metrics) {
    final appColors = context.appColors;
    final insightLines = <_Insight>[
      if (metrics.peakTime.isNotEmpty)
        _Insight(
          icon: '🕐',
          text: 'Peak usage at ${metrics.peakTime}',
        ),
      _Insight(
        icon: '📊',
        text:
            'Average daily usage: ${metrics.dailyAverageL.toStringAsFixed(0)}L',
      ),
      _Insight(
        icon: '📅',
        text:
            'Estimated monthly: ${metrics.estimatedMonthlyLiters.toStringAsFixed(0)}L',
      ),
      if (metrics.isTankLow)
        _Insight(icon: '⚠️', text: 'Tank critically low — motor advised!'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: appColors.card,
        borderRadius: BorderRadius.circular(24),
        border:
            Border.all(color: appColors.border.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.sparkles,
                  color: Colors.lightBlue, size: 20),
              const SizedBox(width: 10),
              Text(
                'Consumption Insights',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: appColors.foreground,
                    letterSpacing: -0.5),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...insightLines.map(
            (i) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Text(i.icon,
                      style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Text(i.text,
                      style: TextStyle(
                          fontSize: 14,
                          color: appColors.foreground,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Fallback when provider has no data yet but for water
  Widget _buildWaterEmptyState(WaterDataProvider provider) {
    final appColors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Text('💧', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text('Water data not available',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: appColors.foreground)),
          const SizedBox(height: 8),
          Text(
              'Start the Home Simulation to send water data to Firebase.',
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontSize: 13, color: appColors.mutedForeground)),
          const SizedBox(height: 20),
          // Still show sleep mode toggle
          _buildSleepModeCard(context, provider),
        ],
      ),
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
    final validTariff = (tariff is TariffSlabs) ? tariff : defaultTariff;
    
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
            tariff: validTariff,
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
    void Function(String id, bool val)? onToggle,
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
              id: r['id'] ?? r['name'],
              icon: r['icon'],
              name: r['name'],
              value: r['value'],
              color: r['color'],
              isOn: r['on'],
              themeColor: themeColor,
              unit: isWater ? "L" : "kW",
              onToggle: onToggle,
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
    String? id,
    void Function(String id, bool val)? onToggle,
  }) {
    final appColors = context.appColors;
    return GestureDetector(
      onTap: onToggle != null && id != null
          ? () => onToggle(id, !isOn)
          : null,
      child: Column(
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
    ),
  );
}
}

/// Simple data class for water insight list items
class _Insight {
  final String icon;
  final String text;
  const _Insight({required this.icon, required this.text});
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/energy_provider.dart';
import '../theme/app_theme.dart';
import '../utils/analytics.dart';
import '../widgets/stat_card.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final TextEditingController _targetController = TextEditingController();
  double _activeTarget = 0.0;
  bool _savingTarget = false;

  @override
  void initState() {
    super.initState();
    _loadTarget();
  }

  Future<void> _loadTarget() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _activeTarget = prefs.getDouble('monthly_target') ?? 0.0;
    });
  }

  Future<void> _handleSaveTarget(double currentTotal) async {
    final val = double.tryParse(_targetController.text);
    if (val == null || val <= 0) return;

    setState(() => _savingTarget = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('monthly_target', val);

    if (currentTotal >= val && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unit target exceeded! Usage ${currentTotal.toStringAsFixed(4)} kWh crossed target $val kWh.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }

    setState(() {
      _savingTarget = false;
      _activeTarget = val;
      _targetController.clear();
    });
  }

  @override
  void dispose() {
    _targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Consumer<EnergyDataProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor));
          }

          final metrics = provider.energyMetrics;
          if (metrics == null) {
            return Center(child: Text("No data available", style: TextStyle(color: context.appColors.mutedForeground)));
          }

          final currentTotal = metrics.monthlyTotalKwh;
          final lastPower = metrics.currentPowerKw;
          final bedroomPower = metrics.rooms.bedroomPowerW;
          final livingRoomPower = metrics.rooms.livingRoomPowerW;
          final kitchenPower = metrics.rooms.kitchenPowerW;

          final peak = provider.peak;

          final activeRooms = [
            {'name': 'Bedroom', 'active': bedroomPower > 0},
            {'name': 'Living Room', 'active': livingRoomPower > 0},
            {'name': 'Kitchen', 'active': kitchenPower > 0},
          ];
          final activeCount = activeRooms.where((r) => r['active'] as bool).length;

          final targetPercent = _activeTarget > 0 ? (currentTotal / _activeTarget).clamp(0.0, 1.0) : 0.0;
          final exceeded = _activeTarget > 0 && currentTotal >= _activeTarget;
          final appColors = context.appColors;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Analytics",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Room-wise consumption & insights",
                  style: TextStyle(fontSize: 14, color: appColors.mutedForeground),
                ),
                const SizedBox(height: 24),

                // Total Units
                StatCard(
                  title: "Total Units This Month",
                  value: "${currentTotal.toStringAsFixed(4)} kWh",
                  subtitle: "Delta energy sum",
                  icon: LucideIcons.activity,
                  color: StatColor.teal,
                ),
                const SizedBox(height: 24),

                // Historical Usage Charts
                UsageChartWidget(
                  daily: provider.daily,
                  weekly: provider.weekly,
                  monthly: provider.monthly,
                ),
                const SizedBox(height: 24),

                // Room Pie Chart — use liveData energy counters (same source as Total Units card)
                RoomBreakdownWidget(
                  bedroom: provider.liveData?.energy['bedroom'] ?? provider.monthEnergy?['bedroom'] ?? 0.0,
                  livingRoom: provider.liveData?.energy['livingRoom'] ?? provider.monthEnergy?['livingRoom'] ?? 0.0,
                  kitchen: provider.liveData?.energy['kitchen'] ?? provider.monthEnergy?['kitchen'] ?? 0.0,
                ),
                const SizedBox(height: 24),

                // Active Rooms
                Container(
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
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.electricGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(LucideIcons.zap, size: 20, color: AppTheme.electricGreen),
                          ),
                          const SizedBox(width: 14),
                          Text(
                            "Active Load ($activeCount/3)",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: appColors.foreground, letterSpacing: -0.5),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      ...activeRooms.map((room) => Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(room['name'] as String, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: appColors.foreground)),
                            Row(
                              children: [
                                Container(
                                  width: 8, height: 8,
                                  decoration: BoxDecoration(
                                    color: (room['active'] as bool) ? AppTheme.electricGreen : appColors.mutedForeground.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                    boxShadow: (room['active'] as bool) ? [
                                      BoxShadow(color: AppTheme.electricGreen.withOpacity(0.4), blurRadius: 4, spreadRadius: 1)
                                    ] : null,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  (room['active'] as bool) ? "Active" : "Idle",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: (room['active'] as bool) ? AppTheme.electricGreen : appColors.mutedForeground,
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ))
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Monthly Insights (Replaced Efficiency Peak)
                Container(
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
                          Icon(LucideIcons.sparkles, color: const Color(0xFFF59E0B), size: 20),
                          const SizedBox(width: 10),
                          Text(
                            "Monthly Insights",
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
                                "Peak Usage Day",
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: appColors.mutedForeground),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                metrics.peakDay,
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: appColors.foreground),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "Estimated Monthly Units",
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: appColors.mutedForeground),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "${metrics.estimatedMonthlyUnits.toStringAsFixed(1)} kWh",
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.electricGreen),
                              ),
                            ],
                          )
                        ],
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Unit Target System
                Container(
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
                              color: const Color(0xFF3B82F6).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(LucideIcons.target, size: 20, color: Color(0xFF3B82F6)),
                          ),
                          const SizedBox(width: 14),
                          Text(
                            "Sustainability Shield",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: appColors.foreground, letterSpacing: -0.5),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (_activeTarget > 0) ...[
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
                                  child: Text("Conservation target reached. Usage optimization recommended.", 
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.error)),
                                ),
                              ],
                            ),
                          ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("${currentTotal.toStringAsFixed(2)} / $_activeTarget kWh", 
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'JetBrains Mono', color: appColors.foreground)),
                            Text("${(targetPercent * 100).toStringAsFixed(0)}%", 
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'JetBrains Mono', color: AppTheme.neonGreen)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: targetPercent,
                            minHeight: 12,
                            backgroundColor: appColors.secondary,
                            valueColor: AlwaysStoppedAnimation<Color>(exceeded ? Theme.of(context).colorScheme.error : AppTheme.electricGreen),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ] else
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20.0),
                          child: Text("Set a monthly allowance to track eco-efficiency.", style: TextStyle(fontSize: 13, color: appColors.mutedForeground, fontWeight: FontWeight.w500)),
                        ),

                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _targetController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'JetBrains Mono', color: appColors.foreground),
                              decoration: InputDecoration(
                                hintText: _activeTarget > 0 ? "Cur: $_activeTarget" : "Limit (kWh)",
                                hintStyle: TextStyle(fontSize: 14, color: appColors.mutedForeground),
                                filled: true,
                                fillColor: appColors.secondary,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.electricGreen, width: 2)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.electricGreen,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _savingTarget ? null : () => _handleSaveTarget(currentTotal),
                            child: Text(_savingTarget ? "..." : "Set Goal", style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }
}

class UsageChartWidget extends StatefulWidget {
  final List<BucketData> daily;
  final List<BucketData> weekly;
  final List<BucketData> monthly;

  const UsageChartWidget({super.key, required this.daily, required this.weekly, required this.monthly});

  @override
  State<UsageChartWidget> createState() => _UsageChartWidgetState();
}

class _UsageChartWidgetState extends State<UsageChartWidget> {
  String _period = 'daily';

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    List<BucketData> data;
    double minWidth;
    switch (_period) {
      case 'weekly':
        data = widget.weekly;
        minWidth = 600;
        break;
      case 'monthly':
        data = widget.monthly;
        minWidth = 800;
        break;
      case 'daily':
      default:
        data = widget.daily;
        minWidth = 1400;
        break;
    }

    double maxY = 10.0;
    if (data.isNotEmpty) {
      maxY = data.map((e) => e.total).reduce((a, b) => a > b ? a : b);
    }
    if (maxY == 0) maxY = 10.0;
    
    double chartMaxY = maxY * 1.2;
    double interval = chartMaxY / 4;
    if (interval <= 0) interval = 1.0;

    return Container(
      decoration: BoxDecoration(
        color: appColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: appColors.border.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))
        ]
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text("Consumption History", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: appColors.foreground, letterSpacing: -0.5)),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(color: appColors.secondary, borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.all(4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: ['daily', 'weekly', 'monthly'].map((p) {
                    final isSelected = _period == p;
                    return GestureDetector(
                      onTap: () => setState(() => _period = p),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.electricGreen : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          p[0].toUpperCase() + p.substring(1),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : appColors.mutedForeground,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: minWidth,
              height: 380,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: chartMaxY,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => AppTheme.deepBlue.withOpacity(0.9),
                      tooltipBorderRadius: BorderRadius.circular(8),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${rod.toY.toStringAsFixed(2)} kWh',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        );
                      }
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          if (value < 0 || value >= data.length) return const SizedBox();
                          return Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: Transform.rotate(
                              angle: _period == 'daily' ? -0.4 : 0,
                              child: Text(
                                data[value.toInt()].label,
                                style: TextStyle(color: appColors.mutedForeground, fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 45,
                        interval: interval,
                        getTitlesWidget: (value, meta) {
                          String text = value.toStringAsFixed(2);
                          if (text.endsWith('.00')) text = value.toStringAsFixed(0);
                          else if (text.endsWith('0')) text = value.toStringAsFixed(1);
                          return Text(text, style: TextStyle(color: appColors.mutedForeground, fontSize: 10, fontWeight: FontWeight.bold));
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    drawHorizontalLine: true,
                    horizontalInterval: interval,
                    getDrawingHorizontalLine: (value) => FlLine(color: appColors.border.withOpacity(0.4), strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: data.asMap().entries.map((e) {
                    if (_period == 'monthly') {
                      return BarChartGroupData(
                        x: e.key,
                        barsSpace: 4,
                        barRods: [
                          BarChartRodData(toY: e.value.total, color: AppTheme.electricGreen, width: 24, borderRadius: BorderRadius.circular(4)),
                        ],
                      );
                    }
                    return BarChartGroupData(
                      x: e.key,
                      barsSpace: 4,
                      barRods: [
                        BarChartRodData(toY: e.value.bedroom, color: appColors.bedroom, width: 10, borderRadius: BorderRadius.circular(4)),
                        BarChartRodData(toY: e.value.livingRoom, color: appColors.living, width: 10, borderRadius: BorderRadius.circular(4)),
                        BarChartRodData(toY: e.value.kitchen, color: appColors.kitchen, width: 10, borderRadius: BorderRadius.circular(4)),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_period != 'monthly')
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem("Bedroom", appColors.bedroom),
                const SizedBox(width: 20),
                _buildLegendItem("Living", appColors.living),
                const SizedBox(width: 20),
                _buildLegendItem("Kitchen", appColors.kitchen),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem("Total", AppTheme.electricGreen),
              ],
            )
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
      ],
    );
  }
}

class RoomBreakdownWidget extends StatelessWidget {
  final double bedroom;
  final double livingRoom;
  final double kitchen;

  const RoomBreakdownWidget({super.key, required this.bedroom, required this.livingRoom, required this.kitchen});

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final total = bedroom + livingRoom + kitchen;
    final data = [
      {'name': 'Bedroom', 'value': bedroom, 'pct': total > 0 ? (bedroom / total * 100).round() : 0, 'color': appColors.bedroom},
      {'name': 'Living', 'value': livingRoom, 'pct': total > 0 ? (livingRoom / total * 100).round() : 0, 'color': appColors.living},
      {'name': 'Kitchen', 'value': kitchen, 'pct': total > 0 ? (kitchen / total * 100).round() : 0, 'color': appColors.kitchen},
    ];

    return Container(
      decoration: BoxDecoration(
        color: appColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: appColors.border.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))
        ]
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Zone Distribution", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: appColors.foreground, letterSpacing: -0.5)),
          const SizedBox(height: 32),
          Row(
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 4,
                    centerSpaceRadius: 35,
                    sections: data.map((e) {
                      return PieChartSectionData(
                        color: e['color'] as Color,
                        value: e['value'] as double,
                        title: '',
                        radius: 30,
                        badgeWidget: null,
                      );
                    }).toList(),
                  )
                ),
              ),
              const SizedBox(width: 32),
              Expanded(
                child: Column(
                  children: data.map((room) => Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(width: 10, height: 10, decoration: BoxDecoration(color: room['color'] as Color, shape: BoxShape.circle)),
                            const SizedBox(width: 10),
                            Text(room['name'] as String, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: appColors.foreground)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text("${(room['value'] as double).toStringAsFixed(1)} kWh", 
                                style: TextStyle(fontSize: 14, fontFamily: 'JetBrains Mono', fontWeight: FontWeight.bold, color: appColors.foreground)),
                            Text("${room['pct']}%", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: appColors.mutedForeground)),
                          ],
                        ),
                      ],
                    ),
                  )).toList(),
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}

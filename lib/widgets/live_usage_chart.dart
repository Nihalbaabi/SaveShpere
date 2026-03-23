import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/analytics.dart';
import '../theme/app_theme.dart';

class LiveUsageChart extends StatelessWidget {
  final List<BucketData> data;
  final bool isWater;
  final Color themeColor;
  final String title;
  final String subtitle;
  final String unit;

  const LiveUsageChart({
    Key? key,
    required this.data,
    this.isWater = false,
    this.themeColor = AppTheme.electricGreen,
    this.title = 'Energy Consumption Profile',
    this.subtitle = 'Real-time total hourly usage',
    this.unit = 'kW',
  }) : super(key: key);

  List<FlSpot> _getSpots(String roomKey) {
    if (data.isEmpty) return [];
    List<FlSpot> spots = [];
    for (int i = 0; i < data.length; i++) {
      double val = 0;
      if (roomKey == 'bedroom') val = data[i].bedroom;
      if (roomKey == 'livingRoom') val = data[i].livingRoom;
      if (roomKey == 'kitchen') val = data[i].kitchen;
      if (roomKey == 'total') val = data[i].total;
      spots.add(FlSpot(i.toDouble(), val));
    }
    return spots;
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    double maxY = 0.0;
    for (var d in data) {
      if (d.total > maxY) maxY = d.total;
    }
    if (maxY == 0) maxY = 1.0;
    
    double chartMaxY = maxY * 1.2;
    double interval = chartMaxY / 4;
    if (interval <= 0) interval = 0.2;

    return Container(
      decoration: BoxDecoration(
        color: appColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: appColors.border.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: appColors.foreground,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: appColors.mutedForeground,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: themeColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'LIVE',
                      style: TextStyle(
                        color: themeColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 900,
              height: 380,
              child: Padding(
                padding: const EdgeInsets.only(right: 18.0, left: 12.0, top: 24, bottom: 12),
                child: LineChart(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutQuart,
                  LineChartData(
                    lineTouchData: LineTouchData(
                      handleBuiltInTouches: true,
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (touchedSpot) => AppTheme.deepBlue.withOpacity(0.9),
                        tooltipBorderRadius: BorderRadius.circular(12),
                        getTooltipItems: (List<LineBarSpot> touchedSpots) {
                          return touchedSpots.map((spot) {
                            return LineTooltipItem(
                              'Total: ${spot.y.toStringAsFixed(2)} $unit',
                              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            );
                          }).toList();
                        },
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: interval,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: appColors.border.withOpacity(0.4),
                          strokeWidth: 1,
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 35,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            if (value < 0 || value >= data.length) return const SizedBox();
                            final label = data[value.toInt()].label;
                            return Padding(
                              padding: const EdgeInsets.only(top: 12.0),
                              child: Text(
                                label,
                                style: TextStyle(
                                  color: appColors.mutedForeground,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: interval,
                          getTitlesWidget: (value, meta) {
                            String text = value.toStringAsFixed(2);
                            if (text.endsWith('.00')) text = value.toStringAsFixed(0);
                            else if (text.endsWith('0')) text = value.toStringAsFixed(1);
                            return Text(
                              '$text $unit',
                              style: TextStyle(
                                color: appColors.mutedForeground,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          },
                          reservedSize: 55,
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    minY: 0,
                    maxY: chartMaxY,
                    lineBarsData: [
                      // Total Consumption
                      LineChartBarData(
                        spots: _getSpots('total'),
                        isCurved: true,
                        curveSmoothness: 0.35,
                        preventCurveOverShooting: true,
                        color: themeColor,
                        barWidth: 4,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              themeColor.withOpacity(0.2),
                              themeColor.withOpacity(0.0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(themeColor, isWater ? 'Total Water Volume' : 'Total Consumption'),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}

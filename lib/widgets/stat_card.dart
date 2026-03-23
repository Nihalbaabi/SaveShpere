import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum StatColor { green, teal, orange, blue }

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final String? trend;
  final StatColor color;

  const StatCard({
    Key? key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    this.trend,
    this.color = StatColor.green,
  }) : super(key: key);

  Color _getBaseColor() {
    switch (color) {
      case StatColor.green:
        return AppTheme.electricGreen;
      case StatColor.teal:
        return AppTheme.neonGreen;
      case StatColor.orange:
        return const Color(0xFFF59E0B); // Amber
      case StatColor.blue:
        return const Color(0xFF3B82F6); // Blue
    }
  }

  List<Color> _getGradientColors() {
    switch (color) {
      case StatColor.green:
        return [AppTheme.electricGreen, AppTheme.neonGreen];
      case StatColor.teal:
        return [AppTheme.neonGreen, const Color(0xFF10B981)];
      case StatColor.orange:
        return [const Color(0xFFF59E0B), const Color(0xFFEF4444)];
      case StatColor.blue:
        return [const Color(0xFF3B82F6), const Color(0xFF8B5CF6)];
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = _getBaseColor();
    final gradientColors = _getGradientColors();
    final appColors = context.appColors;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: appColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: appColors.border.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: baseColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: baseColor, size: 22),
              ),
              if (trend != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.electricGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    trend!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.electricGreen,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: appColors.mutedForeground,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 8),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                fontFamily: 'JetBrains Mono',
                letterSpacing: -1,
                color: Colors.white,
              ),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: appColors.secondary.withOpacity(0.5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: appColors.mutedForeground,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

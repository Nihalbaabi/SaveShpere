import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../providers/notification_provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  IconData _getIconForType(String type) {
    switch (type) {
      case 'budget':
        return LucideIcons.alertOctagon;
      case 'slab':
        return LucideIcons.layers;
      case 'power':
        return LucideIcons.zap;
      case 'peak':
        return LucideIcons.clock;
      default:
        return LucideIcons.bell;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'budget':
        return const Color(0xFFEF4444); // Red-500
      case 'slab':
        return const Color(0xFFF59E0B); // Amber-500
      case 'power':
        return AppTheme.electricGreen;
      case 'peak':
        return const Color(0xFF3B82F6); // Blue-500
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          final alerts = provider.notifications;

          return SingleChildScrollView(
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
                          "Alerts & Notifications",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: appColors.foreground,
                            letterSpacing: -1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Stay updated on your energy goals",
                          style: TextStyle(fontSize: 14, color: appColors.mutedForeground, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    if (alerts.isNotEmpty)
                      GestureDetector(
                        onTap: () => provider.clearAll(),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: appColors.secondary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(LucideIcons.trash2, size: 18, color: appColors.mutedForeground),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                
                if (alerts.isEmpty)
                   Center(
                     child: Padding(
                       padding: const EdgeInsets.only(top: 100.0),
                       child: Column(
                         children: [
                           Container(
                             padding: const EdgeInsets.all(24),
                             decoration: BoxDecoration(
                               color: appColors.secondary,
                               shape: BoxShape.circle,
                             ),
                             child: Icon(LucideIcons.bellOff, size: 40, color: appColors.mutedForeground.withOpacity(0.5)),
                           ),
                           const SizedBox(height: 20),
                           Text("No notifications yet", style: TextStyle(color: appColors.mutedForeground, fontWeight: FontWeight.w600)),
                         ],
                       ),
                     ),
                   ),
                   
                for (final alert in alerts)
                  GestureDetector(
                    onTap: () => provider.markAsRead(alert.id),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: appColors.card,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: alert.isRead 
                            ? appColors.border.withOpacity(0.5) 
                            : _getColorForType(alert.type).withOpacity(0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                          if (!alert.isRead)
                            BoxShadow(
                              color: _getColorForType(alert.type).withOpacity(0.05),
                              blurRadius: 15,
                              offset: const Offset(0, 4),
                            )
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _getColorForType(alert.type).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              _getIconForType(alert.type), 
                              size: 22, 
                              color: _getColorForType(alert.type)
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        alert.title, 
                                        style: TextStyle(
                                          fontSize: 16, 
                                          fontWeight: FontWeight.bold,
                                          color: appColors.foreground,
                                        )
                                      ),
                                    ),
                                    if (!alert.isRead)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: _getColorForType(alert.type),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(color: _getColorForType(alert.type).withOpacity(0.4), blurRadius: 4, spreadRadius: 1)
                                          ]
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  alert.body, 
                                  style: TextStyle(
                                    fontSize: 14, 
                                    color: appColors.mutedForeground,
                                    height: 1.4,
                                    fontWeight: FontWeight.w500,
                                  )
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  alert.timeAgo, 
                                  style: TextStyle(
                                    fontSize: 12, 
                                    color: appColors.mutedForeground.withOpacity(0.6),
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.2,
                                  )
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

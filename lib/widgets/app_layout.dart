import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../theme/app_theme.dart';

class AppLayout extends StatefulWidget {
  final Widget child;
  final String currentRoute;
  final Function(String) onNavigate;

  const AppLayout({
    Key? key,
    required this.child,
    required this.currentRoute,
    required this.onNavigate,
  }) : super(key: key);

  @override
  State<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends State<AppLayout> {
  bool _isOnline = false;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  final List<Map<String, dynamic>> _navItems = [
    {'route': '/home', 'icon': LucideIcons.layoutDashboard, 'label': 'Home'},
    {'route': '/money', 'icon': LucideIcons.indianRupee, 'label': 'Money'},
    {'route': '/analytics', 'icon': LucideIcons.activity, 'label': 'Analytics'},
    {'route': '/notifications', 'icon': LucideIcons.bell, 'label': 'Alerts'},
    {'route': '/settings', 'icon': LucideIcons.settings, 'label': 'Settings'},
  ];

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (mounted) setState(() => _isOnline = online);
    });
  }

  Future<void> _checkConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    final online = results.any((r) => r != ConnectivityResult.none);
    if (mounted) setState(() => _isOnline = online);
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final isDesktop = MediaQuery.of(context).size.width >= 768;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: isDesktop
          ? null
          : AppBar(
              backgroundColor: appColors.card.withOpacity(0.9),
              elevation: 0,
              iconTheme: IconThemeData(color: appColors.foreground),
              title: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      image: const DecorationImage(
                        image: AssetImage('assets/applauncher.jpg'),
                        fit: BoxFit.cover,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.electricGreen.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'SaveSphere',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: appColors.foreground,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1.0),
                child: Container(color: appColors.border.withOpacity(0.5), height: 1.0),
              ),
            ),
      drawer: isDesktop
          ? null
          : Drawer(
              backgroundColor: appColors.card,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: appColors.border.withOpacity(0.5))),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            image: const DecorationImage(
                              image: AssetImage('assets/applauncher.jpg'),
                              fit: BoxFit.cover,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'SaveSphere',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: appColors.foreground,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._navItems.map((item) {
                    final isActive = widget.currentRoute == item['route'];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      child: ListTile(
                        leading: Icon(
                          item['icon'],
                          color: isActive ? AppTheme.electricGreen : appColors.mutedForeground,
                          size: 22,
                        ),
                        title: Text(
                          item['label'],
                          style: TextStyle(
                            color: isActive ? appColors.foreground : appColors.mutedForeground,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                        selected: isActive,
                        selectedTileColor: AppTheme.electricGreen.withOpacity(0.1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        onTap: () {
                          Navigator.pop(context);
                          widget.onNavigate(item['route']);
                        },
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
      body: Row(
        children: [
          if (isDesktop)
            Container(
              width: 260,
              decoration: BoxDecoration(
                border: Border(right: BorderSide(color: appColors.border.withOpacity(0.5))),
                color: isDark ? AppTheme.deepBlue : Colors.white,
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(28),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            image: const DecorationImage(
                              image: AssetImage('assets/applauncher.jpg'),
                              fit: BoxFit.cover,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.electricGreen.withOpacity(0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SaveSphere',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: appColors.foreground,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: _navItems.map((item) {
                        final isActive = widget.currentRoute == item['route'];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: isActive ? AppTheme.electricGreen.withOpacity(0.1) : Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: ListTile(
                              leading: Icon(
                                item['icon'],
                                color: isActive ? AppTheme.electricGreen : appColors.mutedForeground,
                                size: 22,
                              ),
                              title: Text(
                                item['label'],
                                style: TextStyle(
                                  color: isActive ? appColors.foreground : appColors.mutedForeground,
                                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                                  fontSize: 15,
                                ),
                              ),
                              onTap: () => widget.onNavigate(item['route']),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(24),
                    margin: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: appColors.secondary.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: appColors.border.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _isOnline
                                ? AppTheme.electricGreen
                                : const Color(0xFFEF4444),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (_isOnline
                                        ? AppTheme.electricGreen
                                        : const Color(0xFFEF4444))
                                    .withOpacity(0.6),
                                blurRadius: 6,
                                spreadRadius: 1,
                              )
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _isOnline ? 'Online' : 'Offline',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _isOnline
                                      ? AppTheme.electricGreen
                                      : const Color(0xFFEF4444),
                                ),
                              ),
                              Text(
                                _isOnline
                                    ? 'App connected to WiFi'
                                    : 'No internet connection',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: appColors.mutedForeground,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

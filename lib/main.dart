import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'providers/energy_provider.dart';
import 'providers/water_provider.dart';

import 'providers/notification_provider.dart';
import 'widgets/app_layout.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/money_management_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/login_screen.dart';

import 'services/notification_service.dart';
import 'services/auth_service.dart';
import 'providers/assistant_provider.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyCT7MCA-pF0VlqcVTnxLK53lWX_AdhfaT8',
        appId: '1:75943323165:android:943e1ca24f54980df148f4',
        messagingSenderId: '75943323165',
        projectId: 'hackkarma',
        databaseURL: 'https://hackkarma-default-rtdb.asia-southeast1.firebasedatabase.app',
      ),
    );
  } catch (e) {
    debugPrint("Firebase init failed: $e");
  }

  // Initialize Providers
  final notificationProvider = NotificationProvider();

  // Initialize Notifications
  final notificationService = NotificationService();
  notificationService.setProvider(notificationProvider);
  
  // Don't let notification init block the app startup completely if it hangs
  notificationService.initializeNotifications().catchError((e) {
    debugPrint("Notification init failed: $e");
  });
  
  // Initialize Auth
  await AuthService.instance.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider.value(value: AuthService.instance),
        ChangeNotifierProvider.value(value: notificationProvider),
      ],
      child: const SaveSphereApp(),
    ),
  );
}

class SaveSphereApp extends StatefulWidget {
  const SaveSphereApp({super.key});

  @override
  State<SaveSphereApp> createState() => _SaveSphereAppState();
}

class _SaveSphereAppState extends State<SaveSphereApp> {
  bool _splashFinished = false;

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, AuthService>(
      builder: (context, themeProvider, authService, child) {
        return MaterialApp(
          title: 'SaveSphere',
          themeMode: themeProvider.themeMode,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          debugShowCheckedModeBanner: false,
          home: !_splashFinished
              ? SplashScreen(onFinished: () => setState(() => _splashFinished = true))
              : (authService.isLoggedIn ? const LoggedInWrapper() : const LoginScreen()),
        );
      },
    );
  }
}

class LoggedInWrapper extends StatelessWidget {
  const LoggedInWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EnergyDataProvider()),
        ChangeNotifierProvider(create: (_) => WaterDataProvider()),
        ChangeNotifierProvider(create: (_) => AssistantProvider()),
      ],
      child: const MainRouter(),
    );
  }
}

class MainRouter extends StatefulWidget {
  const MainRouter({super.key});

  @override
  State<MainRouter> createState() => _MainRouterState();
}

class _MainRouterState extends State<MainRouter> {
  String _currentRoute = '/home';

  void _navigate(String route) {
    setState(() {
      _currentRoute = route;
    });
  }

  Widget _getCurrentScreen() {
    switch (_currentRoute) {
      case '/home':
        return HomeScreen(onNavigate: _navigate);
      case '/money':
        return const MoneyManagementScreen();
      case '/analytics':
        return const AnalyticsScreen();
      case '/notifications':
        return const NotificationsScreen();
      case '/settings':
        return const SettingsScreen();
      default:
        return HomeScreen(onNavigate: _navigate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      currentRoute: _currentRoute,
      onNavigate: _navigate,
      child: _getCurrentScreen(),
    );
  }
}

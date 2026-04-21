import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';

import 'core/theme/app_theme.dart';
import 'providers/app_state_provider.dart';
import 'providers/tank_provider.dart';
import 'services/background_service.dart';
import 'views/main_page.dart';
import 'widgets/alert_notification_overlay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Request location permissions
  await _requestLocationPermission();

  // Initialize Background Service
  await initializeService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
        ChangeNotifierProvider(create: (_) => TankProvider()),
      ],
      child: const AquaGuardApp(),
    ),
  );
}

Future<void> _requestLocationPermission() async {
  bool serviceEnabled;
  LocationPermission permission;

  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return;
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return;
    }
  }

  if (permission == LocationPermission.deniedForever) {
    return;
  }
}

class AquaGuardApp extends StatelessWidget {
  const AquaGuardApp({Key? key}) : super(key: key);

  static final GlobalKey<NavigatorState> _navigatorKey =
      GlobalKey<NavigatorState>();

  static const AppBarTheme _appBarTheme = AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    iconTheme: IconThemeData(color: Colors.black87),
    titleTextStyle: TextStyle(color: Colors.black87, fontSize: 18),
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AquaGuard Live',
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
      theme: ThemeData(
        primaryColor: AppTheme.cardColor,
        scaffoldBackgroundColor: AppTheme.backgroundColor,
        fontFamily: 'Roboto',
        appBarTheme: _appBarTheme,
      ),
      builder: (context, child) =>
          AlertNotificationOverlay(navigatorKey: _navigatorKey, child: child!),
      home: const MainPage(),
    );
  }
}

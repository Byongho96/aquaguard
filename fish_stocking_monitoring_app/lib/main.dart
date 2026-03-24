import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'providers/app_state_provider.dart';
import 'providers/tank_provider.dart';
import 'views/main_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

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

class AquaGuardApp extends StatelessWidget {
  const AquaGuardApp({Key? key}) : super(key: key);

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
      theme: ThemeData(
        primaryColor: AppTheme.cardColor,
        scaffoldBackgroundColor: AppTheme.backgroundColor,
        fontFamily: 'Roboto',
        appBarTheme: _appBarTheme,
      ),
      home: const MainPage(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state_provider.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({Key? key}) : super(key: key);

  static const TextStyle _titleStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.2,
  );
  static const TextStyle _separatorStyle = TextStyle(
    fontSize: 18,
    color: Colors.grey,
  );
  static const TextStyle _timeStyle = TextStyle(fontSize: 18);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        final String timeText =
            '${appState.currentTime.hour.toString().padLeft(2, '0')} : '
            '${appState.currentTime.minute.toString().padLeft(2, '0')}';

        IconData networkIcon;
        Color networkColor = Colors.black87;

        switch (appState.networkStatus) {
          case NetworkStatus.wifi:
            networkIcon = Icons.wifi;
            break;
          case NetworkStatus.cellular:
            networkIcon = Icons.cell_tower;
            break;
          case NetworkStatus.offline:
            networkIcon = Icons.wifi_off;
            networkColor = Colors.red;
            break;
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('AQUAGUARD LIVE', style: _titleStyle),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.0),
              child: Text('|', style: _separatorStyle),
            ),
            Text(timeText, style: _timeStyle),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.0),
              child: Text('|', style: _separatorStyle),
            ),
            Icon(networkIcon, color: networkColor, size: 24),
          ],
        );
      },
    );
  }
}

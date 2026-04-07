import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/tank_provider.dart';
import '../widgets/header.dart';
import '../widgets/sensor_card.dart';
import 'detail_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TankProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(title: const AppHeader(), centerTitle: true),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 450,
                          crossAxisSpacing: 24,
                          mainAxisSpacing: 24,
                          mainAxisExtent: 500,
                        ),
                    itemCount: provider.tanks.length,
                    itemBuilder: (context, index) {
                      final tank = provider.tanks[index];
                      return _buildTankCard(context, tank, index + 1);
                    },
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildTankCard(BuildContext context, dynamic tank, int tankIndex) {
    final TankProvider provider = context.read<TankProvider>();
    final String tankName = provider.getTankName(tank.id, tankIndex);

    final List<double> temperatureThreshold = provider.getThreshold(
      tank.id,
      'temperature',
    );
    final List<double> oxygenThreshold = provider.getThreshold(
      tank.id,
      'oxygen',
    );
    final List<double> saltThreshold = provider.getThreshold(tank.id, 'salt');
    final List<double> turbidityThreshold = provider.getThreshold(
      tank.id,
      'turbidity',
    );

    final bool isTempAlert =
        tank.temperature < temperatureThreshold[0] ||
        tank.temperature > temperatureThreshold[1];
    final bool isOxygenAlert =
        tank.oxygen < oxygenThreshold[0] || tank.oxygen > oxygenThreshold[1];
    final bool isSaltAlert =
        tank.salt < saltThreshold[0] || tank.salt > saltThreshold[1];
    final bool isTurbidityAlert =
        tank.turbidity < turbidityThreshold[0] ||
        tank.turbidity > turbidityThreshold[1];

    final _TankStatusViewData statusData = _resolveStatusData(provider, tank);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                DetailPage(tankId: tank.id, tankIndex: tankIndex),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '[ $tankName ]',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'AI자동제어',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      CupertinoSwitch(
                        value: tank.isAiControlled,
                        activeColor: Colors.green,
                        onChanged: (value) =>
                            provider.toggleAiControl(tank.id, value),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: SensorCard(
                              icon: Icons.thermostat,
                              title: '온도',
                              value: '${tank.temperature}',
                              unit: '°C',
                              isAlert: isTempAlert,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SensorCard(
                              icon: Icons.bubble_chart,
                              title: '용존산소량',
                              value: '${tank.oxygen}',
                              unit: 'mg/L',
                              isAlert: isOxygenAlert,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: SensorCard(
                              icon: Icons.science,
                              title: '염도',
                              value: '${tank.salt}',
                              unit: '',
                              isAlert: isSaltAlert,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SensorCard(
                              icon: Icons.water_drop,
                              title: '탁도',
                              value: '${tank.turbidity}',
                              unit: 'NTU',
                              isAlert: isTurbidityAlert,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: statusData.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (statusData.icon != null)
                      Icon(statusData.icon, color: Colors.red[800], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      statusData.message,
                      style: TextStyle(
                        color: statusData.icon != null
                            ? Colors.red[900]
                            : Colors.green[900],
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (statusData.icon != null)
                      Icon(statusData.icon, color: Colors.red[800], size: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _TankStatusViewData _resolveStatusData(TankProvider provider, dynamic tank) {
    // 수조별 개별 임계값 조회
    final List<double> temperatureThreshold = provider.getThreshold(
      tank.id,
      'temperature',
    );
    final List<double> oxygenThreshold = provider.getThreshold(
      tank.id,
      'oxygen',
    );
    final List<double> saltThreshold = provider.getThreshold(tank.id, 'salt');
    final List<double> turbidityThreshold = provider.getThreshold(
      tank.id,
      'turbidity',
    );

    if (tank.turbidity < turbidityThreshold[0] ||
        tank.turbidity > turbidityThreshold[1]) {
      return const _TankStatusViewData.alert('탁도 이상 감지');
    }

    if (tank.temperature < temperatureThreshold[0] ||
        tank.temperature > temperatureThreshold[1]) {
      return const _TankStatusViewData.alert('수온 이상 감지');
    }

    if (tank.salt < saltThreshold[0] || tank.salt > saltThreshold[1]) {
      return const _TankStatusViewData.alert('염도 이상 감지');
    }

    if (tank.oxygen < oxygenThreshold[0] || tank.oxygen > oxygenThreshold[1]) {
      return const _TankStatusViewData.alert('용존산소량 이상 감지');
    }

    return const _TankStatusViewData.normal('정상');
  }
}

class _TankStatusViewData {
  final String message;
  final Color backgroundColor;
  final IconData? icon;

  const _TankStatusViewData._({
    required this.message,
    required this.backgroundColor,
    required this.icon,
  });

  const _TankStatusViewData.normal(String message)
    : this._(
        message: message,
        backgroundColor: const Color(0xFFC8E6C9),
        icon: null,
      );

  const _TankStatusViewData.alert(String message)
    : this._(
        message: message,
        backgroundColor: const Color(0xFFFFCDD2),
        icon: Icons.warning,
      );
}

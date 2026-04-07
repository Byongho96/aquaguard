import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/tank_provider.dart';
import '../widgets/header.dart';
import '../widgets/sensor_graph_card.dart';

class DetailPage extends StatefulWidget {
  final String tankId;
  final int tankIndex;

  const DetailPage({Key? key, required this.tankId, required this.tankIndex})
    : super(key: key);

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  String _selectedSensor = 'temperature';

  static const Map<String, Map<String, dynamic>> _sensorMeta =
      <String, Map<String, dynamic>>{
        'temperature': <String, dynamic>{
          'title': '온도',
          'unit': '°C',
          'icon': Icons.thermostat,
        },
        'oxygen': <String, dynamic>{
          'title': '용존산소량',
          'unit': 'mg/L',
          'icon': Icons.bubble_chart,
        },
        'salt': <String, dynamic>{
          'title': '염도',
          'unit': '',
          'icon': Icons.science,
        },
        'turbidity': <String, dynamic>{
          'title': '탁도',
          'unit': 'NTU',
          'icon': Icons.water_drop,
        },
      };

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TankProvider>().startDetailView(widget.tankId);
    });
  }

  @override
  void dispose() {
    context.read<TankProvider>().stopDetailView();
    super.dispose();
  }

  void _showEditNameDialog(BuildContext context, TankProvider provider) {
    final TextEditingController controller = TextEditingController(
      text: provider.getTankName(widget.tankId, widget.tankIndex),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          '수조 이름 변경',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(fontSize: 20),
          decoration: const InputDecoration(hintText: "새 이름 입력"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소', style: TextStyle(fontSize: 18)),
          ),
          ElevatedButton(
            onPressed: () {
              provider.updateTankName(widget.tankId, controller.text);
              Navigator.pop(context);
            },
            child: const Text('저장', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }

  void _showEditThresholdDialog(
    BuildContext context,
    TankProvider provider,
    String title,
    String key,
    String unit,
  ) {
    // 개별 수조 임계값 로드
    final List<double> currentThreshold = provider.getThreshold(
      widget.tankId,
      key,
    );
    final TextEditingController minController = TextEditingController(
      text: currentThreshold[0].toString(),
    );
    final TextEditingController maxController = TextEditingController(
      text: currentThreshold[1].toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '$title 정상 범위 설정',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        contentPadding: const EdgeInsets.all(24),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: TextField(
                controller: minController,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  labelText: '최소값',
                  labelStyle: const TextStyle(fontSize: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '~',
                style: TextStyle(fontSize: 28, color: Colors.grey),
              ),
            ),
            Expanded(
              child: TextField(
                controller: maxController,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  labelText: '최대값',
                  labelStyle: const TextStyle(fontSize: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 12),
              Text(
                unit,
                style: const TextStyle(fontSize: 22, color: Colors.black87),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('취소', style: TextStyle(fontSize: 18)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              try {
                await provider.updateThreshold(
                  widget.tankId,
                  key,
                  double.tryParse(minController.text) ?? 0.0,
                  double.tryParse(maxController.text) ?? 100.0,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('범위 저장에 실패했습니다.')),
                  );
                }
              }
            },
            child: const Text(
              '저장',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _selectAndEdit(TankProvider provider, String sensorKey) {
    setState(() {
      _selectedSensor = sensorKey;
    });

    final Map<String, dynamic> sensorMeta = _sensorMeta[sensorKey]!;
    _showEditThresholdDialog(
      context,
      provider,
      sensorMeta['title'],
      sensorKey,
      sensorMeta['unit'],
    );
  }

  Future<void> _toggleSensorControl(
    TankProvider provider,
    String sensorKey,
    bool value,
  ) async {
    try {
      await provider.toggleSensorControl(widget.tankId, sensorKey, value);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('자동제어 상태 저장에 실패했습니다.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final TankProvider provider = context.watch<TankProvider>();
    final tank = provider.tanks.firstWhere((t) => t.id == widget.tankId);
    final String tankName = provider.getTankName(
      widget.tankId,
      widget.tankIndex,
    );
    final history = provider.getHistory(tank.id);

    // 수조별 임계값 맵 구성
    final Map<String, List<double>> thresholds = <String, List<double>>{
      'temperature': provider.getThreshold(widget.tankId, 'temperature'),
      'oxygen': provider.getThreshold(widget.tankId, 'oxygen'),
      'salt': provider.getThreshold(widget.tankId, 'salt'),
      'turbidity': provider.getThreshold(widget.tankId, 'turbidity'),
    };

    final Map<String, dynamic> currentMeta = _sensorMeta[_selectedSensor]!;
    final List<double> currentThreshold = thresholds[_selectedSensor]!;

    final List<double> tempTh = thresholds['temperature']!;
    final List<double> oxyTh = thresholds['oxygen']!;
    final List<double> saltTh = thresholds['salt']!;
    final List<double> turbTh = thresholds['turbidity']!;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 32.0,
                vertical: 24.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => _showEditNameDialog(context, provider),
                      child: Row(
                        children: [
                          Text(
                            '[ $tankName ]',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.edit, size: 20, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                  const AppHeader(),
                ],
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: SensorGraphCard(
                              minThreshold: tempTh[0],
                              maxThreshold: tempTh[1],
                              icon: Icons.thermostat,
                              title: '온도',
                              value: '${tank.temperature}',
                              unit: '°C',
                              isAlert:
                                  tank.temperature < tempTh[0] ||
                                  tank.temperature > tempTh[1],
                              historyData: history?.temperature ?? [],
                              onTap: () =>
                                  _selectAndEdit(provider, 'temperature'),
                              controlLabel: '냉각기',
                              controlValue: provider.getSensorControlState(
                                widget.tankId,
                                'temperature',
                              ),
                              onControlChanged: (value) => _toggleSensorControl(
                                provider,
                                'temperature',
                                value,
                              ),
                              controlEnabled: !tank.isAiControlled,
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: SensorGraphCard(
                              minThreshold: oxyTh[0],
                              maxThreshold: oxyTh[1],
                              icon: Icons.bubble_chart,
                              title: '용존산소량',
                              value: '${tank.oxygen}',
                              unit: 'mg/L',
                              isAlert:
                                  tank.oxygen < oxyTh[0] ||
                                  tank.oxygen > oxyTh[1],
                              historyData: history?.oxygen ?? [],
                              onTap: () => _selectAndEdit(provider, 'oxygen'),
                              controlLabel: '공기펌프',
                              controlValue: provider.getSensorControlState(
                                widget.tankId,
                                'oxygen',
                              ),
                              onControlChanged: (value) => _toggleSensorControl(
                                provider,
                                'oxygen',
                                value,
                              ),
                              controlEnabled: !tank.isAiControlled,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: SensorGraphCard(
                              minThreshold: saltTh[0],
                              maxThreshold: saltTh[1],
                              icon: Icons.science,
                              title: '염도',
                              value: '${tank.salt}',
                              unit: '',
                              isAlert:
                                  tank.salt < saltTh[0] ||
                                  tank.salt > saltTh[1],
                              historyData: history?.salt ?? [],
                              onTap: () => _selectAndEdit(provider, 'salt'),
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: SensorGraphCard(
                              minThreshold: turbTh[0],
                              maxThreshold: turbTh[1],
                              icon: Icons.water_drop,
                              title: '탁도',
                              value: '${tank.turbidity}',
                              unit: 'NTU',
                              isAlert:
                                  tank.turbidity < turbTh[0] ||
                                  tank.turbidity > turbTh[1],
                              historyData: history?.turbidity ?? [],
                              onTap: () =>
                                  _selectAndEdit(provider, 'turbidity'),
                              controlLabel: '물펌프',
                              controlValue: provider.getSensorControlState(
                                widget.tankId,
                                'turbidity',
                              ),
                              onControlChanged: (value) => _toggleSensorControl(
                                provider,
                                'turbidity',
                                value,
                              ),
                              controlEnabled: !tank.isAiControlled,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // 선택 센서의 임계값 편집 버튼
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                vertical: 20.0,
                horizontal: 32.0,
              ),
              child: Center(
                child: Material(
                  color: const Color(0xFFF0F4F8),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _showEditThresholdDialog(
                      context,
                      provider,
                      currentMeta['title'],
                      _selectedSensor,
                      currentMeta['unit'],
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blue.shade200,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            currentMeta['icon'],
                            color: Colors.blueGrey[700],
                            size: 32,
                          ),
                          const SizedBox(width: 16),
                          Text(
                            '${currentMeta['title']} : ',
                            style: const TextStyle(
                              fontSize: 24,
                              color: Colors.black54,
                            ),
                          ),
                          Text(
                            '[ ${currentThreshold[0]} ~ ${currentThreshold[1]} ] ${currentMeta['unit']}',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.home),
                        Text('메인', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  ...provider.tanks.asMap().entries.map((entry) {
                    final int idx = entry.key + 1;
                    final String tId = entry.value.id;
                    final bool isSelected = tId == widget.tankId;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: InkWell(
                        onTap: () {
                          if (!isSelected) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    DetailPage(tankId: tId, tankIndex: idx),
                              ),
                            );
                          }
                        },
                        child: Text(
                          '[ ${provider.getTankName(tId, idx)} ]',
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: isSelected ? 18 : 16,
                            color: isSelected ? Colors.black : Colors.grey,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                  const Spacer(),
                  Row(
                    children: [
                      const Text('AI자동제어  ', style: TextStyle(fontSize: 14)),
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
            ),
          ],
        ),
      ),
    );
  }
}

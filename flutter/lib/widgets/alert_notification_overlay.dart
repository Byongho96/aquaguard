import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/alert_model.dart';
import '../providers/tank_provider.dart';
import '../views/detail_page.dart';

/// 앱 전체에 겹쳐 표시되는 이상 알림 오버레이.
/// MaterialApp.builder 에서 감싸서 사용합니다.
class AlertNotificationOverlay extends StatelessWidget {
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  const AlertNotificationOverlay({
    Key? key,
    required this.child,
    required this.navigatorKey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<TankAlert> alerts = context.watch<TankProvider>().pendingAlerts;

    return Stack(
      children: [
        child,
        if (alerts.isNotEmpty)
          Positioned(
            right: 16,
            top: 0,
            bottom: 0,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: alerts
                    .map(
                      (alert) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: _AlertCard(
                          alert: alert,
                          onViewDetail: () => _navigateToDetail(context, alert),
                          onDismiss: () => context
                              .read<TankProvider>()
                              .dismissAlert(alert.key),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
      ],
    );
  }

  void _navigateToDetail(BuildContext context, TankAlert alert) {
    final TankProvider provider = context.read<TankProvider>();
    final int tankIndex = provider.tanks.indexWhere(
      (t) => t.id == alert.tankId,
    );
    if (tankIndex == -1) return;

    // 알림 닫기 후 상세 페이지로 이동
    provider.dismissAlert(alert.key);

    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) =>
            DetailPage(tankId: alert.tankId, tankIndex: tankIndex + 1),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final TankAlert alert;
  final VoidCallback onViewDetail;
  final VoidCallback onDismiss;

  const _AlertCard({
    Key? key,
    required this.alert,
    required this.onViewDetail,
    required this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isCritical = alert.severity == AlertSeverity.critical;
    final TankProvider provider = context.read<TankProvider>();
    final int tankIndex = provider.tanks.indexWhere(
      (t) => t.id == alert.tankId,
    );
    final String tankName = provider.getTankName(
      alert.tankId,
      tankIndex == -1 ? 0 : tankIndex + 1,
    );

    final Color bgColor = isCritical
        ? const Color(0xFFFFE0E0)
        : const Color(0xFFFFF9C4);
    final Color iconColor = isCritical ? Colors.red : Colors.amber.shade700;
    final String alertEmoji = isCritical ? '🚨' : '⚠️';

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 280,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 상단 버튼 행: 자세히 보기 / 닫기
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: onViewDetail,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.open_in_new, size: 14, color: iconColor),
                      const SizedBox(width: 4),
                      Text(
                        '자세히 보기',
                        style: TextStyle(fontSize: 12, color: iconColor),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onDismiss,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.close, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 2),
                      Text(
                        '닫기',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // 수조 이름
            Center(
              child: Text(
                '[ $tankName ]',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // 이상 메시지
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(alertEmoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  alert.message,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 6),
                Text(alertEmoji, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

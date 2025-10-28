import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sonar_provider.dart';

class StatusDashboard extends StatelessWidget {
  const StatusDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SonarProvider>(
      builder: (context, provider, child) {
        final data = provider.currentData;
        final connState = provider.connectionState;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.dashboard, size: 20),
                    SizedBox(width: 8),
                    Text(
                      '실시간 센서 상태',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _buildStatusRow(
                  '연결',
                  connState.isConnected ? '● 정상' : '○ 연결 끊김',
                  connState.isConnected ? Colors.green : Colors.red,
                ),
                const SizedBox(height: 12),
                _buildStatusRow(
                  '물 감지',
                  data?.waterStatusText ?? 'N/A',
                  data?.inWater == true ? Colors.blue : Colors.grey,
                ),
                const SizedBox(height: 12),
                _buildStatusRow(
                  '수온',
                  data?.waterTemp != null
                      ? '${data!.waterTemp!.toStringAsFixed(1)} °C'
                      : 'N/A',
                  Colors.orange,
                ),
                const SizedBox(height: 12),
                _buildStatusRow(
                  '스캔 깊이',
                  data?.scanDepth != null
                      ? '${data!.scanDepth!.toStringAsFixed(2)} m'
                      : 'N/A',
                  Colors.purple,
                  bold: true,
                ),
                const SizedBox(height: 12),
                _buildStatusRow(
                  '주파수',
                  data?.frequencyText ?? 'N/A',
                  Colors.indigo,
                ),
                const SizedBox(height: 12),
                _buildStatusRow(
                  '배터리',
                  data != null
                      ? '${data.batteryPercent}% (${data.batteryStatusText})'
                      : 'N/A',
                  _getBatteryColor(data?.batteryPercent ?? 0),
                ),
                const Divider(height: 24),
                Text(
                  '마지막 업데이트: ${connState.lastUpdateText ?? "없음"}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusRow(String label, String value, Color color,
      {bool bold = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              fontSize: bold ? 16 : 14,
            ),
          ),
        ),
      ],
    );
  }

  Color _getBatteryColor(int percent) {
    if (percent > 60) return Colors.green;
    if (percent > 20) return Colors.orange;
    return Colors.red;
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sonar_provider.dart';
import 'dart:math' as math;

class StatisticsDashboard extends StatelessWidget {
  const StatisticsDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SonarProvider>(
      builder: (context, provider, child) {
        final history = provider.dataHistory;

        if (history.isEmpty) {
          return const Card(
            child: Center(
              child: Text('데이터 수집 중...'),
            ),
          );
        }

        // 통계 계산
        final stats = _calculateStatistics(history);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.analytics, size: 20),
                      SizedBox(width: 8),
                      Text(
                        '세션 통계',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  _buildStatRow('총 데이터 포인트', '${history.length}개', Icons.data_usage),
                  _buildStatRow('물 속 시간', '${stats['inWaterCount']}개', Icons.water_drop),
                  const SizedBox(height: 16),

                  if (stats['avgTemp'] != null) ...[
                    const Text(
                      '수온 통계',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _buildStatRow('평균', '${stats['avgTemp']}°C', Icons.thermostat),
                    _buildStatRow('최저', '${stats['minTemp']}°C', Icons.ac_unit),
                    _buildStatRow('최고', '${stats['maxTemp']}°C', Icons.local_fire_department),
                    const SizedBox(height: 16),
                  ],

                  if (stats['avgDepth'] != null) ...[
                    const Text(
                      '깊이 통계',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _buildStatRow('평균', '${stats['avgDepth']}m', Icons.trending_flat),
                    _buildStatRow('최소', '${stats['minDepth']}m', Icons.trending_down),
                    _buildStatRow('최대', '${stats['maxDepth']}m', Icons.trending_up),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Map<String, dynamic> _calculateStatistics(List<dynamic> history) {
    final temps = history
        .where((d) => d.waterTemp != null)
        .map((d) => d.waterTemp as double)
        .toList();

    final depths = history
        .where((d) => d.scanDepth != null)
        .map((d) => d.scanDepth as double)
        .toList();

    final inWaterCount = history.where((d) => d.inWater).length;

    return {
      'inWaterCount': inWaterCount,
      'avgTemp': temps.isNotEmpty
          ? (temps.reduce((a, b) => a + b) / temps.length).toStringAsFixed(1)
          : null,
      'minTemp': temps.isNotEmpty
          ? temps.reduce(math.min).toStringAsFixed(1)
          : null,
      'maxTemp': temps.isNotEmpty
          ? temps.reduce(math.max).toStringAsFixed(1)
          : null,
      'avgDepth': depths.isNotEmpty
          ? (depths.reduce((a, b) => a + b) / depths.length).toStringAsFixed(2)
          : null,
      'minDepth': depths.isNotEmpty
          ? depths.reduce(math.min).toStringAsFixed(2)
          : null,
      'maxDepth': depths.isNotEmpty
          ? depths.reduce(math.max).toStringAsFixed(2)
          : null,
    };
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}

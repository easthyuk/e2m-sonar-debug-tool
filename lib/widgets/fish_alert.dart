import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sonar_provider.dart';
import '../services/fish_detector.dart';

class FishAlert extends StatefulWidget {
  const FishAlert({super.key});

  @override
  State<FishAlert> createState() => _FishAlertState();
}

class _FishAlertState extends State<FishAlert> {
  FishDetection? _lastDetection;
  bool _enabled = false; // 기본값을 false로 변경 (비활성화)
  DateTime? _lastAlertTime;

  @override
  Widget build(BuildContext context) {
    if (!_enabled) return const SizedBox.shrink();

    return Consumer<SonarProvider>(
      builder: (context, provider, child) {
        final data = provider.currentData;

        if (data != null && data.inWater) {
          final detection = FishDetector.detect(data);

          if (detection != null &&
              detection.confidence > 0.7 && // 신뢰도 높임
              _shouldShowAlert(detection)) {
            _lastDetection = detection;
            _lastAlertTime = DateTime.now();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _showFishAlert(context, detection);
              }
            });
          }
        }

        // 투명한 위젯 반환 (오버레이 전용)
        return const SizedBox.shrink();
      },
    );
  }

  bool _shouldShowAlert(FishDetection detection) {
    // 같은 깊이의 어군은 10초에 한 번만 알림
    if (_lastDetection != null && _lastAlertTime != null) {
      final timeDiff = DateTime.now().difference(_lastAlertTime!);
      final depthDiff = (detection.depth - _lastDetection!.depth).abs();

      if (timeDiff.inSeconds < 10 && depthDiff < 1.0) {
        return false;
      }
    }
    return true;
  }

  Widget _buildDetectionInfo(FishDetection detection) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.location_on, size: 16, color: Colors.green),
            const SizedBox(width: 8),
            Text(
              '깊이: ${detection.depth.toStringAsFixed(1)}m',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.signal_cellular_alt, size: 16, color: Colors.blue),
            const SizedBox(width: 8),
            Text('신호 강도: ${detection.strengthText}'),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.check_circle, size: 16, color: Colors.orange),
            const SizedBox(width: 8),
            Text('신뢰도: ${detection.confidenceText} (${(detection.confidence * 100).toInt()}%)'),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '감지 시간: ${detection.timestamp.hour.toString().padLeft(2, '0')}:${detection.timestamp.minute.toString().padLeft(2, '0')}:${detection.timestamp.second.toString().padLeft(2, '0')}',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  void _showFishAlert(BuildContext context, FishDetection detection) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.catching_pokemon, color: Colors.green),
            SizedBox(width: 8),
            Text('어군 감지!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '깊이: ${detection.depth.toStringAsFixed(1)}m',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('신호 강도: ${detection.strengthText}'),
            Text('신뢰도: ${detection.confidenceText}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}

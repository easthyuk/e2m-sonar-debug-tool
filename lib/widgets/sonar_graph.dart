import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/sonar_data.dart';

/// Sonar 데이터 그래프 (Deeper 스타일)
class SonarGraph extends StatefulWidget {
  final List<SonarData> dataHistory;
  final int maxHistoryCount;

  const SonarGraph({
    super.key,
    required this.dataHistory,
    this.maxHistoryCount = 100,
  });

  @override
  State<SonarGraph> createState() => _SonarGraphState();
}

class _SonarGraphState extends State<SonarGraph> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.waves, size: 20),
                SizedBox(width: 8),
                Text(
                  'Sonar 시각화',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: widget.dataHistory.isEmpty
                  ? const Center(
                      child: Text(
                        '스캔 데이터를 기다리는 중...',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : CustomPaint(
                      painter: SonarPainter(
                        dataHistory: widget.dataHistory,
                        maxHistoryCount: widget.maxHistoryCount,
                      ),
                      size: Size.infinite,
                    ),
            ),
            const SizedBox(height: 16),
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildLegendItem('표면', Colors.blue[100]!),
        _buildLegendItem('어군', Colors.yellow),
        _buildLegendItem('강한 신호', Colors.orange),
        _buildLegendItem('바닥', Colors.red),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Colors.black26),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class SonarPainter extends CustomPainter {
  final List<SonarData> dataHistory;
  final int maxHistoryCount;

  SonarPainter({
    required this.dataHistory,
    required this.maxHistoryCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dataHistory.isEmpty) return;

    // 배경
    final bgPaint = Paint()..color = Colors.black87;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 그리드 그리기
    _drawGrid(canvas, size);

    // 데이터 그리기 (오른쪽에서 왼쪽으로 스크롤)
    final columnWidth = size.width / maxHistoryCount;
    final startIndex = math.max(0, dataHistory.length - maxHistoryCount);

    for (int i = startIndex; i < dataHistory.length; i++) {
      final data = dataHistory[i];
      final x = (i - startIndex) * columnWidth;

      if (data.sonarSamples != null && data.scanDepth != null) {
        _drawSonarColumn(canvas, size, x, columnWidth, data);
      }
    }

    // 깊이 라벨
    _drawDepthLabels(canvas, size);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 1;

    // 수평 그리드 (깊이 구간)
    for (int i = 0; i <= 10; i++) {
      final y = size.height * i / 10;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    // 수직 그리드 (시간 구간)
    for (int i = 0; i <= 10; i++) {
      final x = size.width * i / 10;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        gridPaint,
      );
    }
  }

  void _drawSonarColumn(
    Canvas canvas,
    Size size,
    double x,
    double columnWidth,
    SonarData data,
  ) {
    final samples = data.sonarSamples!;
    final scanDepth = data.scanDepth!;

    for (int i = 0; i < samples.length; i++) {
      final value = samples[i];
      if (value == 0) continue; // 신호 없음

      // 깊이 계산
      final depth = (i / samples.length) * scanDepth;
      final y = (depth / scanDepth) * size.height;

      // 신호 강도에 따른 색상
      final color = _getColorForSignal(value);

      final paint = Paint()..color = color;

      // 픽셀 그리기
      canvas.drawRect(
        Rect.fromLTWH(x, y, columnWidth, size.height / samples.length),
        paint,
      );
    }
  }

  Color _getColorForSignal(int value) {
    if (value == 0x0F) {
      // 바닥 확정
      return Colors.red;
    } else if (value >= 0x0A) {
      // 강한 신호
      return Colors.orange;
    } else if (value >= 0x05) {
      // 중간 신호 (어군 가능성)
      return Colors.yellow;
    } else {
      // 약한 신호
      return Colors.blue[100]!;
    }
  }

  void _drawDepthLabels(Canvas canvas, Size size) {
    if (dataHistory.isEmpty || dataHistory.last.scanDepth == null) return;

    final maxDepth = dataHistory.last.scanDepth!;
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // 5개 구간 라벨
    for (int i = 0; i <= 5; i++) {
      final depth = (maxDepth * i / 5);
      final y = size.height * i / 5;

      textPainter.text = TextSpan(
        text: '${depth.toStringAsFixed(1)}m',
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 10,
        ),
      );

      textPainter.layout();
      textPainter.paint(canvas, Offset(5, y - 5));
    }
  }

  @override
  bool shouldRepaint(SonarPainter oldDelegate) {
    return oldDelegate.dataHistory.length != dataHistory.length;
  }
}

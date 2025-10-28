import '../models/sonar_data.dart';

/// 어군 자동 감지 알고리즘
class FishDetector {
  static const int minSignalStrength = 0x05; // 최소 신호 강도
  static const int minClusterSize = 3; // 최소 클러스터 크기
  static const double depthMargin = 2.0; // 바닥 마진 (m)

  /// 어군 감지
  static FishDetection? detect(SonarData data) {
    if (!data.inWater || data.sonarSamples == null || data.scanDepth == null) {
      return null;
    }

    final samples = data.sonarSamples!;
    final scanDepth = data.scanDepth!;

    // 바닥 위치 찾기
    final bottomIndex = _findBottom(samples);

    // 어군 클러스터 찾기
    final clusters = _findClusters(samples, bottomIndex, scanDepth);

    if (clusters.isEmpty) {
      return null;
    }

    // 가장 강한 클러스터 선택
    clusters.sort((a, b) => b.strength.compareTo(a.strength));

    return FishDetection(
      depth: clusters.first.depth,
      strength: clusters.first.strength,
      size: clusters.first.size,
      confidence: _calculateConfidence(clusters.first, samples),
      timestamp: data.timestamp,
    );
  }

  /// 바닥 위치 찾기
  static int _findBottom(List<int> samples) {
    for (int i = samples.length - 1; i >= 0; i--) {
      if (samples[i] == 0x0F) {
        return i;
      }
    }
    return samples.length - 1;
  }

  /// 어군 클러스터 찾기
  static List<FishCluster> _findClusters(
    List<int> samples,
    int bottomIndex,
    double scanDepth,
  ) {
    final clusters = <FishCluster>[];
    int clusterStart = -1;
    int clusterEnd = -1;
    int maxStrength = 0;

    for (int i = 0; i < bottomIndex - 2; i++) {
      final value = samples[i];

      if (value >= minSignalStrength && value < 0x0F) {
        if (clusterStart == -1) {
          clusterStart = i;
        }
        clusterEnd = i;
        if (value > maxStrength) {
          maxStrength = value;
        }
      } else {
        if (clusterStart != -1) {
          final size = clusterEnd - clusterStart + 1;
          if (size >= minClusterSize) {
            final depth = (clusterStart + clusterEnd) / 2 / samples.length * scanDepth;
            clusters.add(FishCluster(
              depth: depth,
              strength: maxStrength,
              size: size,
            ));
          }
          clusterStart = -1;
          clusterEnd = -1;
          maxStrength = 0;
        }
      }
    }

    return clusters;
  }

  /// 신뢰도 계산
  static double _calculateConfidence(FishCluster cluster, List<int> samples) {
    double confidence = 0.0;

    // 신호 강도 (0.0 ~ 0.5)
    confidence += (cluster.strength / 0x0E) * 0.5;

    // 클러스터 크기 (0.0 ~ 0.3)
    confidence += (cluster.size / 10.0).clamp(0.0, 1.0) * 0.3;

    // 안정성 (0.0 ~ 0.2)
    confidence += 0.2; // 기본 안정성

    return confidence.clamp(0.0, 1.0);
  }
}

class FishCluster {
  final double depth;
  final int strength;
  final int size;

  FishCluster({
    required this.depth,
    required this.strength,
    required this.size,
  });
}

class FishDetection {
  final double depth;
  final int strength;
  final int size;
  final double confidence;
  final DateTime timestamp;

  FishDetection({
    required this.depth,
    required this.strength,
    required this.size,
    required this.confidence,
    required this.timestamp,
  });

  String get confidenceText {
    if (confidence > 0.8) return '높음';
    if (confidence > 0.5) return '중간';
    return '낮음';
  }

  String get strengthText {
    if (strength > 0x0C) return '매우 강함';
    if (strength > 0x08) return '강함';
    if (strength > 0x05) return '중간';
    return '약함';
  }

  @override
  String toString() {
    return 'Fish detected at ${depth.toStringAsFixed(1)}m '
        '(Strength: $strengthText, Confidence: ${(confidence * 100).toInt()}%)';
  }
}

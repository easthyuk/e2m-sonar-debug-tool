class SonarData {
  final bool inWater;              // 물 감지
  final double? waterTemp;         // 수온 (°C)
  final double? scanDepth;         // 스캔 깊이 (m)
  final int? frequency;            // 주파수 (1/2/3)
  final int batteryPercent;        // 배터리 (%)
  final int batteryStatus;         // 충전 상태 (0:idle, 1:charging, 2:full)
  final List<int>? sonarSamples;   // 초음파 데이터 (90 bytes)
  final String? gpsData;           // GPS NMEA
  final DateTime timestamp;        // 수신 시간

  SonarData({
    required this.inWater,
    this.waterTemp,
    this.scanDepth,
    this.frequency,
    required this.batteryPercent,
    required this.batteryStatus,
    this.sonarSamples,
    this.gpsData,
    required this.timestamp,
  });

  String get batteryStatusText {
    switch (batteryStatus) {
      case 0:
        return 'idle';
      case 1:
        return '충전중';
      case 2:
        return '완충';
      default:
        return 'unknown';
    }
  }

  String get frequencyText {
    switch (frequency) {
      case 1:
        return '675 kHz';
      case 2:
        return '270 kHz';
      case 3:
        return '100 kHz';
      default:
        return 'N/A';
    }
  }

  String get waterStatusText => inWater ? 'IN WATER (물 속)' : 'OUT OF WATER (물 밖)';

  @override
  String toString() {
    return 'SonarData(inWater: $inWater, waterTemp: $waterTemp, scanDepth: $scanDepth, '
        'frequency: $frequency, battery: $batteryPercent%, status: $batteryStatusText)';
  }
}

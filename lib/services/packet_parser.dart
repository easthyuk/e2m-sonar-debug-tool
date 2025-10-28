import 'dart:typed_data';
import '../models/sonar_data.dart';

class PacketParser {
  // 마지막 배터리 정보 캐싱 (물 밖 패킷에서만 업데이트)
  static int _lastBatteryPercent = 0;
  static int _lastBatteryStatus = 0;

  /// 패킷 파싱 (Big Endian!)
  static SonarData? parse(Uint8List packet) {
    if (packet.length == 7) {
      return _parseOutOfWater(packet);
    } else if (packet.length == 182) {
      return _parseInWater(packet);
    }
    return null;
  }

  /// 물 밖 패킷 파싱 (7 bytes)
  static SonarData _parseOutOfWater(Uint8List packet) {
    // 배터리 정보 캐싱 (물 속에서도 사용하기 위해)
    _lastBatteryPercent = packet[3];
    _lastBatteryStatus = packet[4];

    return SonarData(
      inWater: packet[2] == 1,
      batteryPercent: _lastBatteryPercent,
      batteryStatus: _lastBatteryStatus,
      timestamp: DateTime.now(),
    );
  }

  /// 물 속 패킷 파싱 (182 bytes)
  static SonarData _parseInWater(Uint8List packet) {
    return SonarData(
      inWater: packet[2] == 1,
      waterTemp: _parseFloat(packet, 3, Endian.big),
      gpsData: _parseGpsData(packet.sublist(7, 87)),
      frequency: packet[87],
      scanDepth: _parseFloat(packet, 88, Endian.big), // ⭐ 스캔 깊이!
      sonarSamples: packet.sublist(92, 182).toList(),
      // 물 속 패킷에는 배터리 정보 없음 → 마지막 물 밖 패킷의 값 사용
      batteryPercent: _lastBatteryPercent,
      batteryStatus: _lastBatteryStatus,
      timestamp: DateTime.now(),
    );
  }

  /// Float 파싱 (Big Endian!)
  static double _parseFloat(Uint8List data, int offset, Endian endian) {
    final bytes = data.sublist(offset, offset + 4);
    return bytes.buffer.asByteData().getFloat32(0, endian);
  }

  /// GPS 데이터 파싱 (ASCII NMEA)
  static String _parseGpsData(Uint8List data) {
    try {
      final str = String.fromCharCodes(data);
      // null 문자 제거
      return str.replaceAll('\x00', '').trim();
    } catch (e) {
      return '';
    }
  }

  /// 패킷 정보 텍스트 생성
  static String getPacketInfo(Uint8List packet) {
    if (packet.length == 7) {
      final batteryPercent = packet[3];
      final batteryStatus = _batteryStatusText(packet[4]);
      return '물 밖, 배터리 $batteryPercent%, $batteryStatus';
    } else if (packet.length == 182) {
      final temp = _parseFloat(packet, 3, Endian.big);
      final depth = _parseFloat(packet, 88, Endian.big);
      final freq = _frequencyText(packet[87]);
      return '물 속, ${temp.toStringAsFixed(1)}°C, 스캔깊이 ${depth.toStringAsFixed(2)}m, $freq';
    }
    return 'Unknown packet (${packet.length} bytes)';
  }

  static String _batteryStatusText(int status) {
    switch (status) {
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

  static String _frequencyText(int freq) {
    switch (freq) {
      case 1:
        return '675kHz';
      case 2:
        return '270kHz';
      case 3:
        return '100kHz';
      default:
        return 'unknown';
    }
  }
}

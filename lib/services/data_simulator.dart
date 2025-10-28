import 'dart:typed_data';
import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/foundation.dart';

/// 실제 하드웨어 없이 테스트할 수 있는 데이터 시뮬레이터
class DataSimulator {
  final math.Random _random = math.Random();
  Timer? _timer;

  // 시뮬레이션 상태
  bool _isInWater = false;
  double _waterTemp = 20.0;
  double _scanDepth = 1.2; // 90cm 물통 시뮬레이션 (바닥 0.9m + 여유 0.3m)
  int _frequency = 1; // 675kHz
  int _batteryPercent = 85;
  int _batteryStatus = 0; // idle
  double _latitude = 37.5440; // 서울 성수동
  double _longitude = 127.0557;
  int _scanRate = 5; // 5Hz
  int _packetCount = 0; // 배터리 감소 타이밍용

  final StreamController<Uint8List> _packetController =
      StreamController<Uint8List>.broadcast();

  Stream<Uint8List> get packetStream => _packetController.stream;

  /// 시뮬레이션 시작
  void start({int scanRateHz = 5}) {
    _scanRate = scanRateHz;
    _isInWater = false;

    _timer = Timer.periodic(
      Duration(milliseconds: 1000 ~/ _scanRate),
      (timer) {
        if (_isInWater) {
          _packetController.add(_generateInWaterPacket());
        } else {
          _packetController.add(_generateOutOfWaterPacket());
        }
      },
    );
  }

  /// 시뮬레이션 중지
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// 물 속 상태로 전환
  void enterWater() {
    _isInWater = true;
    if (kDebugMode) print('[Simulator] Entered water');
  }

  /// 물 밖 상태로 전환
  void exitWater() {
    _isInWater = false;
    if (kDebugMode) print('[Simulator] Exited water');
  }

  /// 주파수 변경
  void setFrequency(int freq) {
    _frequency = freq;
    if (kDebugMode) print('[Simulator] Frequency set to: ${_getFreqText(freq)}');
  }

  /// 스캔 주기 변경
  void setScanRate(int rate) {
    _scanRate = rate;
    stop();
    start(scanRateHz: rate);
    if (kDebugMode) print('[Simulator] Scan rate set to: ${rate}Hz');
  }

  /// 최대 깊이 변경
  void setDepthRange(int depth) {
    _scanDepth = depth.toDouble();
    if (kDebugMode) print('[Simulator] Depth range set to: ${depth}m');
  }

  /// 물 밖 패킷 생성 (7 bytes)
  Uint8List _generateOutOfWaterPacket() {
    final packet = Uint8List(7);

    // Frame Length (Little Endian)
    packet[0] = 0x03;
    packet[1] = 0x00;

    // water_detect = 0 (물 밖)
    packet[2] = 0x00;

    // battery_percent (매우 천천히 감소 - 약 5분마다 1%)
    _packetCount++;
    if (_packetCount >= 300) { // 5Hz * 60초 = 300 패킷 = 1분마다
      _packetCount = 0;
      _batteryPercent = (_batteryPercent - 0.2).clamp(0, 100).toInt();
    }
    packet[3] = _batteryPercent;

    // battery_status (거의 idle 유지)
    if (_batteryPercent < 20) {
      _batteryStatus = 0; // idle (저전력)
    } else if (_random.nextDouble() > 0.99) {
      _batteryStatus = (_batteryStatus + 1) % 3; // 아주 가끔 변경
    }
    packet[4] = _batteryStatus;

    // CRLF
    packet[5] = 0x0D;
    packet[6] = 0x0A;

    return packet;
  }

  /// 물 속 패킷 생성 (182 bytes)
  Uint8List _generateInWaterPacket() {
    final packet = Uint8List(182);

    // Frame Length (Little Endian)
    packet[0] = 0xB4; // 180
    packet[1] = 0x00;

    // water_detect = 1 (물 속)
    packet[2] = 0x01;

    // water_temp (4 bytes, float, Big Endian)
    _waterTemp += (_random.nextDouble() - 0.5) * 0.2;
    _waterTemp = _waterTemp.clamp(15.0, 30.0);
    _writeFloat(packet, 3, _waterTemp);

    // GPS data (80 bytes, NMEA)
    _generateGPSData(packet, 7);

    // frequency
    packet[87] = _frequency;

    // water_depth (4 bytes, float, Big Endian)
    // 90cm 물통 시뮬레이션: 0.8~1.3m 범위로 약간 흔들림
    _scanDepth += (_random.nextDouble() - 0.5) * 0.05;
    _scanDepth = _scanDepth.clamp(0.8, 1.3);
    _writeFloat(packet, 88, _scanDepth);

    // sonar_samples (90 bytes)
    _generateSonarSamples(packet, 92);

    return packet;
  }

  /// Float를 Big Endian으로 쓰기
  void _writeFloat(Uint8List data, int offset, double value) {
    final byteData = ByteData(4);
    byteData.setFloat32(0, value, Endian.big);
    for (int i = 0; i < 4; i++) {
      data[offset + i] = byteData.getUint8(i);
    }
  }

  /// GPS 데이터 생성 (NMEA GNRMC)
  void _generateGPSData(Uint8List packet, int offset) {
    // 위도/경도 조금씩 변경 (이동 시뮬레이션)
    _latitude += (_random.nextDouble() - 0.5) * 0.0001;
    _longitude += (_random.nextDouble() - 0.5) * 0.0001;

    // NMEA GNRMC 형식 생성
    final latDeg = _latitude.abs().floor();
    final latMin = (_latitude.abs() - latDeg) * 60;
    final latDir = _latitude >= 0 ? 'N' : 'S';

    final lonDeg = _longitude.abs().floor();
    final lonMin = (_longitude.abs() - lonDeg) * 60;
    final lonDir = _longitude >= 0 ? 'E' : 'W';

    final speed = _random.nextDouble() * 10; // knots
    final course = _random.nextDouble() * 360; // degrees

    final nmea = '\$GNRMC,123519,A,'
        '${latDeg.toString().padLeft(2, '0')}${latMin.toStringAsFixed(3)},${latDir},'
        '${lonDeg.toString().padLeft(3, '0')}${lonMin.toStringAsFixed(3)},${lonDir},'
        '${speed.toStringAsFixed(1)},${course.toStringAsFixed(1)},'
        '270125,003.1,W*6A';

    // ASCII로 변환하여 패킷에 쓰기
    final bytes = nmea.codeUnits;
    for (int i = 0; i < 80 && i < bytes.length; i++) {
      packet[offset + i] = bytes[i];
    }
  }

  /// Sonar 샘플 생성 (90 bytes)
  void _generateSonarSamples(Uint8List packet, int offset) {
    // 바닥 위치 (90개 샘플 중)
    final bottomIndex = (_scanDepth / 1.2 * 90).clamp(10, 89).toInt();

    // 어군 시뮬레이션 (랜덤 위치)
    final fishSchoolDepth = _random.nextInt(bottomIndex - 10) + 5;
    final fishSchoolSize = _random.nextInt(10) + 5;

    for (int i = 0; i < 90; i++) {
      int value = 0x00; // 기본: 신호 없음

      // 표면 노이즈
      if (i < 3 && _random.nextDouble() > 0.7) {
        value = _random.nextInt(3) + 1;
      }

      // 어군 시뮬레이션
      if ((i - fishSchoolDepth).abs() < fishSchoolSize / 2) {
        final distance = (i - fishSchoolDepth).abs();
        final intensity = ((fishSchoolSize / 2 - distance) / (fishSchoolSize / 2) * 10).toInt();
        value = intensity.clamp(0x05, 0x0D);
      }

      // 바닥 근처
      if ((i - bottomIndex).abs() < 2) {
        value = 0x0C + _random.nextInt(3);
      }

      // 바닥 확정
      if (i == bottomIndex) {
        value = 0x0F;
      }

      // 바닥 이후는 신호 없음
      if (i > bottomIndex) {
        value = 0x00;
      }

      packet[offset + i] = value;
    }
  }

  String _getFreqText(int freq) {
    switch (freq) {
      case 1: return '675kHz';
      case 2: return '270kHz';
      case 3: return '100kHz';
      default: return 'unknown';
    }
  }

  void dispose() {
    stop();
    _packetController.close();
  }
}

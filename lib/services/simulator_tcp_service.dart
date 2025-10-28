import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../models/sonar_data.dart';
import '../models/packet_log.dart';
import 'packet_parser.dart';
import 'command_builder.dart';
import 'data_simulator.dart';

/// 시뮬레이터를 사용하는 TCP 서비스 (하드웨어 없이 테스트용)
class SimulatorTCPService {
  final DataSimulator _simulator = DataSimulator();

  final StreamController<SonarData> _dataController =
      StreamController<SonarData>.broadcast();
  final StreamController<PacketLog> _logController =
      StreamController<PacketLog>.broadcast();
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  Stream<SonarData> get dataStream => _dataController.stream;
  Stream<PacketLog> get logStream => _logController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  String host = '192.168.4.1 (Simulator)';
  int port = 36001;

  /// 시뮬레이터 연결 (즉시 연결)
  Future<bool> connect() async {
    if (kDebugMode) print('[Simulator] Connecting...');

    await Future.delayed(const Duration(milliseconds: 500));

    _isConnected = true;
    _connectionController.add(true);

    // 시뮬레이터 시작
    _simulator.start(scanRateHz: 5);

    // 패킷 수신 시작
    _simulator.packetStream.listen((packet) {
      _processPacket(packet);
    });

    // 물 밖 상태로 시작 (사용자가 "스캔 시작" 버튼을 눌러야 물 속 진입)
    _simulator.exitWater();

    if (kDebugMode) print('[Simulator] Connected! (물 밖 상태)');
    return true;
  }

  /// 연결 해제
  void disconnect() {
    _simulator.stop();
    _isConnected = false;
    _connectionController.add(false);
    if (kDebugMode) print('[Simulator] Disconnected');
  }

  /// 패킷 처리
  void _processPacket(Uint8List packet) {
    // 로그 추가
    final log = PacketLog(
      direction: PacketDirection.rx,
      rawData: packet,
      hexString: packet.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' '),
      parsedInfo: PacketParser.getPacketInfo(packet),
      timestamp: DateTime.now(),
    );
    _logController.add(log);

    // 데이터 파싱
    final sonarData = PacketParser.parse(packet);
    if (sonarData != null) {
      _dataController.add(sonarData);
    }
  }

  /// 명령 전송 (시뮬레이터에 반영)
  Future<bool> sendCommand(int cmdId, int param) async {
    if (!_isConnected) {
      if (kDebugMode) print('[Simulator] Cannot send command: not connected');
      return false;
    }

    try {
      final packet = CommandBuilder.build(cmdId, param);

      // 로그 추가
      final log = PacketLog(
        direction: PacketDirection.tx,
        rawData: packet,
        hexString: packet.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' '),
        parsedInfo: CommandBuilder.getCommandInfo(cmdId, param),
        timestamp: DateTime.now(),
      );
      _logController.add(log);

      // 시뮬레이터에 명령 적용
      _applyCommand(cmdId, param);

      if (kDebugMode) print('[Simulator] Sent command: ${CommandBuilder.getCommandInfo(cmdId, param)}');
      return true;
    } catch (e) {
      if (kDebugMode) print('[Simulator] Failed to send command: $e');
      return false;
    }
  }

  /// 명령을 시뮬레이터에 적용
  void _applyCommand(int cmdId, int param) {
    switch (cmdId) {
      case 0x01: // SET_MODE
        // 모드 변경은 시뮬레이터에 영향 없음
        break;
      case 0x02: // SET_FREQUENCY
        _simulator.setFrequency(param);
        break;
      case 0x03: // SET_SCAN_RATE
        _simulator.setScanRate(param);
        break;
      case 0x04: // SET_DEPTH_RANGE
        _simulator.setDepthRange(param);
        break;
      case 0x05: // SCAN_CONTROL
        if (param == 1) {
          _simulator.enterWater();
        } else {
          _simulator.exitWater();
        }
        break;
    }
  }

  /// 리소스 정리
  void dispose() {
    disconnect();
    _simulator.dispose();
    _dataController.close();
    _logController.close();
    _connectionController.close();
  }
}

import 'dart:io';
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/sonar_data.dart';
import '../models/packet_log.dart';
import 'packet_parser.dart';
import 'command_builder.dart';

class TCPService {
  Socket? _socket;
  final StreamController<SonarData> _dataController =
      StreamController<SonarData>.broadcast();
  final StreamController<PacketLog> _logController =
      StreamController<PacketLog>.broadcast();
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  Stream<SonarData> get dataStream => _dataController.stream;
  Stream<PacketLog> get logStream => _logController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;

  final List<int> _buffer = [];
  bool _isConnected = false;
  Timer? _reconnectTimer;

  String host = '192.168.4.1';
  int port = 36001;

  bool get isConnected => _isConnected;

  /// TCP 연결
  Future<bool> connect() async {
    try {
      if (kDebugMode) print('Connecting to $host:$port...');
      _socket = await Socket.connect(host, port,
          timeout: const Duration(seconds: 5));

      _isConnected = true;
      _connectionController.add(true);

      _socket!.listen(
        _handleIncomingData,
        onError: (error) {
          if (kDebugMode) print('Socket error: $error');
          _handleDisconnection();
        },
        onDone: () {
          if (kDebugMode) print('Socket closed');
          _handleDisconnection();
        },
        cancelOnError: false,
      );

      if (kDebugMode) print('Connected successfully!');
      return true;
    } catch (e) {
      if (kDebugMode) print('Connection failed: $e');
      _isConnected = false;
      _connectionController.add(false);
      return false;
    }
  }

  /// 연결 해제 처리
  void _handleDisconnection() {
    _isConnected = false;
    _connectionController.add(false);
    _socket?.destroy();
    _socket = null;
    _buffer.clear();
  }

  /// 연결 해제
  void disconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _handleDisconnection();
  }

  /// 자동 재연결 시작
  void startAutoReconnect({Duration interval = const Duration(seconds: 3)}) {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer.periodic(interval, (timer) async {
      if (!_isConnected) {
        if (kDebugMode) print('Attempting to reconnect...');
        await connect();
      }
    });
  }

  /// 자동 재연결 중지
  void stopAutoReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  /// 수신 데이터 처리
  void _handleIncomingData(Uint8List data) {
    _buffer.addAll(data);
    _processBuffer();
  }

  /// 버퍼 처리 (패킷 경계 검출)
  void _processBuffer() {
    while (_buffer.length >= 2) {
      // Frame Length 읽기 (Little Endian)
      int frameLen = _buffer[0] | (_buffer[1] << 8);
      int totalLen = frameLen + 2; // Frame Length 자체 포함

      // 물 밖 패킷은 CRLF 추가 (7 bytes 총)
      if (frameLen == 3 && _buffer.length >= 7) {
        if (_buffer[5] == 0x0D && _buffer[6] == 0x0A) {
          totalLen = 7; // Frame(2) + Data(3) + CRLF(2)
        }
      }

      // 패킷 완성 확인
      if (_buffer.length >= totalLen) {
        final packet = Uint8List.fromList(_buffer.sublist(0, totalLen));
        _processPacket(packet);
        _buffer.removeRange(0, totalLen);
      } else {
        break; // 더 많은 데이터 대기
      }
    }
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

  /// 명령 전송 (Little Endian Parameter)
  Future<bool> sendCommand(int cmdId, int param) async {
    if (_socket == null || !_isConnected) {
      if (kDebugMode) print('Cannot send command: not connected');
      return false;
    }

    try {
      final packet = CommandBuilder.build(cmdId, param);

      _socket!.add(packet);
      await _socket!.flush();

      // 로그 추가
      final log = PacketLog(
        direction: PacketDirection.tx,
        rawData: packet,
        hexString: packet.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' '),
        parsedInfo: CommandBuilder.getCommandInfo(cmdId, param),
        timestamp: DateTime.now(),
      );
      _logController.add(log);

      if (kDebugMode) print('Sent command (LE): ${CommandBuilder.getCommandInfo(cmdId, param)}');
      return true;
    } catch (e) {
      if (kDebugMode) print('Failed to send command: $e');

      // 에러 로그
      _logController.add(PacketLog(
        direction: PacketDirection.tx,
        rawData: Uint8List(0),
        hexString: '',
        parsedInfo: 'Error: $e',
        timestamp: DateTime.now(),
        isError: true,
      ));

      return false;
    }
  }

  /// 명령 전송 (Big Endian Parameter) - 테스트용
  Future<bool> sendCommandBigEndian(int cmdId, int param) async {
    if (_socket == null || !_isConnected) {
      if (kDebugMode) print('Cannot send command: not connected');
      return false;
    }

    try {
      final packet = CommandBuilder.buildBigEndian(cmdId, param);

      _socket!.add(packet);
      await _socket!.flush();

      // 로그 추가
      final log = PacketLog(
        direction: PacketDirection.tx,
        rawData: packet,
        hexString: packet.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' '),
        parsedInfo: '${CommandBuilder.getCommandInfo(cmdId, param)} [Big Endian]',
        timestamp: DateTime.now(),
      );
      _logController.add(log);

      if (kDebugMode) print('Sent command (BE): ${CommandBuilder.getCommandInfo(cmdId, param)}');
      return true;
    } catch (e) {
      if (kDebugMode) print('Failed to send command: $e');

      // 에러 로그
      _logController.add(PacketLog(
        direction: PacketDirection.tx,
        rawData: Uint8List(0),
        hexString: '',
        parsedInfo: 'Error: $e',
        timestamp: DateTime.now(),
        isError: true,
      ));

      return false;
    }
  }

  /// 명령 전송 (CRLF 추가) - 테스트용
  Future<bool> sendCommandWithCRLF(int cmdId, int param) async {
    if (_socket == null || !_isConnected) return false;
    try {
      final packet = CommandBuilder.buildWithCRLF(cmdId, param);
      _socket!.add(packet);
      await _socket!.flush();
      _logController.add(PacketLog(
        direction: PacketDirection.tx,
        rawData: packet,
        hexString: packet.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' '),
        parsedInfo: '${CommandBuilder.getCommandInfo(cmdId, param)} [+CRLF]',
        timestamp: DateTime.now(),
      ));
      return true;
    } catch (e) {
      _logController.add(PacketLog(
        direction: PacketDirection.tx,
        rawData: Uint8List(0),
        hexString: '',
        parsedInfo: 'Error: $e',
        timestamp: DateTime.now(),
        isError: true,
      ));
      return false;
    }
  }

  /// 명령 전송 (LF 추가) - 테스트용
  Future<bool> sendCommandWithLF(int cmdId, int param) async {
    if (_socket == null || !_isConnected) return false;
    try {
      final packet = CommandBuilder.buildWithLF(cmdId, param);
      _socket!.add(packet);
      await _socket!.flush();
      _logController.add(PacketLog(
        direction: PacketDirection.tx,
        rawData: packet,
        hexString: packet.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' '),
        parsedInfo: '${CommandBuilder.getCommandInfo(cmdId, param)} [+LF]',
        timestamp: DateTime.now(),
      ));
      return true;
    } catch (e) {
      _logController.add(PacketLog(
        direction: PacketDirection.tx,
        rawData: Uint8List(0),
        hexString: '',
        parsedInfo: 'Error: $e',
        timestamp: DateTime.now(),
        isError: true,
      ));
      return false;
    }
  }

  /// 명령 전송 (XOR 체크섬) - 테스트용
  Future<bool> sendCommandWithChecksum(int cmdId, int param) async {
    if (_socket == null || !_isConnected) return false;
    try {
      final packet = CommandBuilder.buildWithChecksum(cmdId, param);
      _socket!.add(packet);
      await _socket!.flush();
      _logController.add(PacketLog(
        direction: PacketDirection.tx,
        rawData: packet,
        hexString: packet.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' '),
        parsedInfo: '${CommandBuilder.getCommandInfo(cmdId, param)} [+XOR]',
        timestamp: DateTime.now(),
      ));
      return true;
    } catch (e) {
      _logController.add(PacketLog(
        direction: PacketDirection.tx,
        rawData: Uint8List(0),
        hexString: '',
        parsedInfo: 'Error: $e',
        timestamp: DateTime.now(),
        isError: true,
      ));
      return false;
    }
  }

  /// 명령 전송 (SUM 체크섬) - 테스트용
  Future<bool> sendCommandWithSumChecksum(int cmdId, int param) async {
    if (_socket == null || !_isConnected) return false;
    try {
      final packet = CommandBuilder.buildWithSumChecksum(cmdId, param);
      _socket!.add(packet);
      await _socket!.flush();
      _logController.add(PacketLog(
        direction: PacketDirection.tx,
        rawData: packet,
        hexString: packet.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' '),
        parsedInfo: '${CommandBuilder.getCommandInfo(cmdId, param)} [+SUM]',
        timestamp: DateTime.now(),
      ));
      return true;
    } catch (e) {
      _logController.add(PacketLog(
        direction: PacketDirection.tx,
        rawData: Uint8List(0),
        hexString: '',
        parsedInfo: 'Error: $e',
        timestamp: DateTime.now(),
        isError: true,
      ));
      return false;
    }
  }

  /// 명령 시퀀스 전송 - 초기화 명령 시퀀스 테스트용
  /// 하드웨어가 특정 순서의 명령을 기대할 수 있음
  Future<bool> sendCommandSequence(List<Map<String, dynamic>> sequence, {Duration delay = const Duration(milliseconds: 500)}) async {
    if (_socket == null || !_isConnected) return false;

    try {
      for (var i = 0; i < sequence.length; i++) {
        final cmd = sequence[i];
        final cmdId = cmd['cmdId'] as int;
        final param = cmd['param'] as int;
        final mode = cmd['mode'] as String? ?? 'normal';

        // 모드에 따라 다른 방식으로 전송
        bool success = false;
        switch (mode) {
          case 'big_endian':
            success = await sendCommandBigEndian(cmdId, param);
            break;
          case 'crlf':
            success = await sendCommandWithCRLF(cmdId, param);
            break;
          case 'lf':
            success = await sendCommandWithLF(cmdId, param);
            break;
          case 'xor':
            success = await sendCommandWithChecksum(cmdId, param);
            break;
          case 'sum':
            success = await sendCommandWithSumChecksum(cmdId, param);
            break;
          default:
            success = await sendCommand(cmdId, param);
        }

        if (!success) return false;

        // 마지막 명령이 아니면 딜레이
        if (i < sequence.length - 1) {
          await Future.delayed(delay);
        }
      }

      return true;
    } catch (e) {
      if (kDebugMode) print('Failed to send command sequence: $e');
      return false;
    }
  }

  /// 리소스 정리
  void dispose() {
    stopAutoReconnect();
    disconnect();
    _dataController.close();
    _logController.close();
    _connectionController.close();
  }
}

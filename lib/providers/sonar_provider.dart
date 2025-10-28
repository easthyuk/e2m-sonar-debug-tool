import 'package:flutter/foundation.dart';
import '../models/sonar_data.dart';
import '../models/packet_log.dart';
import '../models/connection_state.dart' as conn_state;
import '../services/tcp_service.dart';
import '../services/simulator_tcp_service.dart';
import '../services/settings_service.dart';
import '../services/command_builder.dart';
import '../services/export_service.dart';

class SonarProvider extends ChangeNotifier {
  dynamic _tcpService; // TCPService or SimulatorTCPService
  final ExportService _exportService = ExportService();
  final SettingsService _settingsService = SettingsService();
  bool _useSimulator = false;

  SonarData? _currentData;
  final List<PacketLog> _logs = [];
  final List<SonarData> _dataHistory = []; // 데이터 히스토리 추가
  conn_state.ConnectionState _connectionState = conn_state.ConnectionState(
    isConnected: false,
    host: '192.168.4.1',
    port: 36001,
  );

  String? _lastCommandStatus;
  String? _lastError;
  bool _useBigEndianCommands = false; // Big Endian 명령 테스트 플래그 (토글 가능)

  // 고급 테스트 모드
  String _testMode = 'normal'; // normal, big_endian, crlf, lf, xor, sum

  // Getters
  SonarData? get currentData => _currentData;
  List<PacketLog> get logs => List.unmodifiable(_logs);
  List<SonarData> get dataHistory => List.unmodifiable(_dataHistory); // 히스토리 getter
  conn_state.ConnectionState get connectionState => _connectionState;
  String? get lastCommandStatus => _lastCommandStatus;
  String? get lastError => _lastError;
  bool get useBigEndianCommands => _useBigEndianCommands;
  String get testMode => _testMode;

  SonarProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    // 설정 로드
    _useSimulator = await _settingsService.loadUseSimulator();
    final host = await _settingsService.loadHost();
    final port = await _settingsService.loadPort();

    // 시뮬레이터 또는 실제 TCP 서비스 선택
    if (_useSimulator) {
      _tcpService = SimulatorTCPService();
      if (kDebugMode) print('[Provider] Using Simulator mode');
    } else {
      _tcpService = TCPService()
        ..host = host
        ..port = port;
      if (kDebugMode) print('[Provider] Using Real TCP mode: $host:$port');
    }

    _setupStreams();
  }

  void _setupStreams() {
    // 데이터 스트림 구독
    _tcpService.dataStream.listen((data) {
      _currentData = data;

      // 물 속 데이터만 히스토리에 추가
      if (data.inWater && data.sonarSamples != null) {
        _dataHistory.add(data);

        // 메모리 관리: 최대 200개 유지
        if (_dataHistory.length > 200) {
          _dataHistory.removeRange(0, 100);
        }
      }

      _updateConnectionStats(received: true);
      notifyListeners();
    });

    // 로그 스트림 구독
    _tcpService.logStream.listen((log) {
      _logs.add(log);

      // 메모리 관리: 최대 1000개 로그 유지
      if (_logs.length > 1000) {
        _logs.removeRange(0, 500);
      }

      // 송신/수신 카운터 업데이트
      if (log.direction == PacketDirection.rx) {
        _updateConnectionStats(received: true);
      } else {
        _updateConnectionStats(sent: true);
      }

      if (log.isError) {
        _updateConnectionStats(error: true);
      }

      notifyListeners();
    });

    // 연결 상태 스트림 구독
    _tcpService.connectionStream.listen((isConnected) {
      _connectionState = _connectionState.copyWith(
        isConnected: isConnected,
      );
      notifyListeners();
    });
  }

  void _updateConnectionStats({
    bool received = false,
    bool sent = false,
    bool error = false,
  }) {
    _connectionState = _connectionState.copyWith(
      receivedPackets:
          received ? _connectionState.receivedPackets + 1 : _connectionState.receivedPackets,
      sentPackets: sent ? _connectionState.sentPackets + 1 : _connectionState.sentPackets,
      errorCount: error ? _connectionState.errorCount + 1 : _connectionState.errorCount,
      lastReceivedTime: received ? DateTime.now() : _connectionState.lastReceivedTime,
    );
  }

  // 연결 관련
  Future<void> connect() async {
    final success = await _tcpService.connect();
    if (success) {
      _lastCommandStatus = '연결 성공';
      _tcpService.startAutoReconnect();
    } else {
      _lastCommandStatus = '연결 실패';
    }
    notifyListeners();
  }

  void disconnect() {
    _tcpService.disconnect();
    _lastCommandStatus = '연결 해제됨';
    notifyListeners();
  }

  // Big Endian 모드 토글 (하위 호환성 유지)
  void toggleBigEndianMode() {
    _useBigEndianCommands = !_useBigEndianCommands;
    _testMode = _useBigEndianCommands ? 'big_endian' : 'normal';
    _lastCommandStatus = _useBigEndianCommands
        ? '⚠️ Big Endian 모드 활성화 (테스트용)'
        : 'Little Endian 모드 (기본)';
    notifyListeners();
  }

  // 고급 테스트 모드 변경
  void setTestMode(String mode) {
    _testMode = mode;
    _useBigEndianCommands = (mode == 'big_endian'); // 기존 토글과 동기화

    final modeNames = {
      'normal': '기본 (4 bytes)',
      'big_endian': 'Big Endian (5 bytes)',
      'crlf': 'CRLF 추가 (6 bytes)',
      'lf': 'LF 추가 (5 bytes)',
      'xor': 'XOR 체크섬 (5 bytes)',
      'sum': 'SUM 체크섬 (5 bytes)',
    };

    _lastCommandStatus = '테스트 모드: ${modeNames[mode] ?? mode}';
    notifyListeners();
  }

  // 명령 전송 헬퍼 (테스트 모드에 따라 자동 선택)
  Future<bool> _sendCommand(int cmdId, int param) async {
    switch (_testMode) {
      case 'big_endian':
        return await _tcpService.sendCommandBigEndian(cmdId, param);
      case 'crlf':
        return await _tcpService.sendCommandWithCRLF(cmdId, param);
      case 'lf':
        return await _tcpService.sendCommandWithLF(cmdId, param);
      case 'xor':
        return await _tcpService.sendCommandWithChecksum(cmdId, param);
      case 'sum':
        return await _tcpService.sendCommandWithSumChecksum(cmdId, param);
      default:
        return await _tcpService.sendCommand(cmdId, param);
    }
  }

  // 초기화 시퀀스 테스트 - 패턴 1: 모드 → 주파수 → 스캔주기
  Future<void> testInitSequence1() async {
    _lastCommandStatus = '초기화 시퀀스 1 시작 (모드→주파수→주기)...';
    notifyListeners();

    final sequence = [
      {'cmdId': SonarCommand.setMode, 'param': FishingMode.boat, 'mode': _testMode},
      {'cmdId': SonarCommand.setFrequency, 'param': Frequency.freq270, 'mode': _testMode},
      {'cmdId': SonarCommand.setScanRate, 'param': 10, 'mode': _testMode},
    ];

    final success = await _tcpService.sendCommandSequence(sequence, delay: const Duration(seconds: 2));
    _lastCommandStatus = success
        ? '✅ 초기화 시퀀스 1 완료 (6초 소요)'
        : '❌ 초기화 시퀀스 1 실패';
    notifyListeners();
  }

  // 초기화 시퀀스 테스트 - 패턴 2: SCAN OFF → 설정 → SCAN ON
  Future<void> testInitSequence2() async {
    _lastCommandStatus = '초기화 시퀀스 2 시작 (OFF→설정→ON)...';
    notifyListeners();

    final sequence = [
      {'cmdId': SonarCommand.scanControl, 'param': 2, 'mode': _testMode}, // OFF
      {'cmdId': SonarCommand.setFrequency, 'param': Frequency.freq270, 'mode': _testMode},
      {'cmdId': SonarCommand.scanControl, 'param': 1, 'mode': _testMode}, // ON
    ];

    final success = await _tcpService.sendCommandSequence(sequence, delay: const Duration(seconds: 2));
    _lastCommandStatus = success
        ? '✅ 초기화 시퀀스 2 완료 (6초 소요)'
        : '❌ 초기화 시퀀스 2 실패';
    notifyListeners();
  }

  // 초기화 시퀀스 테스트 - 패턴 3: 모든 설정 순차 전송
  Future<void> testInitSequence3() async {
    _lastCommandStatus = '초기화 시퀀스 3 시작 (전체 설정)...';
    notifyListeners();

    final sequence = [
      {'cmdId': SonarCommand.setMode, 'param': FishingMode.boat, 'mode': _testMode},
      {'cmdId': SonarCommand.setFrequency, 'param': Frequency.freq270, 'mode': _testMode},
      {'cmdId': SonarCommand.setScanRate, 'param': 10, 'mode': _testMode},
      {'cmdId': SonarCommand.setDepthRange, 'param': 50, 'mode': _testMode},
      {'cmdId': SonarCommand.scanControl, 'param': 1, 'mode': _testMode},
    ];

    final success = await _tcpService.sendCommandSequence(sequence, delay: const Duration(seconds: 1));
    _lastCommandStatus = success
        ? '✅ 초기화 시퀀스 3 완료 (5초 소요)'
        : '❌ 초기화 시퀀스 3 실패';
    notifyListeners();
  }

  // 빠른 테스트 - 모든 모드로 단일 명령 전송
  Future<void> quickTestAllModes(int cmdId, int param) async {
    _lastCommandStatus = '전체 모드 테스트 시작...';
    notifyListeners();

    final modes = ['normal', 'big_endian', 'crlf', 'lf', 'xor', 'sum'];

    for (var mode in modes) {
      final originalMode = _testMode;
      _testMode = mode;

      await _sendCommand(cmdId, param);
      await Future.delayed(const Duration(seconds: 1));

      _testMode = originalMode;
    }

    _lastCommandStatus = '✅ 전체 모드 테스트 완료 (6가지 방식)';
    notifyListeners();
  }

  // 명령 전송
  Future<void> setMode(int mode) async {
    final success = await _sendCommand(SonarCommand.setMode, mode);
    _lastCommandStatus = success
        ? '모드 변경 성공: ${_getModeText(mode)}'
        : '모드 변경 실패';
    notifyListeners();
  }

  Future<void> setFrequency(int frequency) async {
    final success = await _sendCommand(SonarCommand.setFrequency, frequency);
    _lastCommandStatus = success
        ? '주파수 변경 성공: ${_getFrequencyText(frequency)}'
        : '주파수 변경 실패';
    notifyListeners();
  }

  Future<void> setScanRate(int rate) async {
    if (rate < 1 || rate > 15) {
      _lastCommandStatus = '스캔 주기는 1~15Hz 사이여야 합니다';
      notifyListeners();
      return;
    }

    final success = await _sendCommand(SonarCommand.setScanRate, rate);
    _lastCommandStatus =
        success ? '스캔 주기 변경 성공: ${rate}Hz' : '스캔 주기 변경 실패';
    notifyListeners();
  }

  Future<void> setDepthRange(int depth) async {
    if (depth < 1 || depth > 100) {
      _lastCommandStatus = '최대 깊이는 1~100m 사이여야 합니다';
      notifyListeners();
      return;
    }

    final success = await _sendCommand(SonarCommand.setDepthRange, depth);
    _lastCommandStatus =
        success ? '최대 깊이 설정 성공: ${depth}m' : '최대 깊이 설정 실패';
    notifyListeners();
  }

  Future<void> startScan() async {
    final success = await _sendCommand(SonarCommand.scanControl, 1);
    _lastCommandStatus = success ? '스캔 시작' : '스캔 시작 실패';
    notifyListeners();
  }

  Future<void> stopScan() async {
    final success = await _sendCommand(SonarCommand.scanControl, 2);
    _lastCommandStatus = success ? '스캔 정지' : '스캔 정지 실패';
    notifyListeners();
  }

  // 로그 관리
  void clearLogs() {
    _logs.clear();
    notifyListeners();
  }

  // 데이터 내보내기
  Future<String?> exportLogsToCSV() async {
    try {
      final path = await _exportService.exportLogsToCSV(_logs);
      if (path != null) {
        _lastCommandStatus = 'CSV 내보내기 성공: $path';
      } else {
        _lastCommandStatus = 'CSV 내보내기 실패';
      }
      notifyListeners();
      return path;
    } catch (e) {
      _lastError = e.toString();
      _lastCommandStatus = '내보내기 에러: $e';
      notifyListeners();
      return null;
    }
  }

  Future<String?> exportDataToJSON() async {
    try {
      final path = await _exportService.exportDataToJSON(_dataHistory);
      if (path != null) {
        _lastCommandStatus = 'JSON 내보내기 성공';
      } else {
        _lastCommandStatus = 'JSON 내보내기 실패';
      }
      notifyListeners();
      return path;
    } catch (e) {
      _lastError = e.toString();
      _lastCommandStatus = '내보내기 에러: $e';
      notifyListeners();
      return null;
    }
  }

  Future<String?> exportDataToCSV() async {
    try {
      final path = await _exportService.exportDataToCSV(_dataHistory);
      if (path != null) {
        _lastCommandStatus = 'CSV 내보내기 성공';
      } else {
        _lastCommandStatus = 'CSV 내보내기 실패';
      }
      notifyListeners();
      return path;
    } catch (e) {
      _lastError = e.toString();
      _lastCommandStatus = '내보내기 에러: $e';
      notifyListeners();
      return null;
    }
  }

  Future<String?> exportSessionReport() async {
    try {
      final path = await _exportService.exportSessionReport(_dataHistory, _logs);
      if (path != null) {
        _lastCommandStatus = '리포트 생성 성공';
      } else {
        _lastCommandStatus = '리포트 생성 실패';
      }
      notifyListeners();
      return path;
    } catch (e) {
      _lastError = e.toString();
      _lastCommandStatus = '리포트 에러: $e';
      notifyListeners();
      return null;
    }
  }

  String _getModeText(int mode) {
    switch (mode) {
      case FishingMode.shore:
        return '연안';
      case FishingMode.boat:
        return '보트';
      case FishingMode.ice:
        return '얼음';
      default:
        return 'unknown';
    }
  }

  String _getFrequencyText(int freq) {
    switch (freq) {
      case Frequency.freq675:
        return '675kHz';
      case Frequency.freq270:
        return '270kHz';
      case Frequency.freq100:
        return '100kHz';
      default:
        return 'unknown';
    }
  }

  @override
  void dispose() {
    _tcpService.dispose();
    super.dispose();
  }
}

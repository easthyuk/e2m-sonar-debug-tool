import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../models/packet_log.dart';

class LoggerService {
  File? _logFile;
  bool _isInitialized = false;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd_HH-mm-ss');
  final DateFormat _timestampFormat = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');

  /// 로거 초기화
  Future<void> initialize() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logDir = Directory('${directory.path}/sonar_logs');

      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }

      final timestamp = _dateFormat.format(DateTime.now());
      _logFile = File('${logDir.path}/sonar_log_$timestamp.txt');

      await _logFile!.writeAsString(
        '=== E2M Sonar Debug Tool Log ===\n'
        'Started at: ${_timestampFormat.format(DateTime.now())}\n'
        '================================\n\n',
      );

      _isInitialized = true;
      if (kDebugMode) print('Logger initialized: ${_logFile!.path}');
    } catch (e) {
      if (kDebugMode) print('Failed to initialize logger: $e');
      _isInitialized = false;
    }
  }

  /// 패킷 로그 저장
  Future<void> logPacket(PacketLog log) async {
    if (!_isInitialized || _logFile == null) return;

    try {
      final logText = StringBuffer();
      logText.writeln('${log.directionSymbol} ${log.timestampFormatted}');
      logText.writeln('Hex: ${log.formattedHex}');
      logText.writeln('Info: ${log.parsedInfo}');
      logText.writeln('---');

      await _logFile!.writeAsString(
        logText.toString(),
        mode: FileMode.append,
      );
    } catch (e) {
      if (kDebugMode) print('Failed to log packet: $e');
    }
  }

  /// 일반 메시지 로그
  Future<void> logMessage(String message, {String level = 'INFO'}) async {
    if (!_isInitialized || _logFile == null) return;

    try {
      final timestamp = _timestampFormat.format(DateTime.now());
      await _logFile!.writeAsString(
        '[$level] $timestamp - $message\n',
        mode: FileMode.append,
      );
    } catch (e) {
      if (kDebugMode) print('Failed to log message: $e');
    }
  }

  /// 에러 로그
  Future<void> logError(String error, [StackTrace? stackTrace]) async {
    await logMessage('ERROR: $error', level: 'ERROR');
    if (stackTrace != null) {
      await logMessage('StackTrace: $stackTrace', level: 'ERROR');
    }
  }

  /// 로그 파일 경로 가져오기
  String? get logFilePath => _logFile?.path;

  /// 로그 파일 닫기
  Future<void> close() async {
    if (_isInitialized && _logFile != null) {
      await _logFile!.writeAsString(
        '\n================================\n'
        'Closed at: ${_timestampFormat.format(DateTime.now())}\n'
        '================================\n',
        mode: FileMode.append,
      );
    }
  }
}

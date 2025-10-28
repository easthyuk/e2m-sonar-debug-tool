import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../models/sonar_data.dart';
import '../models/packet_log.dart';

class ExportService {
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd_HH-mm-ss');
  final DateFormat _timestampFormat = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');

  /// 패킷 로그를 CSV로 내보내기
  Future<String?> exportLogsToCSV(List<PacketLog> logs) async {
    if (logs.isEmpty) return null;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final exportDir = Directory('${directory.path}/sonar_exports');

      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }

      final timestamp = _dateFormat.format(DateTime.now());
      final file = File('${exportDir.path}/logs_$timestamp.csv');

      final buffer = StringBuffer();

      // CSV 헤더
      buffer.writeln('Direction,Timestamp,Hex Data,Parsed Info,Error');

      // 데이터 행
      for (final log in logs) {
        buffer.writeln(
          '${log.direction == PacketDirection.rx ? "RX" : "TX"},'
          '${_timestampFormat.format(log.timestamp)},'
          '"${log.formattedHex}",'
          '"${log.parsedInfo}",'
          '${log.isError}',
        );
      }

      await file.writeAsString(buffer.toString());
      if (kDebugMode) print('Exported logs to: ${file.path}');
      return file.path;
    } catch (e) {
      if (kDebugMode) print('Failed to export logs: $e');
      return null;
    }
  }

  /// Sonar 데이터를 JSON으로 내보내기
  Future<String?> exportDataToJSON(List<SonarData> dataHistory) async {
    if (dataHistory.isEmpty) return null;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final exportDir = Directory('${directory.path}/sonar_exports');

      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }

      final timestamp = _dateFormat.format(DateTime.now());
      final file = File('${exportDir.path}/sonar_data_$timestamp.json');

      final jsonData = dataHistory.map((data) {
        return {
          'timestamp': _timestampFormat.format(data.timestamp),
          'inWater': data.inWater,
          'waterTemp': data.waterTemp,
          'scanDepth': data.scanDepth,
          'frequency': data.frequency,
          'batteryPercent': data.batteryPercent,
          'batteryStatus': data.batteryStatus,
          'gpsData': data.gpsData,
          'sonarSamples': data.sonarSamples,
        };
      }).toList();

      final jsonString = const JsonEncoder.withIndent('  ').convert({
        'exportDate': DateTime.now().toIso8601String(),
        'deviceInfo': {
          'name': 'E2M Sonar',
          'ip': '192.168.4.1',
          'port': 36001,
        },
        'dataCount': dataHistory.length,
        'data': jsonData,
      });

      await file.writeAsString(jsonString);
      if (kDebugMode) print('Exported data to: ${file.path}');
      return file.path;
    } catch (e) {
      if (kDebugMode) print('Failed to export data: $e');
      return null;
    }
  }

  /// Sonar 데이터를 CSV로 내보내기 (간단한 형식)
  Future<String?> exportDataToCSV(List<SonarData> dataHistory) async {
    if (dataHistory.isEmpty) return null;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final exportDir = Directory('${directory.path}/sonar_exports');

      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }

      final timestamp = _dateFormat.format(DateTime.now());
      final file = File('${exportDir.path}/sonar_data_$timestamp.csv');

      final buffer = StringBuffer();

      // CSV 헤더
      buffer.writeln(
        'Timestamp,In Water,Water Temp (C),Scan Depth (m),Frequency,Battery (%),Battery Status,GPS Data',
      );

      // 데이터 행
      for (final data in dataHistory) {
        buffer.writeln(
          '${_timestampFormat.format(data.timestamp)},'
          '${data.inWater},'
          '${data.waterTemp ?? ""},'
          '${data.scanDepth ?? ""},'
          '${data.frequency ?? ""},'
          '${data.batteryPercent},'
          '${data.batteryStatus},'
          '"${data.gpsData ?? ""}"',
        );
      }

      await file.writeAsString(buffer.toString());
      if (kDebugMode) print('Exported data to: ${file.path}');
      return file.path;
    } catch (e) {
      if (kDebugMode) print('Failed to export data: $e');
      return null;
    }
  }

  /// 전체 세션 리포트 생성 (Markdown)
  Future<String?> exportSessionReport(
    List<SonarData> dataHistory,
    List<PacketLog> logs,
  ) async {
    if (dataHistory.isEmpty && logs.isEmpty) return null;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final exportDir = Directory('${directory.path}/sonar_exports');

      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }

      final timestamp = _dateFormat.format(DateTime.now());
      final file = File('${exportDir.path}/session_report_$timestamp.md');

      final buffer = StringBuffer();

      // 헤더
      buffer.writeln('# E2M Sonar Debug Tool - Session Report\n');
      buffer.writeln('Generated: ${DateTime.now()}\n');
      buffer.writeln('---\n');

      // 요약
      buffer.writeln('## Summary\n');
      buffer.writeln('- Total Data Points: ${dataHistory.length}');
      buffer.writeln('- Total Packets: ${logs.length}');
      buffer.writeln('- RX Packets: ${logs.where((l) => l.direction == PacketDirection.rx).length}');
      buffer.writeln('- TX Packets: ${logs.where((l) => l.direction == PacketDirection.tx).length}');
      buffer.writeln('- Errors: ${logs.where((l) => l.isError).length}\n');

      // 데이터 통계
      if (dataHistory.isNotEmpty) {
        buffer.writeln('## Data Statistics\n');

        final inWaterCount = dataHistory.where((d) => d.inWater).length;
        buffer.writeln('- In Water: $inWaterCount / ${dataHistory.length}');

        final temps = dataHistory
            .where((d) => d.waterTemp != null)
            .map((d) => d.waterTemp!)
            .toList();
        if (temps.isNotEmpty) {
          final avgTemp = temps.reduce((a, b) => a + b) / temps.length;
          final minTemp = temps.reduce((a, b) => a < b ? a : b);
          final maxTemp = temps.reduce((a, b) => a > b ? a : b);
          buffer.writeln('- Water Temp: Avg ${avgTemp.toStringAsFixed(1)}°C, '
              'Min ${minTemp.toStringAsFixed(1)}°C, Max ${maxTemp.toStringAsFixed(1)}°C');
        }

        final depths = dataHistory
            .where((d) => d.scanDepth != null)
            .map((d) => d.scanDepth!)
            .toList();
        if (depths.isNotEmpty) {
          final avgDepth = depths.reduce((a, b) => a + b) / depths.length;
          final minDepth = depths.reduce((a, b) => a < b ? a : b);
          final maxDepth = depths.reduce((a, b) => a > b ? a : b);
          buffer.writeln('- Scan Depth: Avg ${avgDepth.toStringAsFixed(2)}m, '
              'Min ${minDepth.toStringAsFixed(2)}m, Max ${maxDepth.toStringAsFixed(2)}m');
        }
        buffer.writeln();
      }

      // 최근 로그 (최대 50개)
      buffer.writeln('## Recent Logs (Last 50)\n');
      buffer.writeln('```');
      final recentLogs = logs.length > 50 ? logs.sublist(logs.length - 50) : logs;
      for (final log in recentLogs) {
        buffer.writeln('${log.directionSymbol} ${log.timestampFormatted}');
        buffer.writeln('  ${log.parsedInfo}');
      }
      buffer.writeln('```\n');

      await file.writeAsString(buffer.toString());
      if (kDebugMode) print('Exported report to: ${file.path}');
      return file.path;
    } catch (e) {
      if (kDebugMode) print('Failed to export report: $e');
      return null;
    }
  }
}

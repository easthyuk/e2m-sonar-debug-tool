import 'package:shared_preferences/shared_preferences.dart';

/// 설정 저장/불러오기 서비스
class SettingsService {
  static const String _keyHost = 'connection_host';
  static const String _keyPort = 'connection_port';
  static const String _keyAutoReconnect = 'auto_reconnect';
  static const String _keyEnableLogging = 'enable_logging';
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyUseSimulator = 'use_simulator';

  /// 호스트 저장
  Future<void> saveHost(String host) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyHost, host);
  }

  /// 호스트 불러오기
  Future<String> loadHost() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyHost) ?? '192.168.4.1';
  }

  /// 포트 저장
  Future<void> savePort(int port) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyPort, port);
  }

  /// 포트 불러오기
  Future<int> loadPort() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyPort) ?? 36001;
  }

  /// 자동 재연결 저장
  Future<void> saveAutoReconnect(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoReconnect, enabled);
  }

  /// 자동 재연결 불러오기
  Future<bool> loadAutoReconnect() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAutoReconnect) ?? true;
  }

  /// 로깅 활성화 저장
  Future<void> saveEnableLogging(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnableLogging, enabled);
  }

  /// 로깅 활성화 불러오기
  Future<bool> loadEnableLogging() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyEnableLogging) ?? true;
  }

  /// 테마 모드 저장 (0: system, 1: light, 2: dark)
  Future<void> saveThemeMode(int mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyThemeMode, mode);
  }

  /// 테마 모드 불러오기
  Future<int> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyThemeMode) ?? 0; // system
  }

  /// 시뮬레이터 사용 저장
  Future<void> saveUseSimulator(bool use) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyUseSimulator, use);
  }

  /// 시뮬레이터 사용 불러오기
  Future<bool> loadUseSimulator() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyUseSimulator) ?? false;
  }

  /// 모든 설정 초기화
  Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}

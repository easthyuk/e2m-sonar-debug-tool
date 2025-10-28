import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/settings_service.dart';

class SettingsScreenV2 extends StatefulWidget {
  const SettingsScreenV2({super.key});

  @override
  State<SettingsScreenV2> createState() => _SettingsScreenV2State();
}

class _SettingsScreenV2State extends State<SettingsScreenV2> {
  final SettingsService _settingsService = SettingsService();
  final TextEditingController _hostController = TextEditingController();
  final TextEditingController _portController = TextEditingController();

  bool _autoReconnect = true;
  bool _enableLogging = true;
  bool _useSimulator = false;
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final host = await _settingsService.loadHost();
    final port = await _settingsService.loadPort();
    final autoReconnect = await _settingsService.loadAutoReconnect();
    final enableLogging = await _settingsService.loadEnableLogging();
    final useSimulator = await _settingsService.loadUseSimulator();
    final themeModeIndex = await _settingsService.loadThemeMode();

    setState(() {
      _hostController.text = host;
      _portController.text = port.toString();
      _autoReconnect = autoReconnect;
      _enableLogging = enableLogging;
      _useSimulator = useSimulator;
      _themeMode = ThemeMode.values[themeModeIndex];
    });
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSection(
            '연결 설정',
            Icons.wifi,
            [
              TextField(
                controller: _hostController,
                decoration: const InputDecoration(
                  labelText: 'IP 주소',
                  hintText: '192.168.4.1',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _portController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '포트',
                  hintText: '36001',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('자동 재연결'),
                subtitle: const Text('연결이 끊어지면 자동으로 재연결'),
                value: _autoReconnect,
                onChanged: (value) {
                  setState(() => _autoReconnect = value);
                },
              ),
              SwitchListTile(
                title: const Text('시뮬레이터 사용'),
                subtitle: const Text('하드웨어 없이 데이터 시뮬레이션'),
                value: _useSimulator,
                onChanged: (value) {
                  setState(() => _useSimulator = value);
                },
              ),
            ],
          ),
          const Divider(height: 32),
          _buildSection(
            '테마 설정',
            Icons.palette,
            [
              // ignore: deprecated_member_use
              RadioListTile<ThemeMode>(
                title: const Text('시스템'),
                value: ThemeMode.system,
                groupValue: _themeMode,
                onChanged: (value) {
                  setState(() => _themeMode = value!);
                },
              ),
              // ignore: deprecated_member_use
              RadioListTile<ThemeMode>(
                title: const Text('라이트 모드'),
                value: ThemeMode.light,
                groupValue: _themeMode,
                onChanged: (value) {
                  setState(() => _themeMode = value!);
                },
              ),
              // ignore: deprecated_member_use
              RadioListTile<ThemeMode>(
                title: const Text('다크 모드'),
                value: ThemeMode.dark,
                groupValue: _themeMode,
                onChanged: (value) {
                  setState(() => _themeMode = value!);
                },
              ),
            ],
          ),
          const Divider(height: 32),
          _buildSection(
            '로깅 설정',
            Icons.description,
            [
              SwitchListTile(
                title: const Text('파일 로깅'),
                subtitle: const Text('패킷 로그를 파일에 저장'),
                value: _enableLogging,
                onChanged: (value) {
                  setState(() => _enableLogging = value);
                },
              ),
            ],
          ),
          const Divider(height: 32),
          _buildSection(
            '앱 정보',
            Icons.info,
            [
              const ListTile(
                leading: Icon(Icons.apps),
                title: Text('앱 이름'),
                subtitle: Text('E2M Sonar Debug Tool'),
              ),
              const ListTile(
                leading: Icon(Icons.tag),
                title: Text('버전'),
                subtitle: Text('2.0.0'),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _saveSettings,
                  icon: const Icon(Icons.save),
                  label: const Text('저장'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _resetSettings,
                  icon: const Icon(Icons.restore),
                  label: const Text('초기화'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }

  Future<void> _saveSettings() async {
    // 테마 프로바이더 미리 가져오기
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    await _settingsService.saveHost(_hostController.text);
    await _settingsService.savePort(int.tryParse(_portController.text) ?? 36001);
    await _settingsService.saveAutoReconnect(_autoReconnect);
    await _settingsService.saveEnableLogging(_enableLogging);
    await _settingsService.saveUseSimulator(_useSimulator);
    await _settingsService.saveThemeMode(_themeMode.index);

    // 테마 프로바이더 업데이트
    await themeProvider.setThemeMode(_themeMode);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('설정이 저장되었습니다'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _resetSettings() async {
    await _settingsService.resetAll();
    await _loadSettings();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('설정이 초기화되었습니다'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
}

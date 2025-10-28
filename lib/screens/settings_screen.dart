import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _hostController = TextEditingController(text: '192.168.4.1');
  final TextEditingController _portController = TextEditingController(text: '36001');
  bool _autoReconnect = true;
  bool _enableLogging = true;

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
        backgroundColor: Colors.blueGrey[800],
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 연결 설정
          _buildSection(
            '연결 설정',
            Icons.wifi,
            [
              _buildTextField(
                controller: _hostController,
                label: 'IP 주소',
                hint: '192.168.4.1',
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _portController,
                label: '포트',
                hint: '36001',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('자동 재연결'),
                subtitle: const Text('연결이 끊어지면 자동으로 재연결 시도'),
                value: _autoReconnect,
                onChanged: (value) {
                  setState(() => _autoReconnect = value);
                },
              ),
            ],
          ),

          const Divider(height: 32),

          // 로깅 설정
          _buildSection(
            '로깅 설정',
            Icons.description,
            [
              SwitchListTile(
                title: const Text('파일 로깅 활성화'),
                subtitle: const Text('패킷 로그를 파일에 저장'),
                value: _enableLogging,
                onChanged: (value) {
                  setState(() => _enableLogging = value);
                },
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.folder_open),
                title: const Text('로그 폴더 열기'),
                subtitle: const Text('저장된 로그 파일 보기'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // TODO: 로그 폴더 열기
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('로그 폴더 열기 기능 준비 중...')),
                  );
                },
              ),
            ],
          ),

          const Divider(height: 32),

          // 디스플레이 설정
          _buildSection(
            '디스플레이 설정',
            Icons.display_settings,
            [
              ListTile(
                leading: const Icon(Icons.palette),
                title: const Text('테마'),
                subtitle: const Text('Light (다크모드 준비 중)'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('다크모드 준비 중...')),
                  );
                },
              ),
            ],
          ),

          const Divider(height: 32),

          // 정보
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
                subtitle: Text('1.0.0'),
              ),
              ListTile(
                leading: const Icon(Icons.code),
                title: const Text('오픈소스 라이선스'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  showLicensePage(context: context);
                },
              ),
            ],
          ),

          const SizedBox(height: 32),

          // 저장 버튼
          ElevatedButton.icon(
            onPressed: _saveSettings,
            icon: const Icon(Icons.save),
            label: const Text('설정 저장'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
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
            Icon(icon, size: 20, color: Colors.blueGrey[800]),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[800],
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
      keyboardType: keyboardType,
    );
  }

  void _saveSettings() {
    // TODO: 설정 저장 구현
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('설정이 저장되었습니다'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

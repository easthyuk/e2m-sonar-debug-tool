import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sonar_provider.dart';
import '../services/command_builder.dart';

class ControlPanel extends StatefulWidget {
  const ControlPanel({super.key});

  @override
  State<ControlPanel> createState() => _ControlPanelState();
}

class _ControlPanelState extends State<ControlPanel> {
  int _selectedMode = FishingMode.shore;
  int _selectedFrequency = Frequency.freq675;
  final TextEditingController _scanRateController = TextEditingController(text: '5');
  final TextEditingController _depthController = TextEditingController(text: '50');

  @override
  void dispose() {
    _scanRateController.dispose();
    _depthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SonarProvider>(
      builder: (context, provider, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.settings_remote, size: 20),
                      SizedBox(width: 8),
                      Text(
                        '제어 명령',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Big Endian 테스트 모드 토글
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: provider.useBigEndianCommands
                          ? Colors.orange[50]
                          : Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: provider.useBigEndianCommands
                            ? Colors.orange
                            : Colors.blue,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.science,
                          color: provider.useBigEndianCommands
                              ? Colors.orange
                              : Colors.blue,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Parameter Endian 테스트',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                provider.useBigEndianCommands
                                    ? 'Big Endian (5 bytes)'
                                    : 'Little Endian (4 bytes)',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: provider.useBigEndianCommands,
                          onChanged: (value) => provider.toggleBigEndianMode(),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 24),

                  // 고급 테스트 모드 선택
                  ExpansionTile(
                    leading: const Icon(Icons.science_outlined, size: 20),
                    title: const Text(
                      '고급 진단 테스트',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('현재: ${_getTestModeName(provider.testMode)}'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 테스트 모드 선택
                            const Text('패킷 형식:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildTestModeChip(provider, 'normal', '기본'),
                                _buildTestModeChip(provider, 'big_endian', 'Big Endian'),
                                _buildTestModeChip(provider, 'crlf', '+CRLF'),
                                _buildTestModeChip(provider, 'lf', '+LF'),
                                _buildTestModeChip(provider, 'xor', '+XOR'),
                                _buildTestModeChip(provider, 'sum', '+SUM'),
                              ],
                            ),
                            const Divider(height: 24),

                            // 초기화 시퀀스 테스트
                            const Text('초기화 시퀀스:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => provider.testInitSequence1(),
                                    icon: const Icon(Icons.looks_one, size: 16),
                                    label: const Text('패턴 1', style: TextStyle(fontSize: 12)),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => provider.testInitSequence2(),
                                    icon: const Icon(Icons.looks_two, size: 16),
                                    label: const Text('패턴 2', style: TextStyle(fontSize: 12)),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => provider.testInitSequence3(),
                                    icon: const Icon(Icons.looks_3, size: 16),
                                    label: const Text('패턴 3', style: TextStyle(fontSize: 12)),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '패턴 1: 모드→주파수→주기 (2초 간격)\n패턴 2: OFF→설정→ON (2초 간격)\n패턴 3: 전체 설정 순차 (1초 간격)',
                              style: TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                            const Divider(height: 16),

                            // 전체 모드 테스트
                            const Text('빠른 진단:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: () => provider.quickTestAllModes(SonarCommand.setFrequency, Frequency.freq270),
                              icon: const Icon(Icons.speed, size: 16),
                              label: const Text('6가지 모드로 주파수 변경 테스트', style: TextStyle(fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              '1초 간격으로 모든 패킷 형식 시도',
                              style: TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // 낚시 모드
                  const Text(
                    '낚시 모드',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('연안'),
                        selected: _selectedMode == FishingMode.shore,
                        onSelected: (selected) {
                          setState(() => _selectedMode = FishingMode.shore);
                        },
                      ),
                      ChoiceChip(
                        label: const Text('보트'),
                        selected: _selectedMode == FishingMode.boat,
                        onSelected: (selected) {
                          setState(() => _selectedMode = FishingMode.boat);
                        },
                      ),
                      ChoiceChip(
                        label: const Text('얼음'),
                        selected: _selectedMode == FishingMode.ice,
                        onSelected: (selected) {
                          setState(() => _selectedMode = FishingMode.ice);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => provider.setMode(_selectedMode),
                    child: const Text('모드 설정'),
                  ),
                  const Divider(height: 24),

                  // 주파수
                  const Text(
                    '주파수',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('675kHz'),
                        selected: _selectedFrequency == Frequency.freq675,
                        onSelected: (selected) {
                          setState(() => _selectedFrequency = Frequency.freq675);
                        },
                      ),
                      ChoiceChip(
                        label: const Text('270kHz'),
                        selected: _selectedFrequency == Frequency.freq270,
                        onSelected: (selected) {
                          setState(() => _selectedFrequency = Frequency.freq270);
                        },
                      ),
                      ChoiceChip(
                        label: const Text('100kHz'),
                        selected: _selectedFrequency == Frequency.freq100,
                        onSelected: (selected) {
                          setState(() => _selectedFrequency = Frequency.freq100);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => provider.setFrequency(_selectedFrequency),
                    child: const Text('주파수 변경'),
                  ),
                  const Divider(height: 24),

                  // 스캔 주기
                  const Text(
                    '스캔 주기 (1-15 Hz)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _scanRateController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            suffixText: 'Hz',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          final rate = int.tryParse(_scanRateController.text);
                          if (rate != null) {
                            provider.setScanRate(rate);
                          }
                        },
                        child: const Text('적용'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 최대 깊이
                  const Text(
                    '최대 깊이 (1-100 m)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _depthController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            suffixText: 'm',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          final depth = int.tryParse(_depthController.text);
                          if (depth != null) {
                            provider.setDepthRange(depth);
                          }
                        },
                        child: const Text('적용'),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // 스캔 제어
                  const Text(
                    '스캔 제어',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => provider.startScan(),
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('START'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => provider.stopScan(),
                          icon: const Icon(Icons.pause),
                          label: const Text('STOP'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // 상태
                  if (provider.lastCommandStatus != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              provider.lastCommandStatus!,
                              style: const TextStyle(color: Colors.green),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // 테스트 모드 이름 반환
  String _getTestModeName(String mode) {
    switch (mode) {
      case 'normal':
        return '기본 (4 bytes)';
      case 'big_endian':
        return 'Big Endian (5 bytes)';
      case 'crlf':
        return 'CRLF 추가 (6 bytes)';
      case 'lf':
        return 'LF 추가 (5 bytes)';
      case 'xor':
        return 'XOR 체크섬 (5 bytes)';
      case 'sum':
        return 'SUM 체크섬 (5 bytes)';
      default:
        return mode;
    }
  }

  // 테스트 모드 Chip 생성
  Widget _buildTestModeChip(SonarProvider provider, String mode, String label) {
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: provider.testMode == mode,
      onSelected: (selected) {
        if (selected) {
          provider.setTestMode(mode);
        }
      },
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}

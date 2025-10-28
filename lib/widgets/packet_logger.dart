import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sonar_provider.dart';
import '../models/packet_log.dart';

class PacketLogger extends StatefulWidget {
  const PacketLogger({super.key});

  @override
  State<PacketLogger> createState() => _PacketLoggerState();
}

class _PacketLoggerState extends State<PacketLogger> {
  final ScrollController _scrollController = ScrollController();
  bool _autoScroll = true;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_autoScroll && _scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SonarProvider>(
      builder: (context, provider, child) {
        // 새 로그 추가 시 자동 스크롤
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

        return Card(
          child: Column(
            children: [
              // 헤더
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.article, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      '패킷 로그',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Checkbox(
                          value: _autoScroll,
                          onChanged: (value) {
                            setState(() => _autoScroll = value ?? true);
                          },
                        ),
                        const Text('자동스크롤'),
                      ],
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () => provider.clearLogs(),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // 로그 리스트
              Expanded(
                child: provider.logs.isEmpty
                    ? const Center(
                        child: Text(
                          '패킷 로그가 없습니다',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(8),
                        itemCount: provider.logs.length,
                        itemBuilder: (context, index) {
                          final log = provider.logs[index];
                          return _buildLogEntry(log);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogEntry(PacketLog log) {
    final color = _getLogColor(log);
    final bgColor = color.withValues(alpha: 0.1);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더 (방향 + 타임스탬프)
          Row(
            children: [
              Icon(
                log.direction == PacketDirection.rx
                    ? Icons.arrow_downward
                    : Icons.arrow_upward,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 4),
              Text(
                log.directionSymbol,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SelectableText(
                  log.timestampFormatted,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Hex 데이터
          if (log.hexString.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(4),
              ),
              child: SelectableText(
                log.formattedHex,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Colors.greenAccent,
                ),
              ),
            ),
          const SizedBox(height: 8),

          // 파싱된 정보
          Row(
            children: [
              const Text(
                '→ ',
                style: TextStyle(color: Colors.grey),
              ),
              Expanded(
                child: SelectableText(
                  log.parsedInfo,
                  style: TextStyle(
                    color: log.isError ? Colors.red : Colors.black87,
                    fontWeight: log.isError ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getLogColor(PacketLog log) {
    if (log.isError) return Colors.red;
    return log.direction == PacketDirection.rx ? Colors.blue : Colors.orange;
  }
}

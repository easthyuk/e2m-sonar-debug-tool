class ConnectionState {
  final bool isConnected;
  final String host;
  final int port;
  final int receivedPackets;
  final int sentPackets;
  final int errorCount;
  final DateTime? lastReceivedTime;

  ConnectionState({
    required this.isConnected,
    required this.host,
    required this.port,
    this.receivedPackets = 0,
    this.sentPackets = 0,
    this.errorCount = 0,
    this.lastReceivedTime,
  });

  ConnectionState copyWith({
    bool? isConnected,
    String? host,
    int? port,
    int? receivedPackets,
    int? sentPackets,
    int? errorCount,
    DateTime? lastReceivedTime,
  }) {
    return ConnectionState(
      isConnected: isConnected ?? this.isConnected,
      host: host ?? this.host,
      port: port ?? this.port,
      receivedPackets: receivedPackets ?? this.receivedPackets,
      sentPackets: sentPackets ?? this.sentPackets,
      errorCount: errorCount ?? this.errorCount,
      lastReceivedTime: lastReceivedTime ?? this.lastReceivedTime,
    );
  }

  String get statusText => isConnected ? '● 연결됨' : '○ 연결 끊김';

  String get connectionInfo => '$host:$port';

  String get statsText =>
      '수신: $receivedPackets packets | 송신: $sentPackets | 에러: $errorCount';

  String? get lastUpdateText {
    if (lastReceivedTime == null) return null;
    final diff = DateTime.now().difference(lastReceivedTime!);
    if (diff.inSeconds < 1) return '${diff.inMilliseconds}ms 전';
    if (diff.inMinutes < 1) return '${diff.inSeconds}초 전';
    return '${diff.inMinutes}분 전';
  }
}

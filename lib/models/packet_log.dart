import 'dart:typed_data';

enum PacketDirection { tx, rx }

class PacketLog {
  final PacketDirection direction;
  final Uint8List rawData;
  final String hexString;
  final String parsedInfo;
  final DateTime timestamp;
  final bool isError;

  PacketLog({
    required this.direction,
    required this.rawData,
    required this.hexString,
    required this.parsedInfo,
    required this.timestamp,
    this.isError = false,
  });

  String get formattedHex {
    return rawData
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join(' ');
  }

  String get directionSymbol => direction == PacketDirection.rx ? '▶ RX' : '◀ TX';

  String get timestampFormatted {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    final ms = timestamp.millisecond.toString().padLeft(3, '0');
    return '$h:$m:$s.$ms';
  }

  @override
  String toString() {
    return '$directionSymbol $timestampFormatted\n$formattedHex\n→ $parsedInfo';
  }
}

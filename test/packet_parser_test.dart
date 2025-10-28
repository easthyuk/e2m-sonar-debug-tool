import 'package:flutter_test/flutter_test.dart';
import 'package:sonar_debug_tool/services/packet_parser.dart';
import 'dart:typed_data';

void main() {
  group('PacketParser Tests', () {
    test('Parse out of water packet (7 bytes)', () {
      // 물 밖 패킷: 03 00 00 4A 01 0D 0A
      final packet = Uint8List.fromList([
        0x03, 0x00, // Frame Length (LE)
        0x00, // water_detect = 0
        0x4A, // battery_percent = 74
        0x01, // battery_status = charging
        0x0D, 0x0A, // CRLF
      ]);

      final result = PacketParser.parse(packet);

      expect(result, isNotNull);
      expect(result!.inWater, false);
      expect(result.batteryPercent, 74);
      expect(result.batteryStatus, 1);
    });

    test('Parse in water packet (182 bytes)', () {
      // 물 속 패킷 시작 부분
      final packet = Uint8List(182);
      packet[0] = 0xB4; // Frame Length LSB (180)
      packet[1] = 0x00; // Frame Length MSB
      packet[2] = 0x01; // water_detect = 1

      // water_temp = 24.4°C (0x41C33333 Big Endian)
      packet[3] = 0x41;
      packet[4] = 0xC3;
      packet[5] = 0x33;
      packet[6] = 0x33;

      // GPS data (skip)
      // frequency
      packet[87] = 0x01; // 675kHz

      // water_depth = 1.26m (0x3FA147AE Big Endian)
      packet[88] = 0x3F;
      packet[89] = 0xA1;
      packet[90] = 0x47;
      packet[91] = 0xAE;

      // sonar_samples (skip for now)

      final result = PacketParser.parse(packet);

      expect(result, isNotNull);
      expect(result!.inWater, true);
      expect(result.waterTemp, closeTo(24.4, 0.1));
      expect(result.frequency, 1);
      expect(result.scanDepth, closeTo(1.26, 0.01));
      expect(result.sonarSamples, isNotNull);
      expect(result.sonarSamples!.length, 90);
    });

    test('Invalid packet returns null', () {
      final packet = Uint8List.fromList([0x01, 0x02, 0x03]);
      final result = PacketParser.parse(packet);
      expect(result, isNull);
    });

    test('Get packet info for out of water', () {
      final packet = Uint8List.fromList([
        0x03, 0x00, 0x00, 0x64, 0x02, 0x0D, 0x0A,
      ]);

      final info = PacketParser.getPacketInfo(packet);
      expect(info, contains('물 밖'));
      expect(info, contains('100%'));
    });

    test('Get packet info for in water', () {
      final packet = Uint8List(182);
      packet[0] = 0xB4;
      packet[1] = 0x00;
      packet[2] = 0x01;

      // 25.0°C
      packet[3] = 0x41;
      packet[4] = 0xC8;
      packet[5] = 0x00;
      packet[6] = 0x00;

      packet[87] = 0x02; // 270kHz

      // 2.5m
      packet[88] = 0x40;
      packet[89] = 0x20;
      packet[90] = 0x00;
      packet[91] = 0x00;

      final info = PacketParser.getPacketInfo(packet);
      expect(info, contains('물 속'));
      expect(info, contains('25.0°C'));
      expect(info, contains('2.50m'));
      expect(info, contains('270kHz'));
    });
  });
}

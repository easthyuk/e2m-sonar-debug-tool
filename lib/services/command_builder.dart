import 'dart:typed_data';

class CommandBuilder {
  /// 명령 패킷 생성 - Little Endian Parameter (원래 방식)
  /// 명세서: 4 bytes만 전송 (CRLF 없음!)
  static Uint8List build(int cmdId, int param) {
    final packet = Uint8List(4); // Frame(2) + CMD_ID(1) + Param(1)

    // Frame Length = 3 (Little Endian) - 명세서 확인됨
    // 예시: 03 00 01 01 (SET_MODE), 03 00 05 02 (SCAN_OFF)
    packet[0] = 0x03; // LSB
    packet[1] = 0x00; // MSB

    packet[2] = cmdId;
    packet[3] = param; // Parameter: 1 byte, Little Endian

    return packet;
  }

  /// 명령 패킷 생성 - Big Endian Parameter (테스트용)
  /// RX 패킷이 Big Endian이므로 TX도 Big Endian일 가능성 테스트
  static Uint8List buildBigEndian(int cmdId, int param) {
    final packet = Uint8List(5); // Frame(2) + CMD_ID(1) + Param(2)

    // Frame Length = 4 (Little Endian)
    // 예시: 04 00 02 00 02 (SET_FREQUENCY 270kHz, Big Endian)
    packet[0] = 0x04; // LSB (Frame Length = 4)
    packet[1] = 0x00; // MSB

    packet[2] = cmdId;
    // Parameter: 2 bytes, Big Endian
    packet[3] = (param >> 8) & 0xFF; // MSB
    packet[4] = param & 0xFF;        // LSB

    return packet;
  }

  /// 명령 패킷 생성 - CRLF 추가 (테스트용)
  /// 하드웨어가 CRLF 종료를 요구할 가능성 테스트
  static Uint8List buildWithCRLF(int cmdId, int param) {
    final packet = Uint8List(6); // Frame(2) + CMD_ID(1) + Param(1) + CRLF(2)

    packet[0] = 0x03; // LSB
    packet[1] = 0x00; // MSB
    packet[2] = cmdId;
    packet[3] = param;
    packet[4] = 0x0D; // CR
    packet[5] = 0x0A; // LF

    return packet;
  }

  /// 명령 패킷 생성 - LF만 추가 (테스트용)
  /// 일부 시스템은 LF만 사용
  static Uint8List buildWithLF(int cmdId, int param) {
    final packet = Uint8List(5); // Frame(2) + CMD_ID(1) + Param(1) + LF(1)

    packet[0] = 0x03; // LSB
    packet[1] = 0x00; // MSB
    packet[2] = cmdId;
    packet[3] = param;
    packet[4] = 0x0A; // LF

    return packet;
  }

  /// 명령 패킷 생성 - XOR 체크섬 추가 (테스트용)
  /// 체크섬 = Frame[0] XOR Frame[1] XOR CMD_ID XOR Param
  static Uint8List buildWithChecksum(int cmdId, int param) {
    final packet = Uint8List(5); // Frame(2) + CMD_ID(1) + Param(1) + Checksum(1)

    packet[0] = 0x03; // LSB
    packet[1] = 0x00; // MSB
    packet[2] = cmdId;
    packet[3] = param;

    // XOR 체크섬 계산
    int checksum = packet[0] ^ packet[1] ^ packet[2] ^ packet[3];
    packet[4] = checksum;

    return packet;
  }

  /// 명령 패킷 생성 - SUM 체크섬 추가 (테스트용)
  /// 체크섬 = (Frame[0] + Frame[1] + CMD_ID + Param) & 0xFF
  static Uint8List buildWithSumChecksum(int cmdId, int param) {
    final packet = Uint8List(5); // Frame(2) + CMD_ID(1) + Param(1) + Checksum(1)

    packet[0] = 0x03; // LSB
    packet[1] = 0x00; // MSB
    packet[2] = cmdId;
    packet[3] = param;

    // SUM 체크섬 계산
    int checksum = (packet[0] + packet[1] + packet[2] + packet[3]) & 0xFF;
    packet[4] = checksum;

    return packet;
  }

  /// 명령 정보 텍스트 생성
  static String getCommandInfo(int cmdId, int param) {
    switch (cmdId) {
      case 0x01:
        return 'SET_MODE: ${_getModeText(param)}';
      case 0x02:
        return 'SET_FREQUENCY: ${_getFrequencyText(param)}';
      case 0x03:
        return 'SET_SCAN_RATE: ${param}Hz';
      case 0x04:
        return 'SET_DEPTH_RANGE: ${param}m';
      case 0x05:
        return 'SCAN_CONTROL: ${param == 1 ? "ON" : "OFF"}';
      default:
        return 'Unknown command (0x${cmdId.toRadixString(16)})';
    }
  }

  static String _getModeText(int mode) {
    switch (mode) {
      case 1:
        return '연안';
      case 2:
        return '보트';
      case 3:
        return '얼음';
      default:
        return 'unknown';
    }
  }

  static String _getFrequencyText(int freq) {
    switch (freq) {
      case 1:
        return '675kHz';
      case 2:
        return '270kHz';
      case 3:
        return '100kHz';
      default:
        return 'unknown';
    }
  }
}

// 명령 상수
class SonarCommand {
  static const int setMode = 0x01;
  static const int setFrequency = 0x02;
  static const int setScanRate = 0x03;
  static const int setDepthRange = 0x04;
  static const int scanControl = 0x05;
}

// 모드 상수
class FishingMode {
  static const int shore = 1; // 연안 (GPS 지속)
  static const int boat = 2; // 보트 (GPS 비활성)
  static const int ice = 3; // 얼음 (GPS 1회)
}

// 주파수 상수
class Frequency {
  static const int freq675 = 1; // 675kHz (고해상도, 얕은 수심)
  static const int freq270 = 2; // 270kHz (중간, 범용)
  static const int freq100 = 3; // 100kHz (깊은 수심, 넓은 범위)
}

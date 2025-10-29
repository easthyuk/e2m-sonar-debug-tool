# E2M 소나 하드웨어 통신 프로토콜 명세서

**버전**: 1.0
**최종 수정일**: 2025-10-29
**작성자**: E2M & 케이제이알앤디
**검증 완료**: 2025-10-29

---

## 목차
1. [개요](#개요)
2. [연결 정보](#연결-정보)
3. [패킷 구조](#패킷-구조)
4. [제어 명령 (TX)](#제어-명령-tx)
5. [수신 데이터 (RX)](#수신-데이터-rx)
6. [테스트 결과](#테스트-결과)
7. [구현 예시](#구현-예시)

---

## 개요

E2M 소나 하드웨어는 TCP/IP 소켓 통신을 사용하여 제어 명령을 수신하고 스캔 데이터를 전송합니다.

### 주요 기능
- 실시간 수심/깊이 측정
- 주파수 변경 (675kHz, 270kHz, 100kHz)
- 스캔 모드 변경 (물 밖, 연안, 보트, 얼음)
- 스캔 주기 설정 (1~15Hz)
- 깊이 범위 설정 (1~100m)
- 스캔 제어 (시작/정지)

---

## 연결 정보

### 네트워크 설정
```
프로토콜: TCP/IP
IP 주소: 192.168.4.1
포트: 36001
연결 방식: Wi-Fi Direct (소나 하드웨어가 AP 역할)
```

### 연결 절차
1. 소나 하드웨어의 Wi-Fi에 연결
2. `192.168.4.1:36001`로 TCP 소켓 연결
3. 연결 성공 시 자동으로 RX 데이터 수신 시작
4. 제어 명령 전송 가능

---

## 패킷 구조

### TX (제어 명령) 패킷 형식

**현재 지원되는 형식**: 4 bytes (기본)

```
Byte 0    Byte 1    Byte 2    Byte 3
┌─────────┬─────────┬─────────┬─────────┐
│  0x03   │  0x00   │ CMD_ID  │  PARAM  │
└─────────┴─────────┴─────────┴─────────┘
   ^         ^         ^         ^
   |         |         |         └─ 파라미터 (1 byte)
   |         |         └─────────── 명령 ID (1 byte)
   |         └─────────────────── 예약 (항상 0x00)
   └─────────────────────────── 프레임 길이 (3 = CMD + PARAM + 0x00)
```

**예시**:
- 주파수 270kHz 설정: `03 00 02 02`
- 스캔 10Hz 설정: `03 00 03 0a`
- 스캔 정지: `03 00 05 02`

### RX (수신 데이터) 패킷 형식

#### 1. 상태 패킷 (7 bytes)
```
03 00 00 [BATTERY] 00 0d 0a
         └─ 배터리 잔량 (0x00~0x64 = 0~100%)
```

**예시**:
- `03 00 00 63 00 0d 0a` → 배터리 99%, idle

#### 2. 스캔 데이터 패킷 (182 bytes)
```
b4 00 01 [TEMP] [DEPTH] [GPS] [RESERVED] [FREQ] [DEPTH_FLOAT] [SCAN_DATA]
         └─ 온도 (4 bytes, float)
                 └─ 스캔 깊이 (4 bytes, float)
                         └─ GPS 데이터 (56 bytes, NMEA)
                                  └─ 예약 (52 bytes)
                                           └─ 주파수 (4 bytes)
                                                     └─ 깊이 (4 bytes, float)
                                                              └─ 스캔 데이터 (50 bytes)
```

**파싱 예시**:
```
b4 00 01 c0 3b 85 1e ... 02 40 05 3e f3 ...
             ^^^^^^^^^       ^^^^^^^^^^^^
             온도 -2.9°C      주파수 270kHz, 깊이 2.08m
```

---

## 제어 명령 (TX)

### 명령 ID 목록

| CMD_ID | 명령 이름 | 설명 | PARAM 범위 |
|--------|----------|------|-----------|
| `0x01` | SET_MODE | 스캔 모드 변경 | `0x00`~`0x03` |
| `0x02` | SET_FREQUENCY | 주파수 변경 | `0x00`, `0x02`, `0x03` |
| `0x03` | SET_SCAN_RATE | 스캔 주기 변경 | `0x01`~`0x0F` (1~15Hz) |
| `0x04` | SET_DEPTH_RANGE | 깊이 범위 설정 | `0x01`~`0x64` (1~100m) |
| `0x05` | SCAN_CONTROL | 스캔 시작/정지 | `0x01`, `0x02` |

---

### 1. SET_MODE (0x01) - 스캔 모드 변경

**설명**: 소나의 동작 모드를 변경합니다.

**패킷 형식**:
```
03 00 01 [MODE]
```

**PARAM 값**:
| PARAM | 모드 | 설명 |
|-------|------|------|
| `0x00` | 물 밖 (Out of Water) | 공기 중 감지 차단 |
| `0x01` | 연안 (Shore) | 얕은 물 스캔 |
| `0x02` | 보트 (Boat) | 일반 낚시 모드 |
| `0x03` | 얼음 (Ice) | 빙상 낚시 모드 |

**예시**:
```javascript
// 보트 모드로 변경
const packet = Buffer.from([0x03, 0x00, 0x01, 0x02]);
socket.write(packet);
```

**테스트 결과**:
```
✅ 보트 모드: 03 00 01 02 → 정상 작동 확인
✅ 얼음 모드: 03 00 01 03 → 정상 작동 확인
```

---

### 2. SET_FREQUENCY (0x02) - 주파수 변경

**설명**: 소나의 스캔 주파수를 변경합니다. 주파수에 따라 스캔 깊이와 정밀도가 변화합니다.

**패킷 형식**:
```
03 00 02 [FREQ]
```

**PARAM 값**:
| PARAM | 주파수 | 특징 |
|-------|--------|------|
| `0x00` 또는 `0x01` | 675kHz | 높은 해상도, 얕은 깊이 (기본값) |
| `0x02` | 270kHz | 중간 해상도, 중간 깊이 |
| `0x03` | 100kHz | 낮은 해상도, 깊은 깊이 |

**주파수별 스캔 깊이**:
- **675kHz**: 1.25~1.30m (정밀)
- **270kHz**: 2.08~2.85m (중간)
- **100kHz**: 1.13~13.70m (광범위)

**예시**:
```javascript
// 270kHz로 변경 (중간 깊이)
const packet = Buffer.from([0x03, 0x00, 0x02, 0x02]);
socket.write(packet);
```

**테스트 결과**:
```
✅ 675kHz: 03 00 02 00 → 1.25~1.30m 스캔
✅ 270kHz: 03 00 02 02 → 2.08~2.85m 스캔
✅ 100kHz: 03 00 02 03 → 1.13~13.70m 스캔
```

---

### 3. SET_SCAN_RATE (0x03) - 스캔 주기 변경

**설명**: 초당 스캔 횟수를 설정합니다 (1~15Hz).

**패킷 형식**:
```
03 00 03 [RATE]
```

**PARAM 값**:
| PARAM | 스캔 주기 | 패킷 간격 |
|-------|----------|---------|
| `0x01` | 1Hz | 1000ms |
| `0x05` | 5Hz | 200ms |
| `0x0A` | 10Hz | 100ms |
| `0x0F` | 15Hz | 66ms |

**예시**:
```javascript
// 10Hz로 설정 (0.1초마다 스캔)
const packet = Buffer.from([0x03, 0x00, 0x03, 0x0A]);
socket.write(packet);
```

**테스트 결과**:
```
✅ 10Hz: 03 00 03 0a → RX 패킷 간격 ~100ms로 변경 확인
```

---

### 4. SET_DEPTH_RANGE (0x04) - 깊이 범위 설정

**설명**: 스캔할 최대 깊이를 설정합니다 (1~100m).

**패킷 형식**:
```
03 00 04 [DEPTH]
```

**PARAM 값**:
| PARAM | 깊이 범위 | 용도 |
|-------|----------|------|
| `0x03` | 3m | 얕은 수역 |
| `0x0A` | 10m | 일반 낚시 |
| `0x32` | 50m | 깊은 수역 |
| `0x64` | 100m | 심해 |

**예시**:
```javascript
// 50m 깊이로 설정
const packet = Buffer.from([0x03, 0x00, 0x04, 0x32]);
socket.write(packet);
```

**테스트 결과**:
```
✅ 50m: 03 00 04 32 → 전송 성공 확인
```

---

### 5. SCAN_CONTROL (0x05) - 스캔 시작/정지

**설명**: 스캔을 시작하거나 정지합니다.

**패킷 형식**:
```
03 00 05 [CONTROL]
```

**PARAM 값**:
| PARAM | 동작 | 설명 |
|-------|------|------|
| `0x01` | START | 스캔 시작 |
| `0x02` | STOP | 스캔 정지 |

**예시**:
```javascript
// 스캔 정지
const stopPacket = Buffer.from([0x03, 0x00, 0x05, 0x02]);
socket.write(stopPacket);

// 스캔 시작
const startPacket = Buffer.from([0x03, 0x00, 0x05, 0x01]);
socket.write(startPacket);
```

**테스트 결과**:
```
✅ STOP: 03 00 05 02 → RX 데이터 수신 중단
✅ START: 03 00 05 01 → RX 데이터 수신 재개
```

---

## 수신 데이터 (RX)

### RX 데이터 파싱

#### 상태 패킷 (7 bytes)
```javascript
function parseStatusPacket(buffer) {
  if (buffer[0] === 0x03 && buffer[1] === 0x00 && buffer[2] === 0x00) {
    const battery = buffer[3]; // 0x00~0x64 (0~100%)
    return {
      type: 'status',
      battery: battery,
      status: 'idle'
    };
  }
}
```

#### 스캔 데이터 패킷 (182 bytes)
```javascript
function parseScanPacket(buffer) {
  if (buffer[0] === 0xB4 && buffer.length === 182) {
    // 온도 (bytes 3-6, float, little-endian)
    const tempView = new DataView(buffer.buffer, 3, 4);
    const temperature = tempView.getFloat32(0, true);

    // 주파수 (bytes 112-115)
    const freq = buffer[112];
    let frequency = '675kHz';
    if (freq === 0x02) frequency = '270kHz';
    else if (freq === 0x03) frequency = '100kHz';

    // 깊이 (bytes 116-119, float)
    const depthView = new DataView(buffer.buffer, 116, 4);
    const depth = depthView.getFloat32(0, true);

    // 스캔 데이터 (bytes 120-169, 50 bytes)
    const scanData = buffer.slice(120, 170);

    return {
      type: 'scan',
      temperature: temperature.toFixed(1),
      frequency: frequency,
      depth: depth.toFixed(2),
      scanData: Array.from(scanData)
    };
  }
}
```

---

## 테스트 결과

### 검증된 기능 (2025-10-29)

| 기능 | 명령 | 결과 | 상태 |
|------|------|------|------|
| 주파수 변경 (270kHz) | `03 00 02 02` | 675kHz → 270kHz 변경 확인 | ✅ 성공 |
| 주파수 변경 (100kHz) | `03 00 02 03` | 270kHz → 100kHz 변경 확인 | ✅ 성공 |
| 모드 변경 (보트) | `03 00 01 02` | 보트 모드 변경 확인 | ✅ 성공 |
| 모드 변경 (얼음) | `03 00 01 03` | 얼음 모드 변경 확인 | ✅ 성공 |
| 스캔 주기 (10Hz) | `03 00 03 0a` | 패킷 간격 0.1초로 변경 | ✅ 성공 |
| 깊이 범위 (50m) | `03 00 04 32` | 전송 성공 | ✅ 성공 |
| 스캔 정지 | `03 00 05 02` | RX 데이터 중단 | ✅ 성공 |
| 스캔 시작 | `03 00 05 01` | RX 데이터 재개 | ✅ 성공 |

### 테스트 환경
- **날짜**: 2025-10-29
- **펌웨어**: 최신 버전 (2025-10-29 업데이트)
- **테스트 툴**: E2M Sonar Debug Tool v1.0
- **로그 파일**: `logs_2025-10-29_14-22-39.csv`

---

## 구현 예시

### Node.js / JavaScript

```javascript
const net = require('net');

class E2MSonarController {
  constructor() {
    this.socket = null;
  }

  // 연결
  connect() {
    return new Promise((resolve, reject) => {
      this.socket = net.createConnection({
        host: '192.168.4.1',
        port: 36001
      });

      this.socket.on('connect', () => {
        console.log('E2M Sonar 연결 성공');
        resolve();
      });

      this.socket.on('data', (data) => {
        this.handleRxData(data);
      });

      this.socket.on('error', reject);
    });
  }

  // 명령 전송
  sendCommand(cmdId, param) {
    const packet = Buffer.from([0x03, 0x00, cmdId, param]);
    this.socket.write(packet);
    console.log(`TX: ${packet.toString('hex')}`);
  }

  // 주파수 변경
  setFrequency(freq) {
    let param;
    switch(freq) {
      case 675: param = 0x00; break;
      case 270: param = 0x02; break;
      case 100: param = 0x03; break;
      default: throw new Error('Invalid frequency');
    }
    this.sendCommand(0x02, param);
  }

  // 모드 변경
  setMode(mode) {
    const modeMap = {
      'out_of_water': 0x00,
      'shore': 0x01,
      'boat': 0x02,
      'ice': 0x03
    };
    this.sendCommand(0x01, modeMap[mode]);
  }

  // 스캔 주기 설정
  setScanRate(hz) {
    if (hz < 1 || hz > 15) throw new Error('Rate must be 1-15Hz');
    this.sendCommand(0x03, hz);
  }

  // 스캔 제어
  startScan() {
    this.sendCommand(0x05, 0x01);
  }

  stopScan() {
    this.sendCommand(0x05, 0x02);
  }

  // RX 데이터 처리
  handleRxData(buffer) {
    if (buffer[0] === 0xB4 && buffer.length === 182) {
      const parsed = this.parseScanData(buffer);
      console.log(`스캔 데이터: ${parsed.depth}m, ${parsed.frequency}, ${parsed.temperature}°C`);
    }
  }

  parseScanData(buffer) {
    // 온도
    const tempView = new DataView(buffer.buffer, buffer.byteOffset + 3, 4);
    const temperature = tempView.getFloat32(0, true);

    // 주파수
    const freqByte = buffer[112];
    let frequency = '675kHz';
    if (freqByte === 0x02) frequency = '270kHz';
    else if (freqByte === 0x03) frequency = '100kHz';

    // 깊이
    const depthView = new DataView(buffer.buffer, buffer.byteOffset + 116, 4);
    const depth = depthView.getFloat32(0, true);

    return { temperature, frequency, depth };
  }
}

// 사용 예시
async function main() {
  const sonar = new E2MSonarController();

  await sonar.connect();

  // 270kHz로 변경
  sonar.setFrequency(270);

  // 10Hz 스캔
  sonar.setScanRate(10);

  // 보트 모드
  sonar.setMode('boat');
}
```

---

### Flutter / Dart

```dart
import 'dart:io';
import 'dart:typed_data';

class E2MSonarController {
  Socket? _socket;

  // 연결
  Future<void> connect() async {
    _socket = await Socket.connect('192.168.4.1', 36001);
    print('E2M Sonar 연결 성공');

    _socket!.listen((Uint8List data) {
      _handleRxData(data);
    });
  }

  // 명령 전송
  void sendCommand(int cmdId, int param) {
    final packet = Uint8List.fromList([0x03, 0x00, cmdId, param]);
    _socket?.add(packet);
    print('TX: ${packet.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
  }

  // 주파수 변경
  void setFrequency(int freq) {
    int param;
    switch (freq) {
      case 675:
        param = 0x00;
        break;
      case 270:
        param = 0x02;
        break;
      case 100:
        param = 0x03;
        break;
      default:
        throw ArgumentError('Invalid frequency');
    }
    sendCommand(0x02, param);
  }

  // 모드 변경
  void setMode(String mode) {
    final modeMap = {
      'out_of_water': 0x00,
      'shore': 0x01,
      'boat': 0x02,
      'ice': 0x03,
    };
    sendCommand(0x01, modeMap[mode]!);
  }

  // 스캔 주기 설정
  void setScanRate(int hz) {
    if (hz < 1 || hz > 15) {
      throw ArgumentError('Rate must be 1-15Hz');
    }
    sendCommand(0x03, hz);
  }

  // 스캔 제어
  void startScan() => sendCommand(0x05, 0x01);
  void stopScan() => sendCommand(0x05, 0x02);

  // RX 데이터 처리
  void _handleRxData(Uint8List buffer) {
    if (buffer[0] == 0xB4 && buffer.length == 182) {
      final parsed = _parseScanData(buffer);
      print('스캔 데이터: ${parsed['depth']}m, ${parsed['frequency']}, ${parsed['temperature']}°C');
    }
  }

  Map<String, dynamic> _parseScanData(Uint8List buffer) {
    // 온도 (bytes 3-6, float, little-endian)
    final tempBytes = buffer.sublist(3, 7);
    final temperature = ByteData.sublistView(tempBytes).getFloat32(0, Endian.little);

    // 주파수 (byte 112)
    final freqByte = buffer[112];
    String frequency = '675kHz';
    if (freqByte == 0x02) {
      frequency = '270kHz';
    } else if (freqByte == 0x03) {
      frequency = '100kHz';
    }

    // 깊이 (bytes 116-119, float)
    final depthBytes = buffer.sublist(116, 120);
    final depth = ByteData.sublistView(depthBytes).getFloat32(0, Endian.little);

    return {
      'temperature': temperature,
      'frequency': frequency,
      'depth': depth,
    };
  }
}

// 사용 예시
void main() async {
  final sonar = E2MSonarController();

  await sonar.connect();

  // 270kHz로 변경
  sonar.setFrequency(270);

  // 10Hz 스캔
  sonar.setScanRate(10);

  // 보트 모드
  sonar.setMode('boat');
}
```

---

## 주의사항

### 1. 연결 관리
- Wi-Fi 연결이 끊어지면 TCP 소켓도 끊어짐
- 재연결 시 자동으로 RX 데이터 수신 재개
- 연결 타임아웃: 10초 권장

### 2. 명령 전송
- 명령 전송 후 즉시 RX 데이터에 반영됨
- 별도의 응답 패킷 없음 (RX 데이터로 확인)
- 명령 전송 간격: 최소 100ms 권장

### 3. 주파수별 특성
- **675kHz**: 정밀하지만 얕은 깊이만 측정 가능
- **270kHz**: 균형잡힌 해상도와 깊이
- **100kHz**: 깊은 깊이 측정 가능, 낮은 해상도

### 4. 스캔 주기
- 높은 주기(15Hz)는 배터리 소모 증가
- 일반적으로 5~10Hz 권장
- 스캔 주기와 RX 패킷 간격이 일치함

---

## 버전 히스토리

| 버전 | 날짜 | 변경 사항 |
|------|------|----------|
| 1.0 | 2025-10-29 | 초기 명세서 작성, 모든 명령 테스트 완료 |

---

## 문의

**하드웨어 제조사**: 케이제이알앤디
**프로토콜 검증**: E2M
**테스트 완료일**: 2025-10-29

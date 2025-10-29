# E2M 소나 제어 - 빠른 구현 가이드

**작성일**: 2025-10-29
**대상**: 앱 개발자
**난이도**: 중급

---

## 5분 요약

### 연결 방법
```
IP: 192.168.4.1
Port: 36001
Protocol: TCP/IP
```

### 명령 패킷 형식 (4 bytes)
```
[0x03] [0x00] [명령ID] [파라미터]
```

### 주요 명령 예시
```javascript
주파수 270kHz:  [0x03, 0x00, 0x02, 0x02]
주파수 100kHz:  [0x03, 0x00, 0x02, 0x03]
보트 모드:      [0x03, 0x00, 0x01, 0x02]
스캔 10Hz:     [0x03, 0x00, 0x03, 0x0A]
스캔 정지:      [0x03, 0x00, 0x05, 0x02]
스캔 시작:      [0x03, 0x00, 0x05, 0x01]
```

---

## 1단계: 연결

### JavaScript / Node.js
```javascript
const net = require('net');

const socket = net.createConnection({
  host: '192.168.4.1',
  port: 36001
});

socket.on('connect', () => {
  console.log('연결 성공!');
});

socket.on('data', (data) => {
  console.log('RX:', data.toString('hex'));
});
```

### Flutter / Dart
```dart
import 'dart:io';

Socket socket = await Socket.connect('192.168.4.1', 36001);
print('연결 성공!');

socket.listen((data) {
  print('RX: $data');
});
```

### React Native
```javascript
import TcpSocket from 'react-native-tcp-socket';

const socket = TcpSocket.createConnection({
  host: '192.168.4.1',
  port: 36001
});

socket.on('connect', () => {
  console.log('연결 성공!');
});

socket.on('data', (data) => {
  console.log('RX:', data.toString('hex'));
});
```

---

## 2단계: 명령 전송

### 명령 ID 치트시트
```
0x01: 모드 변경
0x02: 주파수 변경 ⭐ 가장 많이 사용
0x03: 스캔 주기
0x04: 깊이 범위
0x05: 스캔 시작/정지
```

### 주파수 변경 (가장 중요!)
```javascript
// 270kHz로 변경
const packet = Buffer.from([0x03, 0x00, 0x02, 0x02]);
socket.write(packet);

// 100kHz로 변경 (더 깊이 측정)
const packet = Buffer.from([0x03, 0x00, 0x02, 0x03]);
socket.write(packet);
```

### 모드 변경
```javascript
// 보트 모드
const packet = Buffer.from([0x03, 0x00, 0x01, 0x02]);
socket.write(packet);

// 얼음 모드
const packet = Buffer.from([0x03, 0x00, 0x01, 0x03]);
socket.write(packet);
```

### 스캔 제어
```javascript
// 스캔 정지
const stopPacket = Buffer.from([0x03, 0x00, 0x05, 0x02]);
socket.write(stopPacket);

// 스캔 시작
const startPacket = Buffer.from([0x03, 0x00, 0x05, 0x01]);
socket.write(startPacket);
```

---

## 3단계: 수신 데이터 파싱

### 스캔 데이터 확인 (182 bytes)
```javascript
socket.on('data', (buffer) => {
  // 스캔 데이터 패킷인지 확인
  if (buffer[0] === 0xB4 && buffer.length === 182) {

    // 온도 (bytes 3-6, float, little-endian)
    const temperature = buffer.readFloatLE(3);

    // 주파수 (byte 112)
    const freqByte = buffer[112];
    let frequency = '675kHz';
    if (freqByte === 0x02) frequency = '270kHz';
    else if (freqByte === 0x03) frequency = '100kHz';

    // 깊이 (bytes 116-119, float)
    const depth = buffer.readFloatLE(116);

    console.log(`깊이: ${depth.toFixed(2)}m, 주파수: ${frequency}, 온도: ${temperature.toFixed(1)}°C`);
  }
});
```

### Flutter에서 파싱
```dart
socket.listen((Uint8List buffer) {
  if (buffer[0] == 0xB4 && buffer.length == 182) {

    // 온도
    final tempBytes = buffer.sublist(3, 7);
    final temperature = ByteData.sublistView(tempBytes).getFloat32(0, Endian.little);

    // 주파수
    final freqByte = buffer[112];
    String frequency = '675kHz';
    if (freqByte == 0x02) frequency = '270kHz';
    else if (freqByte == 0x03) frequency = '100kHz';

    // 깊이
    final depthBytes = buffer.sublist(116, 120);
    final depth = ByteData.sublistView(depthBytes).getFloat32(0, Endian.little);

    print('깊이: ${depth.toStringAsFixed(2)}m, 주파수: $frequency');
  }
});
```

---

## 완전한 예시 코드

### JavaScript (Node.js)
```javascript
const net = require('net');

class SonarController {
  constructor() {
    this.socket = null;
  }

  // 연결
  async connect() {
    return new Promise((resolve, reject) => {
      this.socket = net.createConnection({
        host: '192.168.4.1',
        port: 36001
      });

      this.socket.on('connect', () => {
        console.log('✅ 소나 연결 성공');
        resolve();
      });

      this.socket.on('data', (data) => {
        this.parseData(data);
      });

      this.socket.on('error', reject);
    });
  }

  // 명령 전송 (공통)
  send(cmdId, param) {
    const packet = Buffer.from([0x03, 0x00, cmdId, param]);
    this.socket.write(packet);
    console.log(`📤 TX: ${packet.toString('hex')}`);
  }

  // 주파수 변경
  setFrequency(freq) {
    const map = { 675: 0x00, 270: 0x02, 100: 0x03 };
    this.send(0x02, map[freq]);
  }

  // 모드 변경
  setMode(mode) {
    const map = { 'boat': 0x02, 'ice': 0x03, 'shore': 0x01, 'out': 0x00 };
    this.send(0x01, map[mode]);
  }

  // 스캔 주기
  setScanRate(hz) {
    this.send(0x03, hz);
  }

  // 스캔 제어
  startScan() { this.send(0x05, 0x01); }
  stopScan() { this.send(0x05, 0x02); }

  // 데이터 파싱
  parseData(buffer) {
    if (buffer[0] === 0xB4 && buffer.length === 182) {
      const temperature = buffer.readFloatLE(3);
      const freqByte = buffer[112];
      const frequency = freqByte === 0x02 ? '270kHz' : freqByte === 0x03 ? '100kHz' : '675kHz';
      const depth = buffer.readFloatLE(116);

      console.log(`📡 깊이: ${depth.toFixed(2)}m, ${frequency}, ${temperature.toFixed(1)}°C`);
    }
  }
}

// 사용 예시
async function main() {
  const sonar = new SonarController();
  await sonar.connect();

  // 270kHz, 10Hz, 보트 모드
  sonar.setFrequency(270);
  sonar.setScanRate(10);
  sonar.setMode('boat');
}

main();
```

---

### Flutter (Dart) - 완전한 예시
```dart
import 'dart:io';
import 'dart:typed_data';

class SonarController {
  Socket? _socket;

  // 연결
  Future<void> connect() async {
    _socket = await Socket.connect('192.168.4.1', 36001);
    print('✅ 소나 연결 성공');

    _socket!.listen((Uint8List data) {
      _parseData(data);
    });
  }

  // 명령 전송 (공통)
  void _send(int cmdId, int param) {
    final packet = Uint8List.fromList([0x03, 0x00, cmdId, param]);
    _socket?.add(packet);
    print('📤 TX: ${packet.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
  }

  // 주파수 변경
  void setFrequency(int freq) {
    final map = {675: 0x00, 270: 0x02, 100: 0x03};
    _send(0x02, map[freq]!);
  }

  // 모드 변경
  void setMode(String mode) {
    final map = {'boat': 0x02, 'ice': 0x03, 'shore': 0x01, 'out': 0x00};
    _send(0x01, map[mode]!);
  }

  // 스캔 주기
  void setScanRate(int hz) {
    _send(0x03, hz);
  }

  // 스캔 제어
  void startScan() => _send(0x05, 0x01);
  void stopScan() => _send(0x05, 0x02);

  // 데이터 파싱
  void _parseData(Uint8List buffer) {
    if (buffer[0] == 0xB4 && buffer.length == 182) {
      final temperature = ByteData.sublistView(buffer, 3, 7).getFloat32(0, Endian.little);

      final freqByte = buffer[112];
      String frequency = '675kHz';
      if (freqByte == 0x02) frequency = '270kHz';
      else if (freqByte == 0x03) frequency = '100kHz';

      final depth = ByteData.sublistView(buffer, 116, 120).getFloat32(0, Endian.little);

      print('📡 깊이: ${depth.toStringAsFixed(2)}m, $frequency, ${temperature.toStringAsFixed(1)}°C');
    }
  }

  // 연결 해제
  void disconnect() {
    _socket?.close();
  }
}

// 사용 예시
void main() async {
  final sonar = SonarController();
  await sonar.connect();

  // 270kHz, 10Hz, 보트 모드
  sonar.setFrequency(270);
  sonar.setScanRate(10);
  sonar.setMode('boat');

  // 10초 후 정지
  await Future.delayed(Duration(seconds: 10));
  sonar.stopScan();
  sonar.disconnect();
}
```

---

## UI 구현 예시 (Flutter)

### 간단한 제어 UI
```dart
import 'package:flutter/material.dart';

class SonarControlScreen extends StatefulWidget {
  @override
  _SonarControlScreenState createState() => _SonarControlScreenState();
}

class _SonarControlScreenState extends State<SonarControlScreen> {
  final SonarController _sonar = SonarController();
  String _status = '연결 안됨';
  String _depth = '--';
  String _frequency = '675kHz';

  @override
  void initState() {
    super.initState();
    _connectSonar();
  }

  Future<void> _connectSonar() async {
    try {
      await _sonar.connect();
      setState(() => _status = '연결됨');
    } catch (e) {
      setState(() => _status = '연결 실패');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('E2M Sonar 제어')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 상태 표시
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('상태: $_status', style: TextStyle(fontSize: 18)),
                    SizedBox(height: 8),
                    Text('깊이: $_depth m', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    Text('주파수: $_frequency', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // 주파수 선택
            Text('주파수 선택', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _sonar.setFrequency(675),
                    child: Text('675kHz\n(얕은 깊이)'),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _sonar.setFrequency(270),
                    child: Text('270kHz\n(중간)'),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _sonar.setFrequency(100),
                    child: Text('100kHz\n(깊은 깊이)'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            // 모드 선택
            Text('모드 선택', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _sonar.setMode('boat'),
                    child: Text('보트'),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _sonar.setMode('ice'),
                    child: Text('얼음'),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _sonar.setMode('shore'),
                    child: Text('연안'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            // 스캔 제어
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _sonar.startScan(),
                    child: Text('스캔 시작'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _sonar.stopScan(),
                    child: Text('스캔 정지'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _sonar.disconnect();
    super.dispose();
  }
}
```

---

## 자주 하는 실수

### ❌ 잘못된 예시
```javascript
// 1. 잘못된 패킷 크기
const wrong = Buffer.from([0x05, 0x00, 0x02, 0x02, 0x0d, 0x0a]); // ❌ 6 bytes (CR LF 포함)

// 2. 잘못된 프레임 길이
const wrong = Buffer.from([0x04, 0x00, 0x02, 0x02]); // ❌ 프레임 길이가 0x04

// 3. Big-endian으로 float 읽기
const depth = buffer.readFloatBE(116); // ❌ BE가 아니라 LE!
```

### ✅ 올바른 예시
```javascript
// 1. 올바른 패킷 (4 bytes)
const correct = Buffer.from([0x03, 0x00, 0x02, 0x02]); // ✅

// 2. 올바른 프레임 길이
const correct = Buffer.from([0x03, 0x00, 0x02, 0x02]); // ✅ 프레임 길이 0x03

// 3. Little-endian으로 float 읽기
const depth = buffer.readFloatLE(116); // ✅
```

---

## 디버깅 팁

### 1. 패킷 전송 확인
```javascript
// 전송한 패킷 로그 출력
socket.on('data', (data) => {
  console.log('📤 TX:', data.toString('hex'));
});
```

### 2. RX 데이터 확인
```javascript
// 수신한 데이터 타입 확인
socket.on('data', (buffer) => {
  if (buffer[0] === 0xB4) {
    console.log('📡 스캔 데이터 수신 (182 bytes)');
  } else if (buffer[0] === 0x03) {
    console.log('📊 상태 패킷 수신 (7 bytes)');
  } else {
    console.log('❓ 알 수 없는 패킷:', buffer.toString('hex'));
  }
});
```

### 3. 연결 상태 모니터링
```javascript
socket.on('error', (err) => {
  console.error('❌ 에러:', err.message);
});

socket.on('close', () => {
  console.log('🔌 연결 종료');
});
```

---

## 성능 최적화

### 1. 버퍼링 처리
```javascript
let buffer = Buffer.alloc(0);

socket.on('data', (chunk) => {
  // 버퍼에 누적
  buffer = Buffer.concat([buffer, chunk]);

  // 완전한 패킷이 있으면 처리
  while (buffer.length >= 182) {
    const packet = buffer.slice(0, 182);
    parsePacket(packet);
    buffer = buffer.slice(182);
  }
});
```

### 2. 명령 큐
```javascript
class SonarController {
  constructor() {
    this.commandQueue = [];
    this.isSending = false;
  }

  async send(cmdId, param) {
    this.commandQueue.push({ cmdId, param });
    if (!this.isSending) {
      this.processCom mandQueue();
    }
  }

  async processCommandQueue() {
    this.isSending = true;
    while (this.commandQueue.length > 0) {
      const cmd = this.commandQueue.shift();
      this.socket.write(Buffer.from([0x03, 0x00, cmd.cmdId, cmd.param]));
      await new Promise(resolve => setTimeout(resolve, 100)); // 100ms 간격
    }
    this.isSending = false;
  }
}
```

---

## 체크리스트

앱 개발 시 확인할 사항:

- [ ] TCP 소켓 연결 (`192.168.4.1:36001`)
- [ ] 명령 패킷 4 bytes로 전송 (`03 00 CMD PARAM`)
- [ ] RX 데이터 little-endian으로 파싱
- [ ] 주파수 변경 기능 구현
- [ ] 모드 변경 기능 구현
- [ ] 스캔 시작/정지 기능 구현
- [ ] 연결 에러 처리
- [ ] 재연결 로직
- [ ] 버퍼링 처리 (불완전한 패킷 대응)
- [ ] UI 업데이트 (깊이, 주파수, 온도 표시)

---

## 다음 단계

1. ✅ 이 가이드로 기본 연결 구현
2. ✅ 명령 전송 테스트
3. ✅ RX 데이터 파싱 확인
4. 📱 UI에 통합
5. 🧪 실제 하드웨어로 테스트
6. 🚀 배포

---

## 참고 문서

- [E2M_SONAR_PROTOCOL_SPEC.md](./E2M_SONAR_PROTOCOL_SPEC.md) - 상세 프로토콜 명세
- [TEST_REPORT.md](./TEST_REPORT.md) - 테스트 결과 및 검증 데이터
- GitHub 저장소: https://github.com/easthyuk/e2m-sonar-debug-tool

---

**궁금한 점이 있으면 프로토콜 명세서를 참고하세요!**

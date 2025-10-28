# E2M Sonar Debug Tool

프로페셔널 수중 음파 탐지기(Sonar) 디버깅 및 모니터링 도구

## 프로젝트 개요

E2M Sonar Debug Tool은 수중 음파 탐지기 하드웨어와 TCP 통신하여 실시간 데이터를 수집, 시각화, 분석하는 크로스 플랫폼 애플리케이션입니다.

### 주요 기능

#### Phase 1 기능
- ✅ TCP 소켓 통신 (192.168.4.1:36001)
- ✅ Big Endian 패킷 파싱
- ✅ 실시간 Sonar 그래프 (Deeper 스타일)
- ✅ GPS 데이터 파싱 (NMEA GNRMC)
- ✅ 데이터 내보내기 (CSV, JSON, Markdown)
- ✅ 패킷 로깅 시스템
- ✅ 반응형 UI (Desktop/Mobile)

#### Phase 2 기능 (NEW)
- 🆕 **데이터 시뮬레이터**: 하드웨어 없이 테스트
- 🆕 **설정 영구 저장**: SharedPreferences 기반
- 🆕 **다크 모드**: 완전한 테마 지원
- 🆕 **통계 대시보드**: 자동 통계 계산
- 🆕 **어군 자동 감지**: AI 기반 클러스터 분석
- 🆕 **실시간 알림**: 어군 감지 알림
- 🆕 **단위 테스트**: 코드 품질 보장

## 빠른 시작

### 요구사항
- Flutter SDK 3.x
- Dart SDK 3.x
- Windows/macOS/Linux/Android/iOS

### 설치

```bash
# 프로젝트 클론
cd sonar_debug_tool

# 의존성 설치
flutter pub get

# Windows 빌드
flutter build windows --release

# 실행 파일
build\windows\x64\runner\Release\sonar_debug_tool.exe
```

### 시뮬레이터 모드로 시작

하드웨어 없이 즉시 테스트할 수 있습니다:

1. 앱 실행
2. 설정 아이콘 클릭
3. "시뮬레이터 사용" 활성화
4. "저장" 버튼 클릭
5. 홈 화면으로 돌아가기
6. "연결" 버튼 클릭
7. "물속 진입" 버튼으로 데이터 생성

### 실제 하드웨어 연결

1. 설정에서 IP 주소 입력 (기본값: 192.168.4.1)
2. 포트 입력 (기본값: 36001)
3. "시뮬레이터 사용" 비활성화
4. "저장" 후 연결

## 문서

- **[Phase 1 개발 보고서](DEVELOPMENT_COMPLETE.md)**: 초기 개발 완료 보고서
- **[Phase 2 기능 가이드](PHASE2_FEATURES.md)**: 최신 기능 상세 설명
- **[빠른 시작 가이드](QUICK_START.md)**: 사용자 가이드
- **[최종 요약](FINAL_SUMMARY.md)**: Phase 1 요약

## 프로젝트 구조

```
lib/
├── main.dart                     # 앱 진입점
├── models/                       # 데이터 모델
│   ├── sonar_data.dart          # 소나 데이터
│   ├── gps_data.dart            # GPS 데이터
│   ├── packet_log.dart          # 패킷 로그
│   └── connection_state.dart    # 연결 상태
├── services/                     # 비즈니스 로직
│   ├── tcp_service.dart         # TCP 통신
│   ├── packet_parser.dart       # 패킷 파싱
│   ├── command_builder.dart     # 명령 생성
│   ├── export_service.dart      # 데이터 내보내기
│   ├── data_simulator.dart      # 데이터 시뮬레이터
│   ├── simulator_tcp_service.dart # 시뮬레이터 래퍼
│   ├── settings_service.dart    # 설정 저장
│   └── fish_detector.dart       # 어군 감지
├── providers/                    # 상태 관리
│   ├── sonar_provider.dart      # 소나 상태
│   └── theme_provider.dart      # 테마 상태
├── widgets/                      # UI 컴포넌트
│   ├── connection_bar.dart      # 연결 바
│   ├── status_dashboard.dart    # 상태 대시보드
│   ├── control_panel.dart       # 제어 패널
│   ├── packet_logger.dart       # 패킷 로거
│   ├── sonar_graph.dart         # 소나 그래프
│   ├── export_menu.dart         # 내보내기 메뉴
│   ├── gps_display.dart         # GPS 표시
│   ├── statistics_dashboard.dart # 통계 대시보드
│   └── fish_alert.dart          # 어군 알림
├── screens/                      # 화면
│   ├── home_screen.dart         # 홈 화면
│   ├── settings_screen.dart     # 설정 화면 (구버전)
│   └── settings_screen_v2.dart  # 설정 화면 V2
└── theme/                        # 테마
    └── app_theme.dart           # 라이트/다크 테마
test/
├── packet_parser_test.dart      # 패킷 파서 테스트
└── gps_data_test.dart           # GPS 테스트
```

## 기술 스택

### Flutter & Dart
- Flutter 3.x
- Dart 3.x
- Material Design 3

### 상태 관리
- Provider 패턴
- ChangeNotifier

### 의존성
```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.1
  intl: ^0.19.0
  path_provider: ^2.1.1
  shared_preferences: ^2.2.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
```

## TCP 프로토콜

### 패킷 구조

#### 물 밖 패킷 (7바이트)
```
[0x55 0xAA] [길이:2] [0x01] [배터리%] [체크섬]
```

#### 물속 패킷 (182바이트)
```
[헤더:2] [길이:2] [타입] [배터리] [체크섬]
[수온:4] [스캔깊이:4] [주파수:4] [소나샘플:90] [GPS:68] [체크섬]
```

### Endianness
- **프레임 길이**: Little Endian (2바이트)
- **모든 데이터**: Big Endian (Float32, Int32)

### 제어 명령
- **주파수 변경**: `[0x55 0xAA 0x05 0x00 0x02 {freq} 0x00 체크섬]`
  - 83kHz: 0x01
  - 200kHz: 0x02
  - 455kHz: 0x03

## 화면 구성

### Desktop 레이아웃 (> 900px)
```
┌────────────────────────────────────────────┐
│ [연결 바]                                   │
├──────────┬──────────────┬─────────────────┤
│ Status   │              │   Control       │
│ GPS      │ Sonar Graph  │   Panel         │
│ Stats    │              │                 │
├──────────┴──────────────┴─────────────────┤
│ Packet Logger                             │
└────────────────────────────────────────────┘
  + Fish Alert (오버레이)
```

### Mobile 레이아웃 (< 900px)
5개 탭:
1. Status - 상태 정보
2. Sonar - 소나 그래프
3. Control - 제어 패널
4. Stats - 통계 대시보드
5. Logs - 패킷 로그

## 어군 감지 알고리즘

### 파라미터
- 최소 신호 강도: 0x05
- 최소 클러스터 크기: 3
- 바닥 마진: 2.0m

### 신뢰도 계산
```
신뢰도 = (신호강도 × 0.5) + (클러스터크기 × 0.3) + (안정성 × 0.2)
```

### 알림 조건
- 신뢰도 > 60%
- 바닥 신호(0x0F) 제외
- 최소 3개 연속 샘플

## 데이터 내보내기

### CSV 형식
```csv
Timestamp,In Water,Water Temp,Scan Depth,Frequency,Battery,GPS
2024-01-15 10:30:45,true,15.2,5.3,200000,85,37.5665,126.9780
```

### JSON 형식
```json
{
  "timestamp": "2024-01-15T10:30:45",
  "inWater": true,
  "waterTemp": 15.2,
  "scanDepth": 5.3,
  "frequency": 200000,
  "batteryPercent": 85,
  "gps": {
    "latitude": 37.5665,
    "longitude": 126.9780
  }
}
```

### Markdown 형식
세션 리포트 형태로 통계 포함

## 테스트

```bash
# 모든 테스트 실행
flutter test

# 특정 테스트
flutter test test/packet_parser_test.dart
flutter test test/gps_data_test.dart
```

## 빌드

### Windows
```bash
flutter build windows --release
```

### macOS
```bash
flutter build macos --release
```

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

## 개발 로드맵

### 완료 (Phase 1 & 2)
- [x] TCP 통신
- [x] 패킷 파싱
- [x] Sonar 그래프
- [x] GPS 파싱
- [x] 데이터 내보내기
- [x] 데이터 시뮬레이터
- [x] 다크 모드
- [x] 통계 대시보드
- [x] 어군 감지
- [x] 단위 테스트

### 향후 계획
- [ ] 어군 이동 경로 추적
- [ ] 그래프 줌/패닝
- [ ] 클라우드 동기화
- [ ] 다중 장치 지원
- [ ] 음성 알림
- [ ] 성능 최적화

## 라이선스

MIT License

## 기여

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 연락처

E2M - Sonar Debug Tool Team

Project Link: [https://github.com/e2m/sonar_debug_tool](https://github.com/e2m/sonar_debug_tool)

## 감사의 말

- Flutter 팀
- Provider 패키지 개발자
- 모든 기여자분들

---

**버전**: 2.0.0
**마지막 업데이트**: 2024-01-15
**개발 기간**: Phase 1 + Phase 2 (총 24시간)

class GPSData {
  final double? latitude;
  final double? longitude;
  final double? speed; // knots
  final double? course; // degrees
  final String? timeUtc;
  final String? dateUtc;
  final bool isValid;
  final String rawNmea;

  GPSData({
    this.latitude,
    this.longitude,
    this.speed,
    this.course,
    this.timeUtc,
    this.dateUtc,
    required this.isValid,
    required this.rawNmea,
  });

  /// NMEA GNRMC 문장 파싱
  /// 형식: $GNRMC,123519,A,4807.038,N,01131.000,E,022.4,084.4,230394,003.1,W*6A
  static GPSData? parseNMEA(String nmea) {
    if (nmea.isEmpty || !nmea.startsWith('\$')) {
      return null;
    }

    try {
      // CRLF 제거
      nmea = nmea.trim();

      // Checksum 검증 (옵션)
      if (nmea.contains('*')) {
        final parts = nmea.split('*');
        nmea = parts[0];
      }

      final fields = nmea.split(',');

      // GNRMC 확인
      if (!fields[0].contains('RMC')) {
        return null;
      }

      // 최소 필드 수 확인
      if (fields.length < 10) {
        return GPSData(isValid: false, rawNmea: nmea);
      }

      // 데이터 유효성 (A = valid, V = invalid)
      final isValid = fields.length > 2 && fields[2] == 'A';

      if (!isValid) {
        return GPSData(isValid: false, rawNmea: nmea);
      }

      // 위도 파싱 (DDMM.MMMM)
      double? latitude;
      if (fields.length > 3 && fields[3].isNotEmpty) {
        latitude = _parseLatitude(fields[3], fields.length > 4 ? fields[4] : 'N');
      }

      // 경도 파싱 (DDDMM.MMMM)
      double? longitude;
      if (fields.length > 5 && fields[5].isNotEmpty) {
        longitude = _parseLongitude(fields[5], fields.length > 6 ? fields[6] : 'E');
      }

      // 속도 (knots)
      double? speed;
      if (fields.length > 7 && fields[7].isNotEmpty) {
        speed = double.tryParse(fields[7]);
      }

      // 방향 (degrees)
      double? course;
      if (fields.length > 8 && fields[8].isNotEmpty) {
        course = double.tryParse(fields[8]);
      }

      return GPSData(
        latitude: latitude,
        longitude: longitude,
        speed: speed,
        course: course,
        timeUtc: fields.length > 1 ? fields[1] : null,
        dateUtc: fields.length > 9 ? fields[9] : null,
        isValid: true,
        rawNmea: nmea,
      );
    } catch (e) {
      return GPSData(isValid: false, rawNmea: nmea);
    }
  }

  /// 위도 변환: DDMM.MMMM -> DD.DDDDDD
  static double _parseLatitude(String value, String direction) {
    if (value.length < 4) return 0.0;

    final degrees = double.parse(value.substring(0, 2));
    final minutes = double.parse(value.substring(2));
    var latitude = degrees + (minutes / 60.0);

    if (direction == 'S') {
      latitude = -latitude;
    }

    return latitude;
  }

  /// 경도 변환: DDDMM.MMMM -> DDD.DDDDDD
  static double _parseLongitude(String value, String direction) {
    if (value.length < 5) return 0.0;

    final degrees = double.parse(value.substring(0, 3));
    final minutes = double.parse(value.substring(3));
    var longitude = degrees + (minutes / 60.0);

    if (direction == 'W') {
      longitude = -longitude;
    }

    return longitude;
  }

  String get latitudeString {
    if (latitude == null) return 'N/A';
    final direction = latitude! >= 0 ? 'N' : 'S';
    return '${latitude!.abs().toStringAsFixed(6)}° $direction';
  }

  String get longitudeString {
    if (longitude == null) return 'N/A';
    final direction = longitude! >= 0 ? 'E' : 'W';
    return '${longitude!.abs().toStringAsFixed(6)}° $direction';
  }

  String get speedString {
    if (speed == null) return 'N/A';
    // knots to km/h
    final kmh = speed! * 1.852;
    return '${kmh.toStringAsFixed(1)} km/h';
  }

  String get courseString {
    if (course == null) return 'N/A';
    return '${course!.toStringAsFixed(1)}°';
  }

  @override
  String toString() {
    if (!isValid) return 'GPS: Invalid';
    return 'GPS: ${latitudeString}, ${longitudeString}';
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:sonar_debug_tool/models/gps_data.dart';

void main() {
  group('GPSData Tests', () {
    test('Parse valid NMEA GNRMC sentence', () {
      const nmea = '\$GNRMC,123519,A,4807.038,N,01131.000,E,022.4,084.4,230394,003.1,W*6A';

      final gps = GPSData.parseNMEA(nmea);

      expect(gps, isNotNull);
      expect(gps!.isValid, true);
      expect(gps.latitude, closeTo(48.1173, 0.0001));
      expect(gps.longitude, closeTo(11.5167, 0.0001));
      expect(gps.speed, closeTo(22.4, 0.1));
      expect(gps.course, closeTo(84.4, 0.1));
    });

    test('Parse NMEA with south latitude', () {
      const nmea = '\$GNRMC,123519,A,3345.678,S,12345.678,E,000.0,000.0,230394,003.1,W*6A';

      final gps = GPSData.parseNMEA(nmea);

      expect(gps, isNotNull);
      expect(gps!.latitude, isNegative);
    });

    test('Parse NMEA with west longitude', () {
      const nmea = '\$GNRMC,123519,A,3345.678,N,12345.678,W,000.0,000.0,230394,003.1,W*6A';

      final gps = GPSData.parseNMEA(nmea);

      expect(gps, isNotNull);
      expect(gps!.longitude, isNegative);
    });

    test('Invalid NMEA returns invalid GPSData', () {
      const nmea = '\$GNRMC,123519,V,,,,,,,,,*6A'; // V = invalid

      final gps = GPSData.parseNMEA(nmea);

      expect(gps, isNotNull);
      expect(gps!.isValid, false);
    });

    test('Empty NMEA returns null', () {
      final gps = GPSData.parseNMEA('');
      expect(gps, isNull);
    });

    test('Formatted strings work correctly', () {
      const nmea = '\$GNRMC,123519,A,3730.339,N,12657.468,E,005.2,045.0,230394,003.1,W*6A';

      final gps = GPSData.parseNMEA(nmea)!;

      expect(gps.latitudeString, contains('N'));
      expect(gps.longitudeString, contains('E'));
      expect(gps.speedString, contains('km/h'));
      expect(gps.courseString, contains('°'));
    });
  });
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sonar_provider.dart';
import '../models/gps_data.dart';

class GPSDisplay extends StatelessWidget {
  const GPSDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SonarProvider>(
      builder: (context, provider, child) {
        final data = provider.currentData;
        GPSData? gpsData;

        if (data?.gpsData != null && data!.gpsData!.isNotEmpty) {
          gpsData = GPSData.parseNMEA(data.gpsData!);
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.location_on, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'GPS 정보',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),

                if (gpsData == null || !gpsData.isValid)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Icon(Icons.location_off, size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text(
                            'GPS 신호 없음',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  _buildGPSRow('위도', gpsData.latitudeString, Icons.north),
                  const SizedBox(height: 12),
                  _buildGPSRow('경도', gpsData.longitudeString, Icons.east),
                  const SizedBox(height: 12),
                  _buildGPSRow('속도', gpsData.speedString, Icons.speed),
                  const SizedBox(height: 12),
                  _buildGPSRow('방향', gpsData.courseString, Icons.explore),
                  const Divider(height: 24),

                  // 지도 링크 버튼
                  if (gpsData.latitude != null && gpsData.longitude != null)
                    ElevatedButton.icon(
                      onPressed: () {
                        // TODO: 지도 앱 열기
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Google Maps: ${gpsData!.latitude}, ${gpsData.longitude}',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.map),
                      label: const Text('지도에서 보기'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(40),
                      ),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGPSRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.blue),
        const SizedBox(width: 8),
        SizedBox(
          width: 60,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

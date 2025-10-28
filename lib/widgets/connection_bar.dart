import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sonar_provider.dart';

class ConnectionBar extends StatelessWidget {
  const ConnectionBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SonarProvider>(
      builder: (context, provider, child) {
        final connState = provider.connectionState;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: connState.isConnected ? Colors.green[700] : Colors.red[700],
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                connState.isConnected ? Icons.wifi : Icons.wifi_off,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                connState.statusText,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                connState.connectionInfo,
                style: const TextStyle(
                  color: Colors.white70,
                ),
              ),
              const Spacer(),
              Text(
                connState.statsText,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 16),
              if (!connState.isConnected)
                ElevatedButton(
                  onPressed: () => provider.connect(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red[700],
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text('연결'),
                )
              else
                TextButton(
                  onPressed: () => provider.disconnect(),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('연결 해제'),
                ),
            ],
          ),
        );
      },
    );
  }
}

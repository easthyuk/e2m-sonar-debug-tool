import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sonar_provider.dart';
import '../widgets/connection_bar.dart';
import '../widgets/status_dashboard.dart';
import '../widgets/control_panel.dart';
import '../widgets/packet_logger.dart';
import '../widgets/sonar_graph.dart';
import '../widgets/export_menu.dart';
import '../widgets/gps_display.dart';
import '../widgets/fish_alert.dart';
import '../widgets/statistics_dashboard.dart';
import 'settings_screen_v2.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('E2M Sonar Debug Tool'),
        backgroundColor: Colors.blueGrey[800],
        foregroundColor: Colors.white,
        actions: [
          const ExportMenu(),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreenV2(),
                ),
              );
            },
            tooltip: '설정',
          ),
        ],
      ),
      body: Column(
        children: [
          // Connection Bar
          const ConnectionBar(),

          // Main Content
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // 반응형 레이아웃
                if (constraints.maxWidth > 900) {
                  // Desktop 레이아웃
                  return _buildDesktopLayout();
                } else {
                  // Mobile 레이아웃 (탭)
                  return _buildMobileLayout();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Consumer<SonarProvider>(
      builder: (context, provider, child) {
        return Stack(
          children: [
            Column(
              children: [
                // 상단: Status + Control + Sonar Graph
                Expanded(
                  flex: 5,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Dashboard + GPS + Statistics (좌측)
                      Expanded(
                        flex: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: const [
                              Expanded(
                                flex: 2,
                                child: StatusDashboard(),
                              ),
                              SizedBox(height: 8),
                              Expanded(
                                flex: 2,
                                child: GPSDisplay(),
                              ),
                              SizedBox(height: 8),
                              Expanded(
                                flex: 2,
                                child: StatisticsDashboard(),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Sonar Graph (중앙)
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SonarGraph(
                            dataHistory: provider.dataHistory,
                            maxHistoryCount: 100,
                          ),
                        ),
                      ),

                      // Control Panel (우측)
                      const Expanded(
                        flex: 1,
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: ControlPanel(),
                        ),
                      ),
                    ],
                  ),
                ),

                // Packet Logger (하단, 전체 너비)
                const Expanded(
                  flex: 3,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(8.0, 0, 8.0, 8.0),
                    child: PacketLogger(),
                  ),
                ),
              ],
            ),

            // Fish Alert Overlay
            const FishAlert(),
          ],
        );
      },
    );
  }

  Widget _buildMobileLayout() {
    return Consumer<SonarProvider>(
      builder: (context, provider, child) {
        return Stack(
          children: [
            DefaultTabController(
              length: 5,
              child: Column(
                children: [
                  TabBar(
                    labelColor: Colors.blueGrey[800],
                    isScrollable: true,
                    tabs: const [
                      Tab(icon: Icon(Icons.dashboard), text: 'Status'),
                      Tab(icon: Icon(Icons.waves), text: 'Sonar'),
                      Tab(icon: Icon(Icons.settings_remote), text: 'Control'),
                      Tab(icon: Icon(Icons.analytics), text: 'Stats'),
                      Tab(icon: Icon(Icons.article), text: 'Logs'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // Status Tab
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: StatusDashboard(),
                        ),

                        // Sonar Tab
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SonarGraph(
                            dataHistory: provider.dataHistory,
                            maxHistoryCount: 50,
                          ),
                        ),

                        // Control Tab
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: ControlPanel(),
                        ),

                        // Statistics Tab
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: StatisticsDashboard(),
                        ),

                        // Logs Tab
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: PacketLogger(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Fish Alert Overlay
            const FishAlert(),
          ],
        );
      },
    );
  }
}

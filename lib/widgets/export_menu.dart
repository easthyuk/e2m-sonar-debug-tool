import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sonar_provider.dart';

class ExportMenu extends StatelessWidget {
  const ExportMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SonarProvider>(
      builder: (context, provider, child) {
        return PopupMenuButton<String>(
          icon: const Icon(Icons.download),
          tooltip: '데이터 내보내기',
          onSelected: (value) async {
            switch (value) {
              case 'csv_logs':
                await _exportLogsCSV(context, provider);
                break;
              case 'csv_data':
                await _exportDataCSV(context, provider);
                break;
              case 'json_data':
                await _exportDataJSON(context, provider);
                break;
              case 'report':
                await _exportReport(context, provider);
                break;
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'csv_logs',
              child: ListTile(
                leading: Icon(Icons.table_chart),
                title: Text('패킷 로그 (CSV)'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem<String>(
              value: 'csv_data',
              child: ListTile(
                leading: Icon(Icons.table_chart),
                title: Text('Sonar 데이터 (CSV)'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem<String>(
              value: 'json_data',
              child: ListTile(
                leading: Icon(Icons.code),
                title: Text('Sonar 데이터 (JSON)'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem<String>(
              value: 'report',
              child: ListTile(
                leading: Icon(Icons.description),
                title: Text('세션 리포트'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _exportLogsCSV(BuildContext context, SonarProvider provider) async {
    _showLoadingDialog(context, '패킷 로그를 내보내는 중...');

    final path = await provider.exportLogsToCSV();

    if (context.mounted) {
      Navigator.of(context).pop(); // 로딩 다이얼로그 닫기

      if (path != null) {
        _showSuccessDialog(context, '패킷 로그가 저장되었습니다', path);
      } else {
        _showErrorDialog(context, '패킷 로그 내보내기에 실패했습니다');
      }
    }
  }

  Future<void> _exportDataCSV(BuildContext context, SonarProvider provider) async {
    _showLoadingDialog(context, 'Sonar 데이터를 내보내는 중...');

    final path = await provider.exportDataToCSV();

    if (context.mounted) {
      Navigator.of(context).pop();

      if (path != null) {
        _showSuccessDialog(context, 'Sonar 데이터가 저장되었습니다', path);
      } else {
        _showErrorDialog(context, 'Sonar 데이터 내보내기에 실패했습니다');
      }
    }
  }

  Future<void> _exportDataJSON(BuildContext context, SonarProvider provider) async {
    _showLoadingDialog(context, 'JSON으로 내보내는 중...');

    final path = await provider.exportDataToJSON();

    if (context.mounted) {
      Navigator.of(context).pop();

      if (path != null) {
        _showSuccessDialog(context, 'JSON 파일이 저장되었습니다', path);
      } else {
        _showErrorDialog(context, 'JSON 내보내기에 실패했습니다');
      }
    }
  }

  Future<void> _exportReport(BuildContext context, SonarProvider provider) async {
    _showLoadingDialog(context, '세션 리포트를 생성하는 중...');

    final path = await provider.exportSessionReport();

    if (context.mounted) {
      Navigator.of(context).pop();

      if (path != null) {
        _showSuccessDialog(context, '세션 리포트가 생성되었습니다', path);
      } else {
        _showErrorDialog(context, '리포트 생성에 실패했습니다');
      }
    }
  }

  void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, String title, String path) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Expanded(child: Text(title)),
          ],
        ),
        content: SelectableText('저장 위치:\n$path'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('오류'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}

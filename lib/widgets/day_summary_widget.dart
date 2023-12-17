import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class DaySummaryWidget extends StatefulWidget {
  @override
  _DaySummaryWidgetState createState() => _DaySummaryWidgetState();
}

Future<List<Map<String, dynamic>>> readReport() async {
  try {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/report.json');
    if (!file.existsSync()) {
      return [];
    }

    final contents = await file.readAsString();
    List<dynamic> jsonReport = json.decode(contents);
    return jsonReport.cast<Map<String, dynamic>>();
  } catch (e) {
    print('Error reading report: $e');
    return [];
  }
}

class _DaySummaryWidgetState extends State<DaySummaryWidget> {
  late Future<List<Map<String, dynamic>>> _reportFuture;

  @override
  void initState() {
    super.initState();
    _reportFuture = readReport();
  }

  DataRow _createRow(Map<String, dynamic> report) {
    bool isZeroDuration = report['duration'] == '00:00:00';
    return DataRow(
      color: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
        if (isZeroDuration) return Colors.red.withOpacity(0.3); // Установка красного фона для строк с нулевым временем
        return null; // Стандартный фон для остальных строк
      }),
      cells: [
        DataCell(Text(report['taskName'])),
        DataCell(Text(report['duration'])),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Итоги дня"),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _reportFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return Text("Ошибка: ${snapshot.error}");
          } else if (snapshot.hasData) {
            Duration totalDuration = _calculateTotalDuration(snapshot.data!);
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Общее время: ${_formatDuration(totalDuration)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Задача')),
                        DataColumn(label: Text('Время')),
                      ],
                      rows: snapshot.data!.map(_createRow).toList(),
                    ),
                  ),
                ),
              ],
            );
          } else {
            return const Text("Нет данных");
          }
        },
      ),
    );
  }
  Duration _calculateTotalDuration(List<Map<String, dynamic>> reports) {
    Duration total = Duration();
    for (var report in reports) {
      List<String> parts = report['duration'].split(':');
      if (parts.length == 3) {
        int hours = int.parse(parts[0]);
        int minutes = int.parse(parts[1]);
        int seconds = int.parse(parts[2]);
        total += Duration(hours: hours, minutes: minutes, seconds: seconds);
      }
    }
    return total;
  }
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(duration.inHours)}:${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}";
  }
}

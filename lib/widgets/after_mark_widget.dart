import 'package:flutter/material.dart';

class AfterMarkWidget extends StatelessWidget {
  @override
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Данные записаны:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24.0),
            ),
            SizedBox(height: 16.0),
            Table(
              columnWidths: const {
                0: FixedColumnWidth(120.0),  // Фиксированная ширина первого столбца
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: const [
                TableRow(
                  children: [
                    Text('ФИО:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0)),
                    Text('Иванов Иван Иванович', style: TextStyle(fontSize: 18.0)), // Пример значения
                  ],
                ),
                TableRow(
                  children: [
                    Text('Офис:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0)),
                    Text('Москва, Центральный', style: TextStyle(fontSize: 18.0)), // Пример значения
                  ],
                ),
                TableRow(
                  children: [
                    Text('Время прибытия:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0)),
                    Text('08:00', style: TextStyle(fontSize: 18.0)), // Пример значения
                  ],
                ),
                TableRow(
                  children: [
                    Text('Время отбытия:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0)),
                    Text('17:00', style: TextStyle(fontSize: 18.0)), // Пример значения
                  ],
                ),
                TableRow(
                  children: [
                    Text('Отчёт:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0)),
                    Text('Ежедневный отчёт', style: TextStyle(fontSize: 18.0)), // Пример значения
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

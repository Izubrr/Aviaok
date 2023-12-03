import 'package:flutter/material.dart';
import 'dart:async';

class Task {
  String name;
  bool isRunning;
  bool isPinned;
  Task({this.name = '', this.isRunning = false, this.isPinned = false});
}

class TaskWidget extends StatefulWidget {
  final Task task;
  final Function onTaskChanged;
  final Function isAnyTaskRunning; // Новый параметр
  final Function manageTimer;

  TaskWidget({Key? key, required this.task, required this.onTaskChanged, required this.isAnyTaskRunning, required this.manageTimer}) : super(key: key);

  @override
  _TaskWidgetState createState() => _TaskWidgetState();
}

class _TaskWidgetState extends State<TaskWidget> {
  void _showAlertPopup(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Внимание'),
          content: Text(message),
          actions: <Widget>[
            CloseButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: TextField(
        controller: TextEditingController(text: widget.task.name),
        decoration: InputDecoration(
          hintText: 'Название задачи',
        ),
        onChanged: (value) {
          widget.task.name = value;
          widget.onTaskChanged();
        },
      ),
      trailing: Wrap(
        spacing: 12, // Пространство между кнопками
        children: [
          IconButton(
            icon: Icon(
              widget.task.isRunning ? Icons.stop : Icons.play_arrow,
              color: widget.task.isRunning ? Colors.red : Colors.green,
            ),
            onPressed: () {
              if (!widget.task.isRunning && widget.isAnyTaskRunning()) {
                _showAlertPopup(context, 'Сначала завершите текущие задачи');
              } else {
                setState(() {
                  widget.task.isRunning = !widget.task.isRunning;
                  widget.onTaskChanged();
                  // Вызов функции управления таймером
                  widget.manageTimer(widget.task.isRunning);
                });
              }
            },
          ),

          IconButton(
            icon: Icon(
              widget.task.isPinned ? Icons.star : Icons.star_border,
              color: widget.task.isPinned ? Colors.amber : Colors.grey,
            ),
            onPressed: () {
              setState(() {
                widget.task.isPinned = !widget.task.isPinned;
                widget.onTaskChanged();
              });
            },
          ),
        ],
      ),
    );
  }
}


class InformationWidget extends StatefulWidget {
  @override
  _InformationWidgetState createState() => _InformationWidgetState();
}

class _InformationWidgetState extends State<InformationWidget> {
  Duration _timerDuration = Duration();
  Timer? _timer;
  List<Task> _tasks = [];
  bool _isTaskRunning = false;

  void _showAlertPopup(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Внимание'),
          content: Text(message),
          actions: <Widget>[
            CloseButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _startTimer() {
    _stopTimer(); // Остановить текущий таймер, если он активен
    _timerDuration = Duration(); // Обнулить таймер
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _timerDuration += Duration(seconds: 1);
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _timerDuration = Duration(); // Обнулить таймер при его остановке
    });
  }

  void manageTimer(bool start) {
    if (start) {
      _startTimer();
    } else {
      _stopTimer();
    }
  }

  void _addTask() {
    if (_tasks.any((task) => task.isRunning)) {
      _showAlertPopup(context, 'Сначала завершите текущие задачи');
    } else {
      setState(() {
        _tasks.add(Task());
      });
    }
  }

  void _handleTaskChanged() {
    setState(() {}); // Перестроение интерфейса после изменения состояния задачи
  }

  bool isAnyTaskRunning() {
    return _tasks.any((task) => task.isRunning);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(formatDuration(_timerDuration)),

        Expanded(
          child: ReorderableListView(
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) {
                  newIndex -= 1;
                }
                final task = _tasks.removeAt(oldIndex);
                _tasks.insert(newIndex, task);
              });
            },
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            children: _tasks.map((task) => TaskWidget(
              key: ValueKey(task),
              task: task,
              onTaskChanged: _handleTaskChanged,
              isAnyTaskRunning: isAnyTaskRunning,
              manageTimer: manageTimer, // Передача функции управления таймером
            )).toList(),
          ),
        ),

        Padding(
          padding: EdgeInsets.only(bottom: 16.0),
          child: ElevatedButton(
              onPressed: _addTask,
              child: Text('Добавить задачу')
          ),
        ),
      ],
    );
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(duration.inHours)}:${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}";
  }
}

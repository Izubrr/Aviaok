import 'dart:convert';
import 'dart:io';
import 'package:aviaok/main.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:path_provider/path_provider.dart';

class Task {
  String name;
  bool isRunning;
  bool isPinned;

  Task({this.name = '', this.isRunning = false, this.isPinned = false});

  // Добавляем конструктор для инициализации всех полей
  Task.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        isRunning = json['isRunning'] ?? false,
        isPinned = json['isPinned'] ?? false;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'isRunning': isRunning,
      'isPinned': isPinned,
    };
  }
}

class TaskWidget extends StatefulWidget {
  final Task task;
  final Function onTaskChanged;
  final Function isAnyTaskRunning;
  final Function manageTimer;
  final Function(Task) onDeleteTask;

  TaskWidget({Key? key, required this.task, required this.onTaskChanged, required this.isAnyTaskRunning, required this.manageTimer, required this.onDeleteTask}) : super(key: key);

  @override
  _TaskWidgetState createState() => _TaskWidgetState();
}

Future<List<Task>> readTasks() async {
  try {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/tasks.json');
    if (!file.existsSync()) {
      return [];
    }

    final contents = await file.readAsString();
    final data = json.decode(contents);
    final currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    if (data['date'] != currentDate) {
      // Если дата не сегодняшняя, сбросить все задачи и сохранить файл
      List<Task> pinnedTasks = (data['tasks'] as List)
          .map((e) => Task.fromJson(e))
          .where((task) => task.isPinned)
          .toList();
      await writeTasks(pinnedTasks); // Сохранение только закрепленных задач
      return pinnedTasks;
    }

    List<dynamic> jsonTasks = data['tasks'];
    return jsonTasks.map((e) => Task.fromJson(e)).toList();
  } catch (e) {
    print('Error reading tasks: $e');
    return [];
  }
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

  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.task.name);
    _controller.addListener(_handleTextChange);
  }

  void _handleTextChange() {
    widget.task.name = _controller.text;
    widget.onTaskChanged();
    // Сохранение списка задач при каждом изменении текста
    writeTasks(context.findAncestorStateOfType<_InformationWidgetState>()!._tasks);
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          hintText: 'Название задачи',
        ),
        maxLength: 128,
        onChanged: (value) {
          widget.task.name = value;
          widget.onTaskChanged();
          setState(() {}); // Обновить состояние для отображения счетчика
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
                  // Вызов функции управления таймером с передачей названия задачи
                  widget.manageTimer(widget.task.isRunning, widget.task.name);
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
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              widget.onDeleteTask(widget.task);
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
  Duration _timerDuration = const Duration();
  List<dynamic> reportMap = [];
  Timer? _timer;
  Timer? _backupTimer; // Таймер для регулярного сохранения
  List<Task> _tasks = [];
  String _currentTaskName = '';

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _initBackupTimer();
  }

  void _initBackupTimer() {
    // Запуск таймера для регулярного сохранения каждые N секунд
    const backupInterval = Duration(minutes: 3); // Например, каждые 30 секунд
    _backupTimer = Timer.periodic(backupInterval, (Timer t) {
      writeTasks(_tasks);
    });
  }

  void _loadTasks() async {
    List<Task> loadedTasks = await readTasks();
    setState(() {
      _tasks = loadedTasks.map((task) {
        return task;
      }).toList();
    });
  }

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

  void _startTimer(String taskName) {
    // Поиск задачи в reportMap и получение сохраненного времени
    var existingTask = reportMap.firstWhere(
          (task) => task['taskName'] == taskName,
      orElse: () => null,
    );

    Duration initialDuration = const Duration();
    if (existingTask != null) {
      // Преобразование строки времени в объект Duration
      List<String> parts = existingTask['duration'].split(':');
      if (parts.length == 3) {
        int hours = int.parse(parts[0]);
        int minutes = int.parse(parts[1]);
        int seconds = int.parse(parts[2]);
        initialDuration = Duration(hours: hours, minutes: minutes, seconds: seconds);
      }
    }

    _timerDuration = initialDuration;
    _timer?.cancel(); // Остановить текущий таймер, если он активен
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timerDuration += const Duration(seconds: 1);
      });
    });
  }
  void _stopTimer() {
    if (_currentTaskName.isNotEmpty) {
      updateOrAddReport();
    }

    _timer?.cancel();
    setState(() {
      _timerDuration = const Duration(); // Обнулить таймер после сохранения
      _currentTaskName = ''; // Очистить текущее название задачи
    });
  }

  void manageTimer(bool start, String taskName) {
    if (start) {
      _currentTaskName = taskName;
      _startTimer(taskName); // Передаем название задачи
    } else {
      _stopTimer();
    }
  }

  void updateOrAddReport() {
    // Поиск индекса существующей задачи
    int existingTaskIndex = reportMap.indexWhere((task) => task['taskName'] == _currentTaskName);

    if (existingTaskIndex != -1) {
      // Задача найдена, обновляем длительность
      reportMap[existingTaskIndex]['duration'] = formatDuration(_timerDuration);
    } else {
      // Задача не найдена, добавляем новую
      reportMap.add({
        'taskName': _currentTaskName,
        'duration': formatDuration(_timerDuration),
      });
    }
  }

  void _addTask() {
    setState(() {
      _tasks.add(Task()); // Добавление новой задачи в список
    });
    writeTasks(_tasks); // Сохранение обновленного списка в файл
  }

  void _handleTaskChanged() {
    setState(() {}); // Перестроение интерфейса после изменения состояния задачи
  }

  bool isAnyTaskRunning() {
    return _tasks.any((task) => task.isRunning);
  }

  void _finishDay() async {
    final directory = await getApplicationDocumentsDirectory();
    final reportFile = File('${directory.path}/report.json');

    // Фильтрация задач, у которых isPinned == true
    List<Task> pinnedTasks = _tasks.where((task) => task.isPinned).toList();

    // Сохранение отфильтрованных задач в файл
    await writeTasks(pinnedTasks);

    // Добавление недостающих задач в reportMap
    for (var task in _tasks) {
      if (!reportMap.any((report) => report['taskName'] == task.name)) {
        reportMap.add({
          'taskName': task.name,
          'duration': '00:00:00',
        });
      }
    }

    // Запись данных в файл в формате JSON
    await reportFile.writeAsString(json.encode(reportMap));

    pageController.nextPage(duration: const Duration(milliseconds: 1), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    bool isFinishDayButtonDisabled = _tasks.any((task) => task.name.isEmpty || task.isRunning);
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
            physics: const NeverScrollableScrollPhysics(),
            children: _tasks.map((task) => TaskWidget(
              key: ValueKey(task),
              task: task,
              onTaskChanged: _handleTaskChanged,
              isAnyTaskRunning: isAnyTaskRunning,
              onDeleteTask: (Task task) {
                setState(() {
                  _tasks.remove(task);
                  writeTasks(_tasks);
                });
              },
              manageTimer: manageTimer, // Передача функции управления таймером
            )).toList(),
          ),
        ),

        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: _addTask,
                child: const Text('Добавить задачу'),
              ),
              ElevatedButton(
                onPressed: isFinishDayButtonDisabled ? null : _finishDay,
                child: const Text('Завершить день'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(duration.inHours)}:${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}";
  }
  @override
  void dispose() {
    _timer?.cancel();
    _backupTimer?.cancel(); // Останавливаем таймер резервного копирования
    super.dispose();
  }
}

Future<File> writeTasks(List<Task> tasks) async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/tasks.json');
  final data = {
    'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
    'tasks': tasks.map((e) => e.toJson()).toList(),
  };
  return file.writeAsString(json.encode(data));
}

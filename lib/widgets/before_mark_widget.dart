import 'package:aviaok/main.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/scheduler.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class BeforeMark extends StatefulWidget {
  const BeforeMark({super.key});

  @override
  State<BeforeMark> createState() => _BeforeMarkState();
}

class _BeforeMarkState extends State<BeforeMark> with TickerProviderStateMixin{

  late Ticker _ticker;
  String _formattedDate = '';

  @override
  void initState() {
    super.initState();
    _formattedDate = _getDateTime();
    _ticker = createTicker((Duration elapsed) => _updateTime())..start();
  }

  void _updateTime() {
    final now = DateTime.now();
    final newFormattedDate = DateFormat('kk:mm:ss \n EEE d MMM').format(now);
    if (newFormattedDate != _formattedDate) {
      setState(() {
        _formattedDate = newFormattedDate;
      });
    }
  }

  static String _getDateTime() {
    return DateFormat('kk:mm:ss \n EEE d MMM').format(DateTime.now());
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  bool _showMarkAnimation = false;
  bool _showDateTextAndButton = true;
  void _toggleMarkAnimation() {
    setState(() {
      _showMarkAnimation = true;
      _showDateTextAndButton = false;
    });

    Future.delayed(CheckAnimationWidget.animationDuration + const Duration(milliseconds: 400), () {
      setState(() {
        _showMarkAnimation = false;
        pageController.nextPage(duration: const Duration(milliseconds: 1), curve: Curves.easeInOut);
      });
    });
  }

  Future<List<TextEditingController>> _loadTaskControllers() async {
    List<Task> tasks = await readTasks();
    return tasks.map((task) {
      // Создаем новый TextEditingController с начальным текстом и слушателем
      var controller = TextEditingController(text: task.name);
      controller.addListener(() {
        // Обновляем значение задачи при каждом изменении текста
        task.name = controller.text;
      });
      return controller;
    }).toList();
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
  void _tryAddTask(List<TextEditingController> controllers, VoidCallback updateState) {
    if (controllers.any((controller) => controller.text.isEmpty)) {
      _showAlertPopup(context, 'Заполните название всех задач перед добавлением новой');
    } else {
      updateState();
    }
  }

  void _trySaveTasks(List<TextEditingController> controllers) {
    if (controllers.any((controller) => controller.text.isEmpty)) {
      _showAlertPopup(context, 'Нельзя сохранить задачи с пустыми названиями');
    } else {
      // Обновление каждой задачи, установка isPinned в true
      List<Task> tasks = controllers.map((controller) {
        return Task(name: controller.text, isPinned: true);
      }).toList();

      // Сохранение обновленных задач
      writeTasks(tasks);
      Navigator.of(context).pop();
    }
  }


  void _openSettings() {
    _loadTaskControllers().then((controllers) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Настройки задач'),
                content: SingleChildScrollView(
                  child: ListBody(
                    children: List<Widget>.generate(controllers.length, (index) {
                      return Row(
                        children: <Widget>[
                          Expanded(
                            child: TextField(
                              controller: controllers[index],
                              decoration: const InputDecoration(
                                hintText: 'Название задачи',
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              setState(() {
                                controllers.removeAt(index);
                              });
                            },
                          ),
                        ],
                      );
                    })
                      ..add(
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: ElevatedButton(
                            child: const Text('Добавить задачу'),
                            onPressed: () => _tryAddTask(controllers, () {
                              setState(() {
                                controllers.add(TextEditingController());
                              });
                            }),
                          ),
                        ),
                      ),
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    child: const Text('Сохранить'),
                    onPressed: () => _trySaveTasks(controllers),
                  ),
                ],
              );
            },
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (_showMarkAnimation) const CheckAnimationWidget(),
                if (_showDateTextAndButton) Text(
                    _formattedDate,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 25.0)),
                if (_showDateTextAndButton) ElevatedButton(
                    onPressed: _toggleMarkAnimation, child: const Text("Начать работу")),
              ],
            ),
          ),
          Positioned(
            right: 10,
            bottom: 10,
            child: FloatingActionButton(
              onPressed: _openSettings,
              child: const Icon(Icons.settings),
            ),
          ),
        ],
      ),
    );
  }
}

class CheckAnimationWidget extends StatefulWidget {
  const CheckAnimationWidget({super.key});
  @override
  _CheckAnimationWidgetState createState() => _CheckAnimationWidgetState();
  static const Duration animationDuration = Duration(milliseconds: 100); // Фиксированная длительность
}

class _CheckAnimationWidgetState extends State<CheckAnimationWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: CheckAnimationWidget.animationDuration,
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.5, 1.0,
          curve: Curves.easeIn,
        ),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: _controller.value,
                child: const Icon(Icons.check_circle, size: 100, color: Colors.green),
              );
            },
          ),
          FadeTransition(
            opacity: _opacityAnimation,
            child: const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text('Готово', style: TextStyle(fontSize: 24)),
            ),
          ),
        ],
      ),
    );
  }
}

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

Future<File> writeTasks(List<Task> tasks) async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/tasks.json');
  final data = {
    'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
    'tasks': tasks.map((e) => e.toJson()).toList(),
  };
  return file.writeAsString(json.encode(data));
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
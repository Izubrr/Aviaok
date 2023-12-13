import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/scheduler.dart';

class BeforeMark extends StatefulWidget {
  final VoidCallback onHide;
  const BeforeMark({super.key, required this.onHide});

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

    Future.delayed(CheckAnimationWidget.animationDuration + const Duration(seconds: 2), () {
      setState(() {
        _showMarkAnimation = false;
        widget.onHide(); // Вызывает callback
      });
    });
  }

  void _openSettings() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        List<TextEditingController> controllers = [];

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
                          onPressed: () {
                            setState(() {
                              controllers.add(TextEditingController());
                            });
                          },
                        ),
                      ),
                    ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Сохранить'),
                  onPressed: () {
                    // Логика сохранения задач
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
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
                    onPressed: _toggleMarkAnimation, child: const Text("Отметиться")),
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


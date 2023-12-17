import 'package:flutter/material.dart';
import 'widgets/before_mark_widget.dart';
import 'widgets/information_widget.dart';
import 'widgets/day_summary_widget.dart';

final PageController pageController = PageController();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aviaok',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Трекер рабочего времени'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _HomePageState();
}

class _HomePageState extends State<MyHomePage> {
  Future<bool> _onWillPop() async {
    return (await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Вы уверены?'),
        content: const Text('При закрытии приложения будет сброшен таймер'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Нет'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Да'),
          ),
        ],
      ),
    )) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          centerTitle: true,
        ),
        body: PageView(
          physics: const NeverScrollableScrollPhysics(),
          controller: pageController,
          children: [
            BeforeMark(),
            InformationWidget(),
            DaySummaryWidget(),
          ],
        ),
      ),
    );
  }
}

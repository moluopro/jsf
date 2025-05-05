import 'package:flutter/material.dart';
import 'package:jsf/jsf.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: Example());
  }
}

class Example extends StatefulWidget {
  const Example({super.key});

  @override
  State<Example> createState() => _ExampleState();
}

class _ExampleState extends State<Example> {
  String _result = '';
  final _js = JsRuntime();
  final _js2 = JsRuntime();

  void _runJS() {
    var result = _js.eval('var a = 44 + 55');
    result = _js.eval('a + 10');
     result = _js2.eval('a + 100');
    // var result = _js.eval('1.4 - 12');
    // var result = _js.eval('true');
    // var result = _js.eval('aaa');
    // var result = _js.eval('new Date().toString()');

    // test big number
    // var result = _js.eval("(123456789123456789123456789n * 2n)");
    // var result = _js.eval("(123456789123456789123456789n * 2n).toString()");

    print("------------------------------------------------------------");
    print("$result: ${result.runtimeType}");
    print("------------------------------------------------------------");

    setState(() {
      _result = result.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('JavaScript in Flutter')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _runJS,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 20,
                ),
                textStyle: const TextStyle(fontSize: 20),
              ),
              child: const Text('Run: 44 + 55'),
            ),
            const SizedBox(height: 20),
            Text('Get  $_result', style: const TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _js.dispose();
    super.dispose();
  }
}

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:jsf/jsf.dart';

void main() {
  runApp(const MyApp());
}

typedef RuntimeFactory = Runtime Function();

Runtime _createRuntime() => JsRuntime();

class MyApp extends StatelessWidget {
  const MyApp({super.key, RuntimeFactory? runtimeFactory})
      : _runtimeFactory = runtimeFactory;

  final RuntimeFactory? _runtimeFactory;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(splashFactory: InkRipple.splashFactory),
      home: Example(runtimeFactory: _runtimeFactory ?? _createRuntime),
    );
  }
}

class Example extends StatefulWidget {
  const Example({super.key, required this.runtimeFactory});

  final RuntimeFactory runtimeFactory;

  @override
  State<Example> createState() => _ExampleState();
}

class _ExampleState extends State<Example> {
  String _result = '';
  Runtime? _js;

  Runtime get _runtime => _js ??= widget.runtimeFactory();

  void _runJS() {
    var jsCode = [
      '44 + 55',
      '1.4 - 12',
      'true',
      '"aaa"',
      'new Date().toString()',
      '(123456789123456789123456789n * 2n)',
      '(123456789123456789123456789n * 2n).toString()'
    ];

    var results = [];

    for (int i = 0; i < jsCode.length; i++) {
      var result = _runtime.eval(jsCode[i]);
      results.add(result);
    }

    for (var j = 0; j < results.length; j++) {
      printDebug(results[j]);
    }

    setState(() {
      _result = results[0].toString();
    });
  }

  Future<void> _runJS2() async {
    String ajvJS = await rootBundle.loadString("assets/ajv.js");
    String test = await rootBundle.loadString("assets/test.js");

    var ajvIsLoaded = _runtime.eval("!(typeof ajv == 'undefined')");

    if (!ajvIsLoaded) {
      _runtime.eval("var window = global = globalThis; $ajvJS");
    }

    var result = _runtime.eval(test);

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
            Column(
              children: [
                ElevatedButton(
                  onPressed: _runJS,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 20),
                    textStyle: const TextStyle(fontSize: 20),
                  ),
                  child: const Text('Run: 44 + 55'),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _runJS2,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 20),
                    textStyle: const TextStyle(fontSize: 20),
                  ),
                  child: const Text('Ajv Result Info'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
                width: 550,
                child: Center(
                    child: Text(_result,
                        style: const TextStyle(fontSize: 20),
                        softWrap: true,
                        overflow: TextOverflow.visible,
                        textAlign: TextAlign.center)))
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _js?.dispose();
    super.dispose();
  }
}

printDebug(dynamic result) {
  if (kDebugMode) {
    print("------------------------------------------------------------");
    print("$result: ${result.runtimeType}");
    print("------------------------------------------------------------");
  }
}

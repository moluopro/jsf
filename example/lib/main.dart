import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/services.dart' show rootBundle;
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

  void _runJS() {
    var result = _js.eval('44 + 55');
    // var result = _js.eval('1.4 - 12');
    // var result = _js.eval('true');
    // var result = _js.eval('aaa');
    // var result = _js.eval('new Date().toString()');

    // test big number
    // var result = _js.eval("(123456789123456789123456789n * 2n)");
    // var result = _js.eval("(123456789123456789123456789n * 2n).toString()");

    printDebug(result);

    setState(() {
      _result = result.toString();
    });
  }

  void _runJS1() {
    _js.loadModule("test",
        "export function add(a, b) { return a + b; } globalThis.test = { add };");
    var result = _js.eval('test.add(4, 5)');

    printDebug(result);

    setState(() {
      _result = result.toString();
    });
  }

  Future<void> _runJS2() async {
    var ajvIsLoaded = _js.eval("!(typeof ajv == 'undefined')");

    if (ajvIsLoaded) {
      return;
    }

    String ajvJS = await rootBundle.loadString("assets/ajv.js");
    String test = await rootBundle.loadString("assets/test.js");

    _js.eval("var window = global = globalThis; $ajvJS");

    var result = _js.eval(test);

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
                  onPressed: _runJS1,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 20),
                    textStyle: const TextStyle(fontSize: 20),
                  ),
                  child: const Text('test.add(4, 5)'),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _runJS2,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 20),
                    textStyle: const TextStyle(fontSize: 20),
                  ),
                  child: const Text('Ajv Error Info'),
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
    _js.dispose();
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

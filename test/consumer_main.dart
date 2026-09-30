import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:jsf/jsf.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final js = JsRuntime();
    try {
      if (js.eval('6*7') != 42) throw StateError('Evaluation failed');
      js.registerFunction('doubleValue', (args) => (args.first as int) * 2);
      if (js.eval('doubleValue(21)') != 42) throw StateError('Callback failed');
      if (await js.evalAsync(
              'new Promise(resolve=>setTimeout(()=>resolve(42),1))') !=
          42) {
        throw StateError('Timer failed');
      }
      if (js.capabilities.abiVersion != 2) throw StateError('ABI mismatch');
      // Android routes print through the Flutter log sink, unlike fd 1.
      // ignore: avoid_print
      print('JSF_CONSUMER_OK');
    } finally {
      js.dispose();
    }
    exit(0);
  } catch (error, stack) {
    // ignore: avoid_print
    print('JSF_CONSUMER_FAILED: $error\n$stack');
    exit(1);
  }
}

import 'package:flutter/foundation.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jsf/jsf.dart';

import 'package:jsf_example/main.dart' as app;

// Usage: flutter drive --driver=integration_test/driver.dart --target=integration_test/js_runtime_test.dart -d linux

final js = JsRuntime();

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  printDebugDivider();

  group('JS_Runtime Tests', () {
    setUpAll(() async {
      app.main();
      printDebugInfo("");
      printDebugDivider();
    });

    testWidgets('Int Test', (WidgetTester tester) async {
      await tester.pumpAndSettle();
      expect(js.eval('123'), 123);
      expect(js.eval('-456'), -456);
      expect(js.eval('0'), 0);
      expect(js.eval('123 + 100'), 223);
    });

    testWidgets('BigInt Test', (WidgetTester tester) async {
      await tester.pumpAndSettle();
      expect(
        js.eval('123456789123456789123456789n * 2n'),
        BigInt.tryParse("246913578246913578246913578"),
      );
      expect(
        js.eval(
          '(123456789123456789123456789n * 2n).toString()',
        ),
        "246913578246913578246913578",
      );
    });

    testWidgets('Double Test', (WidgetTester tester) async {
      await tester.pumpAndSettle();
      expect(js.eval('123.45'), 123.45);
      expect(js.eval('-456.78'), -456.78);
      expect(js.eval('0.0'), 0.0);
      expect(js.eval('1.23 + 3.45'), 4.68);
      expect(js.eval('-1 - 55.5'), -56.5);
    });

    testWidgets('Bool Test', (WidgetTester tester) async {
      await tester.pumpAndSettle();
      expect(js.eval('true'), true);
      expect(js.eval('false'), false);
      expect(js.eval('3 == 3'), true);
      expect(js.eval('3 == 8'), false);
      expect(js.eval('true || false'), true);
    });

    testWidgets('String Test', (WidgetTester tester) async {
      await tester.pumpAndSettle();
      expect(js.eval('"hello"'), 'hello');
      expect(js.eval('"123abc"'), '123abc');
      expect(js.eval('"  spaced  "'), '  spaced  ');
    });

    testWidgets('Null Test', (WidgetTester tester) async {
      await tester.pumpAndSettle();
      expect(js.eval('null'), null);
      expect(js.eval('undefined'), null);
      expect(js.eval('  undefined  '), null);
    });
  });

  tearDownAll(() {
    printDebugDivider();
    printDebugInfo("");
    js.dispose();
  });
}

printDebugInfo(String info) {
  if (kDebugMode) {
    print(info);
  }
}

printDebugDivider() {
  printDebugInfo(
    "---------------------------------------------------------------",
  );
}

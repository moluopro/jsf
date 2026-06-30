import 'package:flutter_test/flutter_test.dart';
import 'package:jsf/jsf.dart';

import 'package:jsf_example/main.dart';

class FakeRuntime implements Runtime {
  int evalCount = 0;
  bool disposed = false;

  @override
  dynamic eval(String code, {String filename = '<eval>', bool module = false}) {
    evalCount++;
    return code == '44 + 55' ? 99 : code;
  }

  @override
  dynamic call(String functionRef, [List<Object?> arguments = const []]) =>
      null;

  @override
  void execInitScript(String code) {}

  @override
  void setGlobal(String name, Object? value) {}

  @override
  void dispose() {
    disposed = true;
  }
}

void main() {
  testWidgets('runs JavaScript from the button', (WidgetTester tester) async {
    final runtime = FakeRuntime();
    var createCount = 0;

    await tester.pumpWidget(
      MyApp(
        runtimeFactory: () {
          createCount++;
          return runtime;
        },
      ),
    );

    expect(find.text('Run: 44 + 55'), findsOneWidget);
    expect(find.text('Ajv Result Info'), findsOneWidget);
    expect(createCount, 0);
    expect(find.text('99'), findsNothing);

    await tester.tap(find.text('Run: 44 + 55'));
    await tester.pump();

    expect(createCount, 1);
    expect(runtime.evalCount, 7);
    expect(find.text('99'), findsOneWidget);
  });
}

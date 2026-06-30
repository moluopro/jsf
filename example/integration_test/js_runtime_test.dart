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
      expect(js.eval('undefined'), jsUndefined);
      expect(js.eval('  undefined  '), jsUndefined);
    });

    testWidgets('Object And Array Conversion Test',
        (WidgetTester tester) async {
      await tester.pumpAndSettle();
      expect(js.eval('[1, "two", true, null]'), [1, 'two', true, null]);
      expect(
        js.eval('({count: 2, items: ["a", "b"], nested: {ok: true}})'),
        {
          'count': 2,
          'items': ['a', 'b'],
          'nested': {'ok': true},
        },
      );
      expect(
        js.eval('({id: 1n, list: [2n, 3]})'),
        {
          'id': BigInt.one,
          'list': [BigInt.from(2), 3],
        },
      );
      expect(js.eval('Number.isNaN(NaN) && NaN'), isNaN);
      expect(js.eval('Infinity'), double.infinity);
      expect(js.eval('-Infinity'), double.negativeInfinity);
      expect(js.eval('Object.is(-0, -0) && -0'), -0.0);
      expect(
        js.eval('({missing: undefined, sparse: [1,,3]})'),
        {
          'missing': jsUndefined,
          'sparse': [1, jsArrayHole, 3],
        },
      );
      expect(
        js.eval('new Date("2026-01-02T03:04:05.000Z")'),
        DateTime.parse('2026-01-02T03:04:05.000Z'),
      );
      expect(js.eval('new Map([["a", 1], ["b", 2]])'), {'a': 1, 'b': 2});
      expect(js.eval('new Set([1, 2, 2])'), {1, 2});
      expect(js.eval('/a+/gi'), const JsRegExp('a+', 'gi'));
      expect(
        js.eval('new Uint8Array([1, 2, 3])').toString(),
        const JsTypedArray('Uint8Array', [1, 2, 3]).toString(),
      );
    });

    testWidgets('Dart To JavaScript Call Test', (WidgetTester tester) async {
      await tester.pumpAndSettle();
      js.setGlobal('dartPayload', {
        'name': 'jsf',
        'values': [1, 2, 3],
      });
      expect(js.eval('dartPayload.values.reduce((a, b) => a + b, 0)'), 6);

      js.execInitScript('function joinValues(prefix, values) {'
          'return prefix + ":" + values.join(",");'
          '}');
      expect(
          js.call('joinValues', [
            'v',
            [1, 2, 3],
          ]),
          'v:1,2,3');
    });

    testWidgets('Handle And Dart Callback Test', (WidgetTester tester) async {
      await tester.pumpAndSettle();
      final adder = js.evalValue('(function(a, b) { return a + b; })');
      try {
        final result = js.callValue(adder, [20, 22]);
        try {
          expect(result.toDart(), 42);
        } finally {
          result.dispose();
        }
      } finally {
        adder.dispose();
      }

      js.registerFunction('dartSum', (arguments) {
        return arguments.cast<num>().reduce((a, b) => a + b);
      });
      expect(js.eval('dartSum(4, 5, 6)'), 15);

      js.registerFunction('dartAsyncSum', (arguments) async {
        await Future<void>.delayed(Duration.zero);
        return arguments.cast<num>().reduce((a, b) => a + b);
      });
      expect(
          await js.evalAsync('dartAsyncSum(7, 8).then((value) => value + 1)'),
          16);
    });

    testWidgets('Bidirectional Handle Interop Test',
        (WidgetTester tester) async {
      await tester.pumpAndSettle();

      final model = js.evalValue('({count: 2, items: [3, 4], '
          'scale: function(value) { return value * this.count; }})');
      try {
        final initialCount = model.getPropertyValue('count');
        try {
          expect(initialCount.toDart(), 2);
        } finally {
          initialCount.dispose();
        }

        final nextCount = js.newValue(5);
        try {
          model.setPropertyValue('count', nextCount);
        } finally {
          nextCount.dispose();
        }

        final items = model.getPropertyValue('items');
        try {
          expect(items.length, 2);
          expect(items.getIndexValue(1).toDart(), 4);
          final replacement = js.newValue(9);
          try {
            items.setIndexValue(1, replacement);
          } finally {
            replacement.dispose();
          }
        } finally {
          items.dispose();
        }

        final scale = model.getPropertyValue('scale');
        try {
          final arg = js.newValue(6);
          try {
            final scaled = scale.callWithValues([arg], thisValue: model);
            try {
              expect(scaled.toDart(), 30);
            } finally {
              scaled.dispose();
            }
          } finally {
            arg.dispose();
          }
        } finally {
          scale.dispose();
        }

        js.registerHandleFunction('dartReadHandle', (arguments) {
          final object = arguments.first;
          final count = object.getPropertyValue('count');
          final list = object.getPropertyValue('items');
          try {
            final second = list.getIndexValue(1);
            try {
              return (count.toDart() as int) + (second.toDart() as int);
            } finally {
              second.dispose();
            }
          } finally {
            count.dispose();
            list.dispose();
          }
        });
        expect(js.call('dartReadHandle', [model]), 14);

        js.registerHandleFunction('dartReturnHandle', (arguments) {
          return arguments.first.getPropertyValue('items');
        });
        expect(js.call('dartReturnHandle', [model]), [3, 9]);
      } finally {
        model.dispose();
      }
    });

    testWidgets('Exception And Timeout Test', (WidgetTester tester) async {
      await tester.pumpAndSettle();
      expect(
        () => js.eval('throw new Error("boom")'),
        throwsA(isA<JsException>()),
      );

      final limited = JsRuntime(
        options: const JsRuntimeOptions(timeout: Duration(milliseconds: 10)),
      );
      try {
        expect(
          () => limited.eval('while (true) {}'),
          throwsA(isA<JsException>()),
        );
      } finally {
        limited.dispose();
      }
    });

    testWidgets('Promise And Module Loader Test', (WidgetTester tester) async {
      await tester.pumpAndSettle();
      expect(await js.evalAsync('Promise.resolve(42)'), 42);
      expect(
        await js.evalAsync(
          'Promise.resolve({id: 7n, text: "ok"})',
        ),
        {'id': BigInt.from(7), 'text': 'ok'},
      );

      js.registerModules({
        'math': 'export const answer = 42; '
            'export function inc(value) { return value + 1; }',
        'consumer': 'import { answer, inc } from "math"; '
            'export const result = inc(answer);',
        'pkg/math': 'export const relativeAnswer = 50;',
        'pkg/consumer': 'import { relativeAnswer } from "./math"; '
            'export const relativeResult = relativeAnswer + 1;',
        'pkg/default': 'const value = 11; export default value; '
            'export { value as namedValue };',
        'pkg/reexport': 'export * from "./math"; '
            'export { default as defaultValue, namedValue as aliasValue } from "./default";',
        'pkg/namespace': 'import * as math from "../math"; '
            'export const result = math.inc(math.answer);',
        'pkg/dynamic': 'export function loadRelative() { '
            'return import("./math").then((m) => m.relativeAnswer); }',
        'pkg/uses-relative-alias':
            'import { aliasValue } from "./alias-target"; '
                'export const result = aliasValue + 1;',
        'shared/alias-target': 'export const aliasValue = 80;',
        'pkg/counter': 'globalThis.__jsfCounter = '
            '(globalThis.__jsfCounter || 0) + 1; '
            'export const count = globalThis.__jsfCounter;',
      });
      js.registerImportMap({
        'mapped-math': 'math',
        'pkg/alias-target': 'shared/alias-target',
      });

      js.eval(
        'import { result } from "consumer"; '
        'import * as math from "math"; '
        'import defaultValue, { namedValue as aliasValue } from "pkg/default"; '
        'globalThis.staticModuleResult = result + math.inc(1) + defaultValue + aliasValue;',
        filename: 'static-module-test',
        module: true,
      );
      expect(js.eval('staticModuleResult'), 67);

      expect(
        await js.evalAsync(
          'import("math").then((m) => m.inc(m.answer))',
        ),
        43,
      );
      expect(
        await js.evalAsync(
          'import("mapped-math").then((m) => m.inc(m.answer))',
        ),
        43,
      );
      expect(
        await js.evalAsync(
          'import("pkg/consumer").then((m) => m.relativeResult)',
        ),
        51,
      );
      expect(
        await js.evalAsync(
          'import("pkg/namespace").then((m) => m.result)',
        ),
        43,
      );
      expect(
        await js.evalAsync(
          'import("pkg/default").then((m) => m.default + m.namedValue)',
        ),
        22,
      );
      expect(
        await js.evalAsync(
          'import("pkg/reexport").then((m) => m.relativeAnswer + m.defaultValue + m.aliasValue)',
        ),
        72,
      );
      expect(
        await js.evalAsync(
          'import("pkg/dynamic").then((m) => m.loadRelative())',
        ),
        50,
      );
      expect(
        await js.evalAsync(
          'import("pkg/uses-relative-alias").then((m) => m.result)',
        ),
        81,
      );
      expect(
        await js.evalAsync(
          'Promise.all([import("pkg/counter"), import("pkg/counter")])'
          '.then((modules) => modules[0].count === modules[1].count)',
        ),
        true,
      );
    });

    testWidgets('Stress And Edge Case Test', (WidgetTester tester) async {
      await tester.pumpAndSettle();
      expect(js.eval('"你好, JSF 🚀".length'), 10);
      expect(
        js.eval('Array.from(new Uint8Array([1,2,3])).join(",")'),
        '1,2,3',
      );
      expect(js.eval('let s = 0; for (let i = 0; i < 10000; i++) s += i; s'),
          49995000);

      final circular = js.evalValue('const c = {}; c.self = c; c');
      try {
        expect(() => circular.toDart(), throwsA(isA<JsException>()));
        final self = circular.getPropertyValue('self');
        try {
          expect(self.isDisposed, false);
        } finally {
          self.dispose();
        }
      } finally {
        circular.dispose();
      }

      final runtimes = List.generate(3, (_) => JsRuntime());
      try {
        for (var i = 0; i < runtimes.length; i++) {
          runtimes[i].setGlobal('runtimeIndex', i);
          expect(runtimes[i].eval('runtimeIndex + 1'), i + 1);
        }
      } finally {
        for (final runtime in runtimes) {
          runtime.dispose();
        }
      }

      final scoped = JsRuntime();
      final retained = scoped.evalValue('({ok: true})');
      scoped.dispose();
      expect(retained.isDisposed, true);
      expect(() => retained.toDart(), throwsA(isA<StateError>()));
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

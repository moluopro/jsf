@TestOn('browser')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:jsf/jsf.dart';

void main() {
  test('web module registry mirrors native module APIs', () async {
    final js = JsRuntime();
    try {
      js.registerModules({
        'math': 'export const answer = 42; '
            'export function inc(value) { return value + 1; }',
        'consumer': 'import { answer, inc } from "math"; '
            'export const result = inc(answer);',
        'pkg/math': 'export const relativeAnswer = 50;',
        'pkg/default': 'const value = 11; export default value; '
            'export { value as namedValue };',
        'pkg/reexport': 'export * from "./math"; '
            'export { default as defaultValue, namedValue as aliasValue } from "./default";',
        'pkg/native-namespace': 'export * as math from "../math";',
        'pkg/tla': 'const value = await Promise.resolve(7); '
            'export const awaited = value;',
        'pkg/namespace': 'import * as math from "../math"; '
            'export const result = math.inc(math.answer);',
        'pkg/dynamic': 'export function loadRelative() { '
            'return import("./math").then((m) => m.relativeAnswer); }',
        'pkg/uses-relative-alias':
            'import { aliasValue } from "./alias-target"; '
                'export const result = aliasValue + 1;',
        'shared/alias-target': 'export const aliasValue = 80;',
      });
      js.registerImportMap({
        'mapped-math': 'math',
        'pkg/alias-target': 'shared/alias-target',
      });

      js.eval(
        'import { result } from "consumer"; '
        'import * as math from "math"; '
        'import defaultValue, { namedValue as aliasValue } from "pkg/default"; '
        'globalThis.webModuleResult = result + math.inc(1) + defaultValue + aliasValue;',
        filename: 'web-module-test',
        module: true,
      );

      expect(js.eval('webModuleResult'), 67);
      expect(
        await js.evalAsync('import("mapped-math").then((m) => m.answer)'),
        42,
      );
      expect(
        await js.evalAsync('import("pkg/namespace").then((m) => m.result)'),
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
          'import("pkg/reexport").then((m) => m.relativeAnswer + m.defaultValue + m.aliasValue)',
        ),
        72,
      );
      expect(
        await js.evalAsync(
          'import { math } from "pkg/native-namespace"; '
          'export const result = math.inc(math.answer) + await import("pkg/tla").then((m) => m.awaited);',
          filename: 'native-web-module-test',
          module: true,
        ),
        {'result': 50},
      );
    } finally {
      js.dispose();
    }
  });
}

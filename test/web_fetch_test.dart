@TestOn('browser')
library;

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:jsf/jsf.dart';

void main() {
  test('fetch options preserve the browser implementation', () async {
    final js =
        JsRuntime(options: const JsRuntimeOptions(fetch: JsFetchOptions()));
    try {
      expect(
          js.eval(
              '[fetch,ReadableStream,Blob,File,FormData,TextDecoder,URLSearchParams].every(v=>/\\[native code\\]/.test(Function.prototype.toString.call(v)))'),
          true);
      expect(
          await js
              .evalAsync('fetch("data:text/plain,hello").then(r=>r.text())'),
          'hello');
      expect(js.eval(r'"上\u0000线\uD800"'), '上\u0000线\ud800');
      final bytes = js.newValue(Uint8List.fromList([0, 128, 255]));
      try {
        expect(bytes.toBytes(), [0, 128, 255]);
      } finally {
        bytes.dispose();
      }
    } finally {
      js.dispose();
    }
  });

  test('browser streaming and multipart remain usable', () async {
    final js =
        JsRuntime(options: const JsRuntimeOptions(fetch: JsFetchOptions()));
    try {
      expect(await js.evalAsync('''(async()=>{
        const f=new FormData();f.append('text','上线');f.append('file',new File([new Uint8Array([0,255])],'file.bin'));
        const form=await new Response(f).formData();
        let text='';for await(const part of new Blob(['上线']).stream().pipeThrough(new TextDecoderStream()))text+=part;
        return [form.get('text'),form.get('file').name,text];
      })()'''), ['上线', 'file.bin', '上线']);
    } finally {
      js.dispose();
    }
  });

  test('native URL policy is not silently ignored on Web', () {
    expect(
        () => JsRuntime(
            options: JsRuntimeOptions(
                fetch: JsFetchOptions(allowRequest: (_) => false))),
        throwsUnsupportedError);
  });
}

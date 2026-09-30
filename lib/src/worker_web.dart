import 'runtime_options.dart';

/// Background execution is currently available on native platforms.
class JsWorker {
  static Future<JsWorker> start(
          {JsRuntimeOptions options = const JsRuntimeOptions(),
          int maxPendingRequests = 128}) =>
      Future.error(UnsupportedError(
          'JsWorker requires a native Dart isolate. Check runtime.capabilities.backgroundExecution.'));
  Future<Object?> eval(String code,
          {String filename = '<eval>',
          bool module = false,
          Duration? timeout}) =>
      throw UnsupportedError('Native worker required.');
  Future<Object?> call(String function, List<Object?> arguments,
          {Duration? timeout}) =>
      throw UnsupportedError('Native worker required.');
  Future<void> setGlobal(String name, Object? value) =>
      throw UnsupportedError('Native worker required.');
  Future<void> registerModule(String name, String source) =>
      throw UnsupportedError('Native worker required.');
  Future<void> registerModules(Map<String, String> modules) =>
      throw UnsupportedError('Native worker required.');
  Future<void> registerImportMap(Map<String, String> aliases) =>
      throw UnsupportedError('Native worker required.');
  Future<void> clearModules() =>
      throw UnsupportedError('Native worker required.');
  Future<void> dispose() async {}
}

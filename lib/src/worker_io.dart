import 'dart:async';
import 'dart:isolate';

import 'exception.dart';
import 'runtime_ffi.dart';
import 'runtime_options.dart';

/// A serial JavaScript execution queue in a dedicated Dart isolate.
/// Values cross the boundary as snapshots. A request timeout closes the worker;
/// its finite execution budget allows pending native work to unwind and clean up.
class JsWorker {
  JsWorker._(this._messages, this._exits, this._errors, this._maxPending);
  final ReceivePort _messages, _exits, _errors;
  final int _maxPending;
  final _ready = Completer<void>(), _closed = Completer<void>();
  final Map<int, Completer<Object?>> _pending = {};
  SendPort? _commands;
  int _nextId = 1;
  bool _closing = false;

  static Future<JsWorker> start(
      {JsRuntimeOptions options =
          const JsRuntimeOptions(timeout: Duration(seconds: 5)),
      int maxPendingRequests = 128}) async {
    options.validate();
    if (maxPendingRequests < 1) {
      throw ArgumentError.value(maxPendingRequests, 'maxPendingRequests');
    }
    if (options.timeout == null ||
        options.onConsole != null ||
        options.onError != null ||
        options.onUnhandledRejection != null ||
        options.fetch?.transport != null ||
        options.fetch?.allowRequest != null) {
      throw ArgumentError(
          'Workers require a finite execution timeout and transferable options without host callbacks or custom transports.');
    }
    final worker = JsWorker._(
        ReceivePort(), ReceivePort(), ReceivePort(), maxPendingRequests);
    worker._messages.listen(worker._receive);
    worker._errors.listen((dynamic error) =>
        worker._fail(JsException(error.toString(), name: 'WorkerError')));
    worker._exits.listen((_) {
      worker._fail(StateError('JavaScript worker stopped.'));
      worker._finish();
    });
    try {
      await Isolate.spawn(_workerMain, [worker._messages.sendPort, options],
          onError: worker._errors.sendPort,
          onExit: worker._exits.sendPort,
          errorsAreFatal: true,
          debugName: 'jsf-worker');
      await worker._ready.future;
      return worker;
    } catch (_) {
      worker._finish();
      rethrow;
    }
  }

  void _receive(dynamic message) {
    final data = message as List;
    if (data[0] == 'ready') {
      _commands = data[1] as SendPort;
      _ready.complete();
      return;
    }
    if (data[0] == 'closed') {
      _finish();
      return;
    }
    if (data[0] == 'startupError') {
      final error = JsException.fromDetails(data[1]);
      if (!_ready.isCompleted) _ready.completeError(error);
      _finish();
      return;
    }
    final pending = _pending.remove(data[1] as int);
    if (pending == null) return;
    if (data[0] == 'result') {
      pending.complete(data[2]);
    } else {
      pending.completeError(JsException.fromDetails(data[2]));
    }
  }

  Future<Object?> _request(String operation, List<Object?> arguments,
      {Duration? timeout}) {
    if (_closing) {
      return Future.error(StateError('JavaScript worker has been disposed.'));
    }
    if (_pending.length >= _maxPending) {
      return Future.error(
          StateError('JavaScript worker queue limit exceeded.'));
    }
    if (timeout != null && timeout <= Duration.zero) {
      return Future.error(ArgumentError.value(timeout, 'timeout'));
    }
    final id = _nextId++, pending = Completer<Object?>();
    _pending[id] = pending;
    try {
      _commands!.send([id, operation, arguments]);
    } catch (error, stack) {
      _pending.remove(id);
      pending.completeError(error, stack);
    }
    if (timeout == null) return pending.future;
    return pending.future.timeout(timeout, onTimeout: () {
      // Stop the entire serial queue so timed-out scripts cannot mutate later requests.
      unawaited(dispose());
      throw JsException('JavaScript worker request timed out after $timeout.',
          name: 'TimeoutError');
    });
  }

  Future<Object?> eval(String code,
          {String filename = '<eval>',
          bool module = false,
          Duration? timeout}) =>
      _request('eval', [code, filename, module], timeout: timeout);
  Future<Object?> call(String function, List<Object?> arguments,
          {Duration? timeout}) =>
      _request('call', [function, arguments], timeout: timeout);
  Future<void> setGlobal(String name, Object? value) async {
    await _request('setGlobal', [name, value]);
  }

  Future<void> registerModule(String name, String source) async {
    await _request('registerModule', [name, source]);
  }

  Future<void> registerModules(Map<String, String> modules) async {
    await _request('registerModules', [modules]);
  }

  Future<void> registerImportMap(Map<String, String> aliases) async {
    await _request('registerImportMap', [aliases]);
  }

  Future<void> clearModules() async {
    await _request('clearModules', []);
  }

  Future<void> dispose() {
    if (!_closing) {
      _closing = true;
      _fail(StateError('JavaScript worker has been disposed.'));
      _commands?.send('close');
    }
    return _closed.future;
  }

  void _fail(Object error) {
    if (!_ready.isCompleted) _ready.completeError(error);
    for (final pending in _pending.values) {
      pending.completeError(error);
    }
    _pending.clear();
  }

  void _finish() {
    _closing = true;
    _messages.close();
    _errors.close();
    _exits.close();
    if (!_closed.isCompleted) _closed.complete();
  }
}

void _workerMain(List<Object?> bootstrap) {
  final replies = bootstrap[0] as SendPort;
  late JsRuntime runtime;
  try {
    runtime = JsRuntime(options: bootstrap[1] as JsRuntimeOptions);
  } catch (error) {
    replies.send(['startupError', _errorDetails(error)]);
    Isolate.exit();
  }
  final commands = ReceivePort();
  var closing = false;
  Future<void> queue = Future.value();
  replies.send(['ready', commands.sendPort]);
  commands.listen((dynamic message) {
    if (message == 'close') {
      closing = true;
      runtime.dispose();
      commands.close();
      replies.send(['closed']);
      Isolate.exit();
    }
    final request = message as List;
    queue = queue.then((_) async {
      if (closing) return;
      final args = request[2] as List;
      try {
        Object? result;
        switch (request[1]) {
          case 'eval':
            result = await runtime.evalAsync(args[0] as String,
                filename: args[1] as String, module: args[2] as bool);
          case 'call':
            final fn = runtime.evalValue('(${args[0]})');
            try {
              final value =
                  runtime.callValue(fn, (args[1] as List).cast<Object?>());
              try {
                result = await runtime.awaitValue(value);
              } finally {
                value.dispose();
              }
            } finally {
              fn.dispose();
            }
          case 'setGlobal':
            runtime.setGlobal(args[0] as String, args[1]);
          case 'registerModule':
            runtime.registerModule(args[0] as String, args[1] as String);
          case 'registerModules':
            runtime.registerModules((args[0] as Map).cast<String, String>());
          case 'registerImportMap':
            runtime.registerImportMap((args[0] as Map).cast<String, String>());
          case 'clearModules':
            runtime.clearModules();
          default:
            throw ArgumentError('Unknown worker operation');
        }
        if (!closing) replies.send(['result', request[0], result]);
      } catch (error) {
        if (!closing) replies.send(['error', request[0], _errorDetails(error)]);
      }
    });
  });
}

Map<String, Object?> _errorDetails(Object error) => error is JsException
    ? {
        'name': error.name,
        'message': error.message,
        'stack': error.stack,
        'cause': error.cause?.toString()
      }
    : {'name': 'WorkerError', 'message': error.toString()};

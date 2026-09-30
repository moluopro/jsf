import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'fetch.dart';

class _IoFetchTransport implements JsStreamingFetchTransport {
  _IoFetchTransport(Duration timeout) {
    _client.connectionTimeout = timeout;
  }
  final _client = HttpClient();

  @override
  Future<JsFetchResponse> send(
      JsFetchRequest request, JsFetchCancellation cancellation) async {
    cancellation.throwIfCancelled();
    final connection = await _client.openUrl(request.method, request.url);
    // An aborted upload can complete `done` before close() is reached.
    // Attach a handler immediately; awaiting close() still receives the error.
    connection.done.ignore();
    connection.followRedirects = false;
    connection.persistentConnection = true;
    final unregister =
        cancellation.onCancel((reason) => connection.abort(reason));
    try {
      cancellation.throwIfCancelled();
      for (final pair in request.headers) {
        connection.headers.add(pair[0], pair[1]);
      }
      if (request.bodyStream != null) {
        connection.bufferOutput = false;
        if (request.contentLength != null) {
          connection.contentLength = request.contentLength!;
        }
        await for (final chunk in request.bodyStream!) {
          cancellation.throwIfCancelled();
          connection.add(chunk);
          await connection.flush();
        }
        cancellation.throwIfCancelled();
      } else if (request.body != null) {
        connection.contentLength = request.body!.length;
        connection.add(request.body!);
      }
      final response = await connection.close();
      final headers = <List<String>>[];
      response.headers.forEach((name, values) {
        for (final value in values) {
          headers.add([name, value]);
        }
      });
      late StreamController<List<int>> body;
      late StreamSubscription<List<int>> subscription;
      body = StreamController<List<int>>(
        onListen: () {
          subscription =
              response.listen(body.add, onError: body.addError, onDone: () {
            unregister();
            body.close();
          });
        },
        onPause: () => subscription.pause(),
        onResume: () => subscription.resume(),
        onCancel: () {
          unregister();
          return subscription.cancel();
        },
      );
      return JsFetchResponse(
          status: response.statusCode,
          statusText: response.reasonPhrase,
          headers: headers,
          body: body.stream);
    } catch (error) {
      connection.abort(error);
      unregister();
      rethrow;
    }
  }

  @override
  void close() => _client.close(force: true);
}

/// Subscribes immediately so cancelling an unread response releases its socket.
/// StreamIterator starts listening only on its first moveNext().
class _ResponseReader {
  _ResponseReader(Stream<List<int>> stream) {
    _subscription = stream.listen((data) {
      _subscription.pause();
      current = data;
      final pending = _pending;
      _pending = null;
      pending?.complete(true);
    }, onError: (Object error, StackTrace stack) {
      _failure = error;
      final pending = _pending;
      _pending = null;
      pending?.completeError(error, stack);
    }, onDone: () {
      _ended = true;
      final pending = _pending;
      _pending = null;
      pending?.complete(false);
    });
    _subscription.pause();
  }
  late final StreamSubscription<List<int>> _subscription;
  Completer<bool>? _pending;
  bool _ended = false;
  Object? _failure;
  List<int> current = const [];
  Future<bool> moveNext() {
    if (_failure != null) return Future.error(_failure!);
    if (_ended) return Future.value(false);
    final pending = _pending = Completer<bool>();
    _subscription.resume();
    return pending.future;
  }

  Future<void> cancel() {
    _ended = true;
    current = const [];
    final pending = _pending;
    _pending = null;
    pending?.complete(false);
    return _subscription.cancel();
  }
}

/// One exchange owns its connection, reader, deadlines and completion signal.
class _Exchange {
  _Exchange(this.id, this.owner);
  final int id;
  final NativeFetch owner;
  final cancellation = JsFetchCancellation();
  final completed = Completer<Object?>();
  _ResponseReader? iterator;
  Uint8List? chunk;
  int offset = 0, received = 0;
  bool connecting = true, finished = false, reading = false, watching = false;
  Object? failure;
  int bufferedBytes = 0;
  NativeFetchUpload? upload;
  bool closing = false;
  Future<void> closed = Future.value();
  Timer? deadline, headersDeadline;

  void finish([Object? reason]) {
    if (finished) return;
    finished = true;
    failure = reason;
    deadline?.cancel();
    headersDeadline?.cancel();
    releaseChunk();
    if (reason != null) cancellation.cancel(reason);
    final reader = iterator;
    if (reader != null) {
      closing = true;
      closed = reader.cancel().catchError((Object _) {}).whenComplete(() {
        closing = false;
        release();
      });
    }
    completed.complete(reason);
    // Do not release a pending connection's slot until the transport settles.
    release();
  }

  void releaseChunk() {
    if (chunk != null) {
      owner._bufferedBytes -= chunk!.length;
      chunk = null;
    }
  }

  void release() {
    if (finished && !connecting && !closing && (watching || iterator == null)) {
      owner._requests.remove(id);
    }
  }
}

/// Keeps the JS producer alive while the transport pulls it on demand.
class NativeFetchUpload {
  NativeFetchUpload(
      {required this.read,
      required this.cancel,
      required this.release,
      this.replay});
  final Future<Uint8List?> Function() read;
  final void Function(Object reason) cancel;
  final void Function() release;
  final void Function()? replay;
}

/// Owns only its own in-flight operations, even with a shared injected transport.
class NativeFetch {
  NativeFetch(this.options)
      : _transport =
            options.transport ?? _IoFetchTransport(options.headersTimeout) {
    options.validate();
  }
  final JsFetchOptions options;
  final JsFetchTransport _transport;
  final _requests = <int, _Exchange>{};
  bool _disposed = false;
  int get activeRequests => _requests.length;
  int _bufferedBytes = 0;
  int get bufferedBytes => _bufferedBytes;
  void _reserveBuffer(int bytes) {
    if (_bufferedBytes + bytes > options.maxTotalBufferedBytes) {
      throw const JsFetchException(
          'TypeError', 'Fetch aggregate buffer limit exceeded.');
    }
    _bufferedBytes += bytes;
  }

  Future<Map<String, Object?>> send(int id, Map request, Uint8List? bytes,
      {NativeFetchUpload? upload}) async {
    if (_disposed) {
      throw const JsFetchException('AbortError', 'Runtime disposed.');
    }
    if (_requests.containsKey(id) ||
        _requests.length >= options.maxConcurrentRequests) {
      throw const JsFetchException(
          'TypeError', 'Fetch concurrency limit exceeded.');
    }
    if ((bytes?.length ?? 0) > options.maxRequestBytes) {
      throw const JsFetchException(
          'TypeError', 'Fetch request body limit exceeded.');
    }
    final state = _Exchange(id, this);
    _requests[id] = state;
    state.upload = upload;
    final failed = Completer<Map<String, Object?>>();
    final unregister = state.cancellation.onCancel((reason) {
      upload?.cancel(reason);
      if (!failed.isCompleted) failed.completeError(reason);
    });
    if (options.timeout != null) {
      state.deadline = Timer(
          options.timeout!,
          () => state.finish(const JsFetchException(
              'TimeoutError', 'Fetch deadline exceeded.')));
    }
    state.headersDeadline = Timer(
        options.headersTimeout,
        () => state.finish(const JsFetchException(
            'TimeoutError', 'Fetch response headers timed out.')));
    final operation = _exchangeWithUpload(request, bytes, state).then((result) {
      state.headersDeadline?.cancel();
      return result;
    }).catchError((Object error) {
      final reason = _networkError(error);
      state.finish(reason);
      throw reason;
    }).whenComplete(() {
      state.connecting = false;
      _bufferedBytes -= state.bufferedBytes;
      state.bufferedBytes = 0;
      state.release();
    });
    try {
      return await Future.any([operation, failed.future]);
    } finally {
      unregister();
    }
  }

  Stream<List<int>> _uploadStream(_Exchange state) async* {
    var sent = 0;
    while (true) {
      state.cancellation.throwIfCancelled();
      final interrupted = Completer<Uint8List?>();
      final unregister = state.cancellation.onCancel((reason) {
        if (!interrupted.isCompleted) interrupted.completeError(reason);
      });
      Uint8List? chunk;
      try {
        var pending = state.upload!.read();
        if (options.uploadIdleTimeout != null) {
          pending = pending.timeout(options.uploadIdleTimeout!,
              onTimeout: () => throw const JsFetchException(
                  'TimeoutError', 'Fetch upload producer stalled.'));
        }
        chunk = await Future.any([pending, interrupted.future]);
      } finally {
        unregister();
      }
      state.cancellation.throwIfCancelled();
      if (chunk == null) return;
      sent += chunk.length;
      if (sent > options.maxRequestBytes) {
        throw const JsFetchException(
            'TypeError', 'Fetch request body limit exceeded.');
      }
      _reserveBuffer(chunk.length);
      try {
        yield chunk;
      } finally {
        _bufferedBytes -= chunk.length;
      }
    }
  }

  Future<Map<String, Object?>> _exchangeWithUpload(
      Map request, Uint8List? bytes, _Exchange state) async {
    if (state.upload != null && _transport is! JsStreamingFetchTransport) {
      final builder = BytesBuilder(copy: false);
      await for (final chunk in _uploadStream(state)) {
        // During aggregation the original chunks and the contiguous result may coexist.
        _reserveBuffer(chunk.length * 2);
        state.bufferedBytes += chunk.length * 2;
        builder.add(chunk);
      }
      bytes = builder.takeBytes();
      _bufferedBytes -= bytes.length;
      state.bufferedBytes -= bytes.length;
    }
    return _exchange(request, bytes, state);
  }

  static JsFetchException _networkError(Object error) =>
      error is JsFetchException
          ? error
          : const JsFetchException('TypeError', 'Network request failed.');

  Future<Map<String, Object?>> _exchange(
      Map request, Uint8List? bytes, _Exchange state) async {
    final cancellation = state.cancellation;
    var url = Uri.parse(request['url'] as String);
    if (!url.hasScheme && options.baseUrl != null) {
      url = options.baseUrl!.resolveUri(url);
    }
    var method = request['method'] as String;
    var headers = (request['headers'] as List)
        .map((p) => (p as List).cast<String>().toList())
        .toList();
    var redirected = false;
    var streaming =
        state.upload != null && _transport is JsStreamingFetchTransport;
    for (var redirects = 0;; redirects++) {
      cancellation.throwIfCancelled();
      if (!const ['http', 'https'].contains(url.scheme) ||
          !url.hasAuthority ||
          url.host.isEmpty ||
          url.userInfo.isNotEmpty ||
          options.allowRequest?.call(url) == false) {
        throw const JsFetchException(
            'TypeError', 'Fetch URL is not permitted.');
      }
      url = url.removeFragment();
      final response = await _transport.send(
          JsFetchRequest(
              url: url,
              method: method,
              headers: headers,
              body: bytes,
              bodyStream: streaming ? _uploadStream(state) : null,
              contentLength:
                  streaming ? request['bodyLength'] as int? : bytes?.length),
          cancellation);
      if (cancellation.isCancelled) {
        await response.body.listen((_) {}).cancel();
        cancellation.throwIfCancelled();
      }
      final locations =
          response.headers.where((h) => h[0].toLowerCase() == 'location');
      final isRedirect =
          const [301, 302, 303, 307, 308].contains(response.status) &&
              locations.isNotEmpty;
      if (isRedirect) {
        await response.body.listen((_) {}).cancel();
        final mode = request['redirect'];
        if (mode != 'follow' || redirects >= options.maxRedirects) {
          if (mode == 'manual') {
            state.finish();
            return {
              'status': 0,
              'statusText': '',
              'headers': <List<String>>[],
              'url': '',
              'redirected': false,
              'type': 'opaqueredirect',
              'hasBody': false
            };
          }
          throw const JsFetchException(
              'TypeError', 'Fetch redirect rejected or limit exceeded.');
        }
        final next = url.resolve(locations.first[1]);
        if (next.origin != url.origin) {
          headers.removeWhere((h) => const [
                'authorization',
                'proxy-authorization',
                'cookie',
                'cookie2'
              ].contains(h[0].toLowerCase()));
        }
        if (((response.status == 301 || response.status == 302) &&
                method == 'POST') ||
            (response.status == 303 && method != 'GET' && method != 'HEAD')) {
          method = 'GET';
          bytes = null;
          streaming = false;
          headers.removeWhere((h) => const [
                'content-type',
                'content-encoding',
                'content-language',
                'content-location'
              ].contains(h[0].toLowerCase()));
        }
        if (streaming) {
          final replay = state.upload!.replay;
          if (replay == null) {
            throw const JsFetchException('TypeError',
                'Cannot replay a streaming upload after a redirect.');
          }
          replay();
        }
        url = next;
        redirected = true;
        continue;
      }
      final hasBody = method != 'HEAD' &&
          !const [0, 204, 205, 304].contains(response.status);
      if (hasBody) {
        // The reader pauses the subscription between pulls. Never drain a
        // socket into an unbounded Dart controller while JS is not reading.
        state.iterator = _ResponseReader(response.body);
      } else {
        await response.body.listen((_) {}).cancel();
        state.finish();
      }
      return {
        'status': response.status,
        'statusText': response.statusText,
        'url': url.toString(),
        'headers': response.headers,
        'redirected': redirected,
        'type': 'default',
        'hasBody': hasBody
      };
    }
  }

  /// Completion is observed independently of pulls, so an absolute deadline also
  /// errors a paused JS reader. A successful completion returns null.
  Future<Map<String, String>?> watch(int id) async {
    final state = _requests[id];
    if (state == null) return null;
    state.watching = true;
    state.release();
    final reason = await state.completed.future;
    if (reason == null) return null;
    final error = _networkError(reason);
    return {'name': error.name, 'message': error.message};
  }

  Future<Uint8List?> read(int id) async {
    final state = _requests[id];
    if (state == null) return null;
    if (state.reading) {
      throw const JsFetchException('TypeError', 'Concurrent body pull.');
    }
    state.reading = true;
    try {
      if (state.failure != null) throw state.failure!;
      if (state.finished) return null;
      while (state.chunk == null || state.offset == state.chunk!.length) {
        state.releaseChunk();
        state.offset = 0;
        var next = state.iterator!.moveNext();
        if (options.bodyIdleTimeout != null) {
          next = next.timeout(options.bodyIdleTimeout!,
              onTimeout: () => throw const JsFetchException(
                  'TimeoutError', 'Fetch response body stalled.'));
        }
        final interrupted = Completer<bool>();
        final unregister = state.cancellation.onCancel((reason) {
          if (!interrupted.isCompleted) interrupted.completeError(reason);
        });
        late bool hasNext;
        try {
          hasNext = await Future.any<bool>([next, interrupted.future]);
        } finally {
          unregister();
        }
        if (state.failure != null) throw state.failure!;
        if (!hasNext) {
          state.finish();
          return null;
        }
        final data = state.iterator!.current;
        state.received += data.length;
        if (options.maxResponseBytes != null &&
            state.received > options.maxResponseBytes!) {
          throw const JsFetchException(
              'TypeError', 'Fetch response body limit exceeded.');
        }
        _reserveBuffer(data.length);
        state.chunk = data is Uint8List ? data : Uint8List.fromList(data);
      }
      final end = (state.offset + 65536).clamp(0, state.chunk!.length);
      final result = Uint8List.sublistView(state.chunk!, state.offset, end);
      state.offset = end;
      return result;
    } catch (error) {
      final reason = _networkError(error);
      state.finish(reason);
      throw reason;
    } finally {
      state.reading = false;
    }
  }

  Future<void> cancel(int id) {
    final state = _requests[id];
    if (state == null) return Future.value();
    state.watching = true;
    state.finish(
        const JsFetchException('AbortError', 'The request was aborted.'));
    state.release();
    return state.closed;
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    for (final state in List.of(_requests.values)) {
      state.finish(const JsFetchException('AbortError', 'Runtime disposed.'));
    }
    _requests.clear();
    if (options.transport == null) _transport.close();
  }
}

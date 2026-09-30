import 'dart:async';
import 'dart:typed_data';

/// Opt-in native Fetch with streaming responses and multipart bodies.
/// Web uses the browser's own Fetch API and resource policies.
class JsFetchOptions {
  const JsFetchOptions({
    this.timeout,
    this.headersTimeout = const Duration(seconds: 30),
    this.bodyIdleTimeout = const Duration(seconds: 30),
    this.maxConcurrentRequests = 16,
    this.maxRequestBytes = 8 * 1024 * 1024,
    this.maxTotalBufferedBytes = 32 * 1024 * 1024,
    this.uploadIdleTimeout = const Duration(seconds: 30),
    this.maxResponseBytes,
    this.maxBufferedBodyBytes = 8 * 1024 * 1024,
    this.maxCloneBufferBytes = 8 * 1024 * 1024,
    this.maxFormDataParts = 1024,
    this.maxMultipartHeaderBytes = 16 * 1024,
    this.maxMultipartPartBytes = 8 * 1024 * 1024,
    this.maxRedirects = 20,
    this.baseUrl,
    this.allowRequest,
    this.transport,
  });

  /// Total deadline, including redirects and reading the response body.
  final Duration? timeout;

  /// Deadline for response headers, including redirects.
  final Duration headersTimeout;

  /// Maximum wait for the next network chunk while a reader demands data.
  /// Paused consumers do not count as network inactivity. Null disables it.
  final Duration? bodyIdleTimeout;
  final int maxConcurrentRequests;
  final int maxRequestBytes;

  /// Aggregate limit for buffers retained by the native transport bridge.
  final int maxTotalBufferedBytes;

  /// Maximum time waiting for the next chunk requested from an upload producer.
  final Duration? uploadIdleTimeout;

  /// Optional cumulative response limit; null permits long-lived streams.
  final int? maxResponseBytes;

  /// Limit for text/json/bytes/arrayBuffer/blob/formData aggregation.
  final int maxBufferedBodyBytes;

  /// Maximum queued bytes per slow branch created by Response/Request.clone().
  final int maxCloneBufferBytes;
  final int maxFormDataParts;
  final int maxMultipartHeaderBytes;

  /// Maximum buffered bytes per part for incremental formDataParts().
  final int maxMultipartPartBytes;
  final int maxRedirects;
  final Uri? baseUrl;

  /// Optional policy checked before every request, including every redirect.
  final bool Function(Uri url)? allowRequest;

  /// Borrowed transport. JSF cancels its requests but does not close this object.
  /// A null value creates a runtime-owned dart:io transport.
  final JsFetchTransport? transport;

  void validate() {
    if ((timeout != null && timeout! <= Duration.zero) ||
        headersTimeout <= Duration.zero ||
        (bodyIdleTimeout != null && bodyIdleTimeout! <= Duration.zero) ||
        maxConcurrentRequests < 1 ||
        maxRequestBytes < 0 ||
        maxTotalBufferedBytes < 0 ||
        (uploadIdleTimeout != null && uploadIdleTimeout! <= Duration.zero) ||
        (maxResponseBytes != null && maxResponseBytes! < 0) ||
        maxBufferedBodyBytes < 0 ||
        maxCloneBufferBytes < 0 ||
        maxFormDataParts < 1 ||
        maxMultipartHeaderBytes < 1 ||
        maxMultipartPartBytes < 0 ||
        maxRedirects < 0) {
      throw ArgumentError(
          'Fetch deadlines and concurrency must be positive; byte and redirect limits must be nonnegative.');
    }
    if (baseUrl != null &&
        (!baseUrl!.hasAuthority ||
            !const ['http', 'https'].contains(baseUrl!.scheme))) {
      throw ArgumentError.value(
          baseUrl, 'baseUrl', 'Expected an absolute HTTP(S) URL.');
    }
  }
}

/// One HTTP exchange. Redirects are managed by JSF, not by the transport.
class JsFetchRequest {
  const JsFetchRequest(
      {required this.url,
      required this.method,
      required this.headers,
      this.body,
      this.bodyStream,
      this.contentLength});
  final Uri url;
  final String method;
  final List<List<String>> headers;
  final Uint8List? body;

  /// Single-subscription upload; only supplied to JsStreamingFetchTransport.
  final Stream<List<int>>? bodyStream;
  final int? contentLength;
}

class JsFetchResponse {
  const JsFetchResponse(
      {required this.status,
      required this.statusText,
      required this.headers,
      required this.body});
  final int status;
  final String statusText;
  final List<List<String>> headers;
  final Stream<List<int>> body;
}

/// A transport must honor cancellation during connection, upload and download.
abstract class JsFetchTransport {
  Future<JsFetchResponse> send(
      JsFetchRequest request, JsFetchCancellation cancellation);
  void close();
}

/// A transport that consumes request.bodyStream on demand and honors cancellation.
/// Other transports receive a bounded, buffered body for compatibility.
abstract class JsStreamingFetchTransport implements JsFetchTransport {}

/// A cancellation token for one HTTP exchange.
class JsFetchCancellation {
  Object? _reason;
  final _listeners = <void Function(Object)>[];
  bool get isCancelled => _reason != null;
  Object? get reason => _reason;

  void throwIfCancelled() {
    if (_reason != null) throw _reason!;
  }

  /// Returns a function that unregisters the listener.
  void Function() onCancel(void Function(Object reason) listener) {
    if (_reason != null) {
      listener(_reason!);
    } else {
      _listeners.add(listener);
    }
    return () => _listeners.remove(listener);
  }

  void cancel([Object? reason]) {
    if (_reason != null) return;
    _reason = reason ??
        const JsFetchException('AbortError', 'The request was aborted.');
    final listeners = List.of(_listeners);
    _listeners.clear();
    for (final listener in listeners) {
      try {
        listener(_reason!);
      } catch (_) {/* Other listeners must still run. */}
    }
  }
}

class JsFetchException implements Exception {
  const JsFetchException(this.name, this.message);
  final String name;
  final String message;
  @override
  String toString() => '$name: $message';
}

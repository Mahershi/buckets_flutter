/// Base class for all Buckets SDK exceptions
abstract class BucketsException implements Exception {
  final String message;
  final dynamic cause;

  const BucketsException(this.message, {this.cause});

  @override
  String toString() =>
      '$runtimeType: $message${cause != null ? ' (caused by: $cause)' : ''}';
}

// ─── Connection Exceptions ────────────────────────────────────────────────────

class BucketsConnectionException extends BucketsException {
  const BucketsConnectionException({
    String message = "Failed to connect to server",
    dynamic cause,
  }) : super(message, cause: cause);
}

class BucketsConnectionTimeoutException extends BucketsException {
  const BucketsConnectionTimeoutException({
    String message = "Connection timed out",
    dynamic cause,
  }) : super(message, cause: cause);
}

class BucketsConnectionDroppedException extends BucketsException {
  final int? closeCode;
  final String? closeReason;

  const BucketsConnectionDroppedException({
    String message = "Connection dropped unexpectedly",
    this.closeCode,
    this.closeReason,
    dynamic cause,
  }) : super(message, cause: cause);

  @override
  String toString() =>
      '$runtimeType: $message (code: $closeCode, reason: $closeReason)';
}

class BucketsMaxRetriesExceededException extends BucketsException {
  final int retries;

  const BucketsMaxRetriesExceededException({
    this.retries = 0,
    String message = "Max retries exceeded",
    dynamic cause,
  }) : super(message, cause: cause);

  @override
  String toString() =>
      '$runtimeType: $message (retries: $retries)';
}

// ─── Auth Exceptions ──────────────────────────────────────────────────────────

class BucketsAuthException extends BucketsException {
  const BucketsAuthException({
    String message = "Authentication failed",
    dynamic cause,
  }) : super(message, cause: cause);
}

class BucketsAuthTimeoutException extends BucketsException {
  const BucketsAuthTimeoutException({
    String message = "Authentication timed out",
    dynamic cause,
  }) : super(message, cause: cause);
}

// ─── Fetch / Query Exceptions ─────────────────────────────────────────────────

class BucketsFetchTimeoutException extends BucketsException {
  const BucketsFetchTimeoutException({
    String message = "Fetch request timed out",
    dynamic cause,
  }) : super(message, cause: cause);
}

class BucketsQueryException extends BucketsException {
  const BucketsQueryException({
    String message = "Query configuration failed",
    dynamic cause,
  }) : super(message, cause: cause);
}

// ─── Data Exceptions ──────────────────────────────────────────────────────────

class BucketsParseException extends BucketsException {
  const BucketsParseException({
    String message = "Failed to parse server response",
    dynamic cause,
  }) : super(message, cause: cause);
}

class BucketsSnapshotTypeException extends BucketsException {
  const BucketsSnapshotTypeException({
    String message = "Unexpected snapshot type",
    dynamic cause,
  }) : super(message, cause: cause);
}

class BucketsInvalidArgumentException extends BucketsException {
  const BucketsInvalidArgumentException(super.message, {super.cause});
}

// ─── Server Exceptions ────────────────────────────────────────────────────────

class BucketsServerException extends BucketsException {
  const BucketsServerException({
    String message = "Server returned an error",
    dynamic cause,
  }) : super(message, cause: cause);
}

// ─── Domain / App-Level Exceptions (merged & cleaned) ─────────────────────────

class BucketsUnauthAccessException extends BucketsException {
  const BucketsUnauthAccessException({
    String message = "Unauthorized access",
    dynamic cause,
  }) : super(message, cause: cause);
}

class BucketsNotFoundException extends BucketsException {
  const BucketsNotFoundException({
    String message = "Requested resource not found",
    dynamic cause,
  }) : super(message, cause: cause);
}

class BucketsWsException extends BucketsException {
  const BucketsWsException({
    String message = "WebSocket error",
    dynamic cause,
  }) : super(message, cause: cause);
}

class BucketsUnknownException extends BucketsException {
  const BucketsUnknownException({
    String message = "Unknown error occurred",
    dynamic cause,
  }) : super(message, cause: cause);
}

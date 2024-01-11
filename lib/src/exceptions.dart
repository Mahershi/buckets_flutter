class UnauthAccess implements Exception{
  String cause;

  UnauthAccess(this.cause);
}

class BucketNotFound implements Exception{
  String cause;

  BucketNotFound(this.cause);
}

class UnknownException implements Exception{
  String cause;

  UnknownException(this.cause);
}
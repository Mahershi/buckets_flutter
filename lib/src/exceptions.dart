class UnauthAccess implements Exception{
  String cause;

  UnauthAccess(this.cause);

  @override
  String toString(){
    return this.cause;
  }
}

class BucketNotFound implements Exception{
  String cause;

  BucketNotFound(this.cause);

  @override
  String toString(){
    return this.cause;
  }
}

class UnknownException implements Exception{
  String cause;

  UnknownException(this.cause);

  @override
  String toString(){
    return this.cause;
  }
}
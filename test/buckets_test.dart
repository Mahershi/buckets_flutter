import 'package:flutter_test/flutter_test.dart';

import 'package:buckets/buckets.dart';

void main() {
  test('Should Work', () async {
    await BucketAuth.loginWithCredentials("mahershi1999@gmail.com", "mahershi");
    var ub = await Buckets.bucket('1');
    expect(true, true);
  });

  test('Should Throw Exception 401: User has no access', () async {
    await BucketAuth.loginWithCredentials("mahershi1999@gmail.com", "mahershi");
    expect(() async {
      await Buckets.bucket('5');
    }, throwsException);
  });

  test('Should Throw Exception 404: Bucket Not Exist', () async {
    await BucketAuth.loginWithCredentials("mahershi1999@gmail.com", "mahershi");

    expect(() async {
      await Buckets.bucket('12');
    }, throwsException);
  });

}

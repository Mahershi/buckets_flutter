import 'package:flutter_test/flutter_test.dart';

import 'package:buckets/buckets.dart';

void main() {
  test('Should Work', () async {
    await BucketAuth.clientLogin("b07c4d0709dc7b3cfaa3bc6a4b80cc5a", "W8nmcKwxEdc_KZqYVxhLXqU5rcb30gznN21UBUD66uE");
    var ub = await Buckets.project();
    expect(true, true);
  });

  test('Should Throw Exception 401: User has no access', () async {
    await BucketAuth.clientLogin("b07c4d0709dc7b3cfaa3bc6a4b80cc5a", "W8nmcKwxEdc_KZqYVxhLXqU5rcb30gznN21UBUD66uE");
    expect(() async {
      await Buckets.project();
    }, throwsException);
  });

  test('Should Throw Exception 404: Bucket Not Exist', () async {
    await BucketAuth.clientLogin("b07c4d0709dc7b3cfaa3bc6a4b80cc5a", "W8nmcKwxEdc_KZqYVxhLXqU5rcb30gznN21UBUD66uE");
    expect(() async {
      await Buckets.project();
    }, throwsException);
  });

}

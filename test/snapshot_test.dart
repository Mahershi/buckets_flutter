import 'package:buckets/src/models/bucket.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:buckets/src/authentication/auth.dart' as auth;
import 'package:buckets/buckets.dart';
import 'package:logging/logging.dart';

void main() {
  Buckets.setLogLevel(level: Level.ALL);
  Buckets.switchToDevelopment();
  test('Should Work', () async {
    await BucketAuth.clientLogin("b07c4d0709dc7b3cfaa3bc6a4b80cc5a", "W8nmcKwxEdc_KZqYVxhLXqU5rcb30gznN21UBUD66uE");
    var ub = await Buckets.project();
    ProjectReference ref = ub.getReference();
    ref.snapshots().listen((event) {
      print(event.data.toString());
    });

    await Future.delayed(Duration(seconds: 5));
    ref.close();

    expect(true, true);
  });


}

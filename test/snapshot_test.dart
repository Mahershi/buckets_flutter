import 'package:buckets/src/models/bucket.dart';
import 'package:buckets/src/bucket_snapshot.dart';
import 'package:buckets/src/client.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:buckets/src/authentication/auth.dart' as auth;
import 'package:buckets/buckets.dart';
import 'package:logging/logging.dart';

void main() {
  Buckets.setLogLevel(level: Level.ALL);
  Buckets.switchToDevelopment();
  test('Should Work', () async {
    await auth.BucketAuth.clientLogin("448dd712addad98eece8e2cc2724a2e0", "r2dbBBRMrId_zwjHtFddI0aXtaofL94L93CUA5ETKh0");
    Client c = Buckets.client();

    c.snapshots().listen((event) {
      print(event.data.toString());
    });
    await Future.delayed(Duration(seconds: 5));
    c.disconnect();

    expect(true, true);
  });


}

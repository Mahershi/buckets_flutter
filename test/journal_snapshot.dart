import 'package:buckets/src/models/bucket.dart';
import 'package:buckets/src/bucket_snapshot.dart';
import 'package:buckets/src/client.dart';
import 'package:buckets/src/references/JournalReference.dart';
import 'package:buckets/src/snapshots/JournalSnapshot.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:buckets/src/authentication/auth.dart' as auth;
import 'package:buckets/buckets.dart';
import 'package:logging/logging.dart';

void main() {
  Buckets.setLogLevel(level: Level.ALL);
  Buckets.switchToDevelopment();
  test('Should Work', () async {
    await auth.BucketAuth.clientLogin("130a15b34349ed79d0cadd73c1dbf5b2", "X7odcWuJil9wznMzkY3z_z1lj8iCojnxTVk_U5401EE");



    expect(true, true);
  });


}

import 'package:buckets/src/models/bucket.dart';
import 'package:buckets/src/references/JournalReference.dart';
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
    ProjectReference pref = ub.getReference();
    pref.snapshots().listen((event) {
      print(event.data.toString());
    });

    Journal j = await ub.journal("23");
    Record r = await j.record("r4");
    RecordReference rref = r.getReference();

    rref.snapshots().listen((event) {
      print(event.data.toString());
    });
    final stopwatch = Stopwatch()..start();
    rref.setMap(
      field: "apimap",
      data: {
        "subarrya": ["one","hello"]
      }
    );
    stopwatch.stop();
    print('Update operation time: ${stopwatch.elapsedMilliseconds} ms');
    await Future.delayed(Duration(seconds: 5));
    pref.close();
    // rref.close();
    expect(true, true);
  });


}

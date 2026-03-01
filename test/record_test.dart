import 'package:buckets/src/references/JournalReference.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:buckets/src/authentication/auth.dart' as auth;
import 'package:buckets/buckets.dart';
import 'package:logging/logging.dart';

void main() async {

  Buckets.setLogLevel(level: Level.ALL);
  Buckets.switchToDevelopment();

  test('No Filter Query', () async {
    await auth.BucketAuth.clientLogin(
        "0541a883e0e521872a42e7491ef50292",
        "aidQUpSVzWBh_QwnhPaTY9UEbhGSSIUZ-E0Ofn-VB6w"
    );
    Project p = Buckets.project();
    print(p);
    Journal j = await p.journal("test");
    print(j.name);
    Record r = await j.record("r1");
    RecordReference rr = r.getReference();
    RecordSnapshot snap = await rr.snapshots().first;

    print(snap.data);
    expect(true, true);
  });



}

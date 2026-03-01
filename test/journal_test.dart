import 'package:buckets/src/references/JournalReference.dart';
import 'package:buckets/src/snapshots/JournalSnapshot.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:buckets/src/authentication/auth.dart' as auth;
import 'package:buckets/buckets.dart';
import 'package:logging/logging.dart';

void main() async {
  print("in main");

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
    JournalReference jr = j.getReference();
    JournalSnapshot js = await jr.snapshots().first;
    for (RecordSnapshot i in js.data['records']){
      print(i.name);
    }
    expect(true, true);
  });

  test('Filter Query', () async {
    await auth.BucketAuth.clientLogin(
        "0541a883e0e521872a42e7491ef50292",
        "aidQUpSVzWBh_QwnhPaTY9UEbhGSSIUZ-E0Ofn-VB6w"
    );
    Project p = Buckets.project();
    print(p);
    Journal j = await p.journal("test");
    print(j.name);
    // able to chain multiple filters on different fields.
    // not able to chain multiple Operators on same fields.
    // like value less than x and greater than y for the same field.
    JournalReference jr = j.getReference().where("s", greaterThan: 1).where("adult", equalTo: false);
    JournalSnapshot js = await jr.snapshots().first;
    for (RecordSnapshot i in js.data['records']){
      print(i.name);
    }
    expect(true, true);
  });
  
}

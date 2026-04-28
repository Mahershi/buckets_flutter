import 'package:buckets/src/references/JournalReference.dart';
import 'package:buckets/src/snapshots/JournalSnapshot.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:buckets/src/authentication/auth.dart' as auth;
import 'package:buckets/buckets.dart';
import 'package:logging/logging.dart';

void main() async {
  print("in main");

  Buckets.setLogLevel(level: Level.ALL);
  Buckets.switchToStaging();

  test('No Filter Query', () async {
    await auth.BucketAuth.clientLogin(
        "864b8fe1f263e2e96649cd645b388545",
        "Jjug4iI8bx-w24XB8lFf3rxBKnSv79p1HIMZ8EGdpkU"
    );
    Project p = Buckets.project();
    print(p);
    Journal j = await p.journal("gol");
    print(j.name);
    JournalReference jr = j.getReference();
    JournalSnapshot js = await jr.snapshots().first;
    for (RecordSnapshot i in js.data['records']){
      print(i.name);
    }

    await Future.delayed(Duration(seconds: 10));
    expect(true, true);
  });

  // test('Filter Query', () async {
  //   await auth.BucketAuth.clientLogin(
  //       "864b8fe1f263e2e96649cd645b388545",
  //       "Jjug4iI8bx-w24XB8lFf3rxBKnSv79p1HIMZ8EGdpkU"
  //   );
  //   Project p = Buckets.project();
  //   print(p);
  //   Journal j = await p.journal("gol");
  //   print(j.name);
  //   // able to chain multiple filters on different fields.
  //   // not able to chain multiple Operators on same fields.
  //   // like value less than x and greater than y for the same field.
  //   JournalReference jr = j.getReference().where("s", greaterThan: 1).where("adult", equalTo: false);
  //   JournalSnapshot js = await jr.snapshots().first;
  //   for (RecordSnapshot i in js.data['records']){
  //     print(i.name);
  //   }
  //   expect(true, true);
  // });
  
}

import 'package:flutter_test/flutter_test.dart';

import 'package:buckets/buckets.dart';

void main(){
  test('Should Work', () async {
    await BucketAuth.loginWithCredentials("mahershi1999@gmail.com", "mahershi");
    var ub = await Buckets.bucket('1');
    var ub2 = await Buckets.bucket('10');

    ub.snapshots().listen((event) {
      print("UB: " + event.toString());
    });

    ub2.snapshots().listen((event){
      print("UB2: " + event.toString());
    });

    ub.setInt(field: 'new', value:2);

    expect(true, true);
  });
}
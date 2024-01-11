import 'dart:async';

import 'package:buckets/buckets.dart';
import 'package:buckets/src/bucket_snapshot.dart';

void main() async {
  removeFieldTest();
}

void removeFieldTest() async {
  bool authSuccess = await BucketAuth.loginWithCredentials("mahershi1999@gmail.com", "mahershi");
  print("AUth: $authSuccess");

  UserBucket ub = await Buckets.bucket('7');

  ub.removeField(field: "NEW STR");
}

void setStringTest() async {
  bool authSuccess = await BucketAuth.loginWithCredentials("mahershi1999@gmail.com", "mahershi");
  print("AUth: $authSuccess");

  UserBucket ub = await Buckets.bucket('7');
  await ub.setString(field: "NEW STR", value: "HELLO");
  await ub.setInt(field: "NEW INT", value: 1);
  await ub.setDouble(field: "NEW DOUBLE", value: 1.23);
  await ub.setBool(field: "NEW BOOL", value: true);
}

void sameBucket() async {
  bool authSuccess = await BucketAuth.loginWithCredentials("mahershi1999@gmail.com", "mahershi");
  print("AUth: $authSuccess");

  UserBucket ub = await Buckets.bucket('1');
  UserBucket ub2 = await Buckets.bucket('1');

  ub.snapshots().listen((event) {
    print("Listener 1: ${event.name}");
  });

  ub2.snapshots().listen((event) {
    print("Listener 2: ${event.name}");
  });

  await Future.delayed(Duration(seconds: 5));
  print("closed");
  ub.disconnect();

  UserBucket ub3 = await Buckets.bucket('1');
  ub3.snapshots().listen((event) {
    print("Listener 3: ${event.name}");
  });
}

void multipleBuckets() async {
  bool authSuccess = await BucketAuth.loginWithCredentials("mahershi1999@gmail.com", "mahershi");
  print("AUth: $authSuccess");

  UserBucket ub = await Buckets.bucket('1');
  UserBucket ub2 = await Buckets.bucket('2');

  StreamController<BucketSnapshot> c1 = StreamController<BucketSnapshot>();
  StreamController<BucketSnapshot> c2 = StreamController<BucketSnapshot>();

  c1.stream.listen((BucketSnapshot event) {
    print("Stream 1: ${event.name}");
  });

  c2.stream.listen((BucketSnapshot event) {
    print("Stream 2: ${event.name}");
  });

  ub.snapshots().listen((event) {
    c1.sink.add(event);
  });

  ub2.snapshots().listen((event) {
    c2.sink.add(event);
  });

  print("Created ALL");
  await Future.delayed(Duration(seconds: 10), (){
    ub.disconnect();
    print("Disconnected 1");
  });
}
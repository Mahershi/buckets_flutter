import 'dart:io';

import 'package:buckets/buckets.dart';
import 'package:web_socket_channel/web_socket_channel.dart';


void main() async {
  Stopwatch stopwatch = new Stopwatch();
  stopwatch.start();
  Buckets.switchToStaging();
  await BucketAuth.loginWithCredentials("mahershi1999@gmail.com", "mahershi");
  print("Login Time: " + stopwatch.elapsed.toString());
  stopwatch.reset();
  var ub = await Buckets.bucket('3');
  print(ub.bucket.name);
  print("Bucket Fetch Time: " + stopwatch.elapsed.toString());
  stopwatch.reset();
}
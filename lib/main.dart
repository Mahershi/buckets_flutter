import 'dart:io';

import 'package:buckets/buckets.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() async {
  Stopwatch stopwatch = new Stopwatch();
  stopwatch.start();
  // Buckets.switchToStaging();
  await BucketAuth.loginWithCredentials("mahershi1999@gmail.com", "mahershi");
  print("Login Time: " + stopwatch.elapsed.toString());
  stopwatch.reset();
  var ub = await Buckets.bucket('1');
  print(ub.bucket.name);
  print("Bucket Fetch Time: " + stopwatch.elapsed.toString());
  stopwatch.reset();
  // ub.removeField(field: 'DartMap');

  // await ub.setString(field: "new", value: "test");
  await ub.setMap(
    field: "DartMap",
    data: {
      "one": "two",
      "submap": {
        "one": "111111",
        "two": "222222"
      }
    }
  );
  print("Update Time: " + stopwatch.elapsed.toString());
}

Future<void> testWS() async {
  String s = "ws://localhost:8000/bucket/stream/1/?Authorization=Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoiYWNjZXNzIiwiZXhwIjoxNzI0NTk4Njk0LCJpYXQiOjE3MjQ1OTE0OTQsImp0aSI6ImRkNDEyNTYwZTJhOTQ2NzM5ZWQ3Y2E4Y2FlNzNkNzlkIiwidXNlcl9pZCI6MX0.mxBMQ-d23TibKPTjX6XJ7s6dtrRkD05soVj6c15_QMo";
  print(s);
  Uri uri = Uri.parse(s);
  WebSocketChannel ws = WebSocketChannel.connect(uri);

  await ws.ready;
  ws.sink.add("Hello");
  print("Ready");
}
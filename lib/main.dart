import 'package:buckets/buckets.dart';

void main() async {
  Stopwatch stopwatch = new Stopwatch();
  stopwatch.start();
  await BucketAuth.loginWithCredentials("mahershi1999@gmail.com", "mahershi");
  print("Login Time: " + stopwatch.elapsed.toString());
  stopwatch.reset();
  var ub = await Buckets.bucket('10');
  print("Bucket Fetch Time: " + stopwatch.elapsed.toString());
  stopwatch.reset();
  // ub.removeField(field: 'DartMap');

  ub.setString(field: "new", value: "test");
  ub.setMap(
    field: "DartMap",
    data: {
      "one": "two",
    }
  );
  print("Update Time: " + stopwatch.elapsed.toString());

}
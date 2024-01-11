import 'package:flutter_test/flutter_test.dart';
import 'package:buckets/src/auth.dart' as auth;

void main(){
  test('Correct Auth', () async {
    expect(
        await auth.BucketAuth.loginWithCredentials("mahershi1999@gmail.com", "mahershi"),
        true
    );
  });


  test("Incorrect Auth", () async {
    expect(
        await auth.BucketAuth.loginWithCredentials("mahershi1999@gmail.com", "mah"),
        false
    );
  });
}

import 'package:buckets/buckets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:buckets/src/authentication/auth.dart' as auth;
import 'package:logging/logging.dart';

void main(){
  Buckets.setLogLevel(level: Level.ALL);
  Buckets.switchToDevelopment();
  test('Correct Auth', () async {
    expect(
        await auth.BucketAuth.clientLogin("9695c4d5c93629eea247dec4fc68f626", "gL4hpNdXojMBfsNw5B3wFDikRFacvQnf7TUNp_Dlg7M"),
        true
    );
  });


  test("Incorrect Auth", () async {
    expect(
        await auth.BucketAuth.clientLogin("448dd712addad98eece8e2cc2724a2e0", "2dA5ETKh0"),
        false
    );
  });
}

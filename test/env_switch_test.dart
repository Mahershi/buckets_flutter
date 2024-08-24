import 'package:buckets/src/config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:buckets/src/auth.dart' as auth;

void main(){
  test('ENV Switch DEVELOPMENT', () async {
    Config.setEnvironment(Environment.DEVELOPMENT);
    expect(
        Config.currentEnvironment, Environment.DEVELOPMENT
    );
  });


  test("ENV Switch STAGING", () async {
    Config.setEnvironment(Environment.STAGING);
    expect(
        Config.currentEnvironment, Environment.STAGING
    );
  });
}

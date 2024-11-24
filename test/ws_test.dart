import 'package:buckets/buckets.dart';
import 'package:buckets/src/WSHandler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:buckets/src/authentication/auth.dart' as auth;
import 'package:logging/logging.dart';
import 'package:web_socket_channel/io.dart';


void main(){
  Buckets.setLogLevel(level: Level.ALL);
  Buckets.switchToDevelopment();
  test('Correct WS Auth', () async {
    await auth.BucketAuth.clientLogin("448dd712addad98eece8e2cc2724a2e0", "r2dbBBRMrId_zwjHtFddI0aXtaofL94L93CUA5ETKh0");
    expect(
        (await WSHandler().updateChannel("61")).runtimeType,
        IOWebSocketChannel
    );
    await Future.delayed(Duration(seconds: 5));
  });


  // disable auth when testing this
  test('Auth not sent', () async {
    await auth.BucketAuth.clientLogin("448dd712addad98eece8e2cc2724a2e0", "r2dbBBRMrId_zwjHtFddI0aXtaofL94L93CUA5ETKh0");
    expect(
        (await WSHandler().updateChannel("61", auth: false)).runtimeType,
        Null
    );
    await Future.delayed(Duration(seconds: 13));
  });

}

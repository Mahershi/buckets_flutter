import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:buckets/src/authentication/auth.dart' as auth;
import 'package:buckets/buckets.dart';
import 'package:logging/logging.dart';

void main() {
  Buckets.setLogLevel(level: Level.ALL);
  Buckets.switchToDevelopment();
  test('Should Work', () async {
    await auth.BucketAuth.clientLogin("9695c4d5c93629eea247dec4fc68f626", "gL4hpNdXojMBfsNw5B3wFDikRFacvQnf7TUNp_Dlg7M");
    Project p = Project("4", "Test", "", true);
    File file = File("/Users/mahershibhavsar/Downloads/Me/MahershiShailendraBhavsar.pdf");
    String publicUrl = await p.putFile(
      file: file,
      path: "subdir/subdir2"
    );
    print("File Test done, Public Url: " + publicUrl);

    expect(true, true);
  });


}

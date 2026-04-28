import 'dart:async';


import 'package:buckets/buckets.dart';

import 'package:logging/logging.dart';




void main() async {
  Buckets.setLogLevel(level: Level.ALL);
  Buckets.switchToDevelopment();
  await BucketAuth.userLoginWithCredentials("mahershi1999@gmail.com", "mahershi");
  print(BucketAuth.curUser);
}

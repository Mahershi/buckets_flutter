import 'dart:async';


import 'package:buckets/buckets.dart';
import 'package:buckets/src/models/Journal.dart';
import 'package:buckets/src/models/Project.dart';
import 'package:buckets/src/references/MinJournalReference.dart';
import 'package:buckets/src/references/RecordReference.dart';
import 'package:logging/logging.dart';
import 'package:buckets/src/models/Record.dart';



void main() async {
  Buckets.setLogLevel(level: Level.ALL);
  Buckets.switchToDevelopment();
  await BucketAuth.userLoginWithCredentials("mahershi1999@gmail.com", "mahershi");
  print(BucketAuth.curUser);
}

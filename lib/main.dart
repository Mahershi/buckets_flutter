import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:buckets/buckets.dart';
import 'package:buckets/src/references/JournalReference.dart';
import 'package:buckets/src/references/ProjectReference.dart';
import 'package:buckets/src/references/RecordReference.dart';
import 'package:buckets/src/references/Reference.dart';
import 'package:buckets/src/config.dart';
import 'package:buckets/src/snapshots/ProjectSnapshot.dart';
import 'package:buckets/src/snapshots/Snapshot.dart';
import 'package:logging/logging.dart';
import 'package:web_socket_channel/web_socket_channel.dart';


void main() async {
  Buckets.setLogLevel(level: Level.ALL);
  Buckets.switchToDevelopment();
  await BucketAuth.clientLogin("9695c4d5c93629eea247dec4fc68f626", "gL4hpNdXojMBfsNw5B3wFDikRFacvQnf7TUNp_Dlg7M");
  await Future.delayed(Duration(seconds: 2));

  ProjectReference r = ProjectReference("ws://localhost:8000/project/stream/4");
  r.snapshots().listen((event) {
    print(event);
  });
  // //
  JournalReference jr = JournalReference("ws://localhost:8000/journal/stream/9");
  jr.snapshots().listen((event) {
    print(event);
  });

  await Future.delayed(Duration(seconds: 2));
  // jr.createRecord("API_record");

  jr.deleteRecord("rec1");
  // RecordReference rr = RecordReference("ws://localhost:8000/record/stream/2");
  // rr.snapshots().listen((event){
  //   print("1: " + event.toString());
  // });



}

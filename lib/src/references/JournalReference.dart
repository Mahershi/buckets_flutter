import 'dart:async';
import 'dart:convert';

import 'package:buckets/src/references/Reference.dart';
import 'package:buckets/src/snapshots/JournalSnapshot.dart';
import 'package:logging/logging.dart';

final Logger _logger = Logger("JournalReference");


class JournalReference extends Reference{
  JournalReference(super.wsUrl);

  @override
  Stream<JournalSnapshot> snapshots(){
    return super.snapshots().map((snapshot){
      if (snapshot is JournalSnapshot)
        return snapshot;
      else
        throw Exception("Unexpected Snapshot Type");
    });
  }

  @override
  Stream<JournalSnapshot> parseMessage(Stream broadcast) {
    // controller for stream ID:1
    StreamController<JournalSnapshot> controller = StreamController<JournalSnapshot>();
    broadcast.listen((event) {
      // convert string event to ProjectSnapshot object
      Map<String, dynamic> jsonEvent = jsonDecode(event);

      controller.sink.add(JournalSnapshot(
          jsonEvent['data']['id'].toString(),
          jsonEvent['data']['name'],
          jsonEvent['data']['value']
      ));
    });
    return controller.stream;
  }

  Future<void> createRecord(String name) async {
    _logger.fine("createRecord() name: " + name);
    try{
      Map<String, dynamic> jsonData = {
        "type": "add_record",
        "data": {"name": "$name"}
      };
      _logger.fine("createRecord() Message: " + jsonData.toString());
      await update(jsonData);
    }catch(e){
      _logger.severe("createRecord() Exception: " + e.toString());
    }
  }

  Future<void> deleteRecord(String name) async {
    _logger.fine("removeRecord() name: " + name);
    try{
      Map<String, dynamic> jsonData = {
        "type": "remove_record",
        "data": {"name": "$name"}
      };
      _logger.fine("removeRecord() Message: " + jsonData.toString());
      await update(jsonData);
    }catch(e){
      _logger.severe("removeRecord() Exception: " + e.toString());
    }
  }

}
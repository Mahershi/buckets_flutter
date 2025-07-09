import 'dart:async';
import 'dart:convert';

import 'package:buckets/buckets.dart';
import 'package:buckets/src/references/Reference.dart';
import 'package:logging/logging.dart';

final Logger _logger = Logger("JournalReference");


class JournalReference extends Reference{
  JournalReference(super.wsUrl);



  JournalSnapshot eventMap(Map<String, dynamic> event){
    switch(event['type']){
      case 'update':
        return _update(event);
      case 'update_record':
        return _update_record(event);
      case 'remove_record':
        return _remove_record(event);
    }
    return JournalSnapshot("", "", {});
  }


  // TODO: will probably return a list of Record Snapshots
  @override
  Stream<JournalSnapshot> snapshots(){
    return super.snapshots().map((snapshot){
      if (snapshot is JournalSnapshot)
        return snapshot;
      else {
        _logger.severe("Snapshot Type is not JournalSnapshot");
        throw Exception("Unexpected Snapshot Type");
      }
    });
  }

  @override
  Stream<JournalSnapshot> parseMessage(Stream broadcast) {
    // controller for stream ID:1
    StreamController<JournalSnapshot> controller = StreamController<JournalSnapshot>();
    broadcast.listen((event) {
      // convert string event to ProjectSnapshot object
      Map<String, dynamic> jsonEvent = jsonDecode(event);
      // 1. "update" event - full snapshot
      // 2. "update_record" - update the record id in the prev snapshot and sink it
      // 3. "remove_record" - remove the record id in the prev snapshot and sink it.
      controller.sink.add(eventMap(jsonEvent));
    });
    return controller.stream;
  }

  static JournalSnapshot _update(Map<String, dynamic> event){
    List<RecordSnapshot> records = [];
    for(var recordDump in event['data']['value']['records']){
      records.add(
        RecordSnapshot(
            recordDump['id'].toString(),
            recordDump['name'],
            recordDump['value']
        )
      );
    }

    return JournalSnapshot(
        event['data']['id'].toString(),
        event['data']['name'],
        {"records": records}
    );
  }

  JournalSnapshot _remove_record(Map<String, dynamic> event){
    String recidToRemove = event['data']['id'].toString();
    List<RecordSnapshot> records = [];
    for(RecordSnapshot recordSnap in this.prevSnapshot.data['records']){
      if(recordSnap.id != recidToRemove){
        records.add(recordSnap);
      }
    }

    return JournalSnapshot(
        this.prevSnapshot.id,
        this.prevSnapshot.name,
        {'records': records}
    );
  }

  JournalSnapshot _update_record(Map<String, dynamic> event){
    String recidToUpdate = event['data']['id'].toString();
    List<RecordSnapshot> records = [];
    bool updatedExisting = false;
    for(RecordSnapshot recordSnap in this.prevSnapshot.data['records']){
      if(recordSnap.id != recidToUpdate){
        records.add(recordSnap);
      }else{
        updatedExisting = true;
        records.add(
          RecordSnapshot(recidToUpdate, event['data']['name'], event['data']['value'])
        );
      }
    }

    if(!updatedExisting){
      records.add(
          RecordSnapshot(recidToUpdate, event['data']['name'], event['data']['value'])
      );
    }

    return JournalSnapshot(
        this.prevSnapshot.id,
        this.prevSnapshot.name,
        {'records': records}
    );
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
    }catch(e, stackTrace){
      _logger.severe("createRecord() Exception: ", e, stackTrace);
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
    }catch(e, stackTrace){
      _logger.severe("removeRecord() Exception: ", e, stackTrace);
    }
  }

}
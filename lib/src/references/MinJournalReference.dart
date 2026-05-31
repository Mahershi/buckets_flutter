import 'dart:async';
import 'package:buckets/src/references/Reference.dart';
import 'package:buckets/src/snapshots/MinJournalSnapshot.dart';
import 'package:logging/logging.dart';

final Logger _logger = Logger("JournalReference");


class MinJournalReference extends Reference{
  MinJournalReference(super.wsUrl);

  @override
  Stream<MinJournalSnapshot> snapshots(){
    return super.snapshots().map((snapshot){
      if (snapshot is MinJournalSnapshot)
        return snapshot;
      else {
        _logger.severe("Snapshot Type is not JournalSnapshot");
        throw Exception("Unexpected Snapshot Type");
      }
    });
  }

  @override
  Stream<MinJournalSnapshot> parseMessage(Stream broadcast) {
    return baseParse<MinJournalSnapshot>(
      broadcast,
          (data) => MinJournalSnapshot(
        data['id'].toString(),
        data['name'],
        data['value'],
      ),
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
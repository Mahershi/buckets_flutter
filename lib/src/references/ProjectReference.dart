import 'dart:async';
import 'dart:convert';

import 'package:buckets/src/references/Reference.dart';
import 'package:buckets/src/snapshots/ProjectSnapshot.dart';
import 'package:logging/logging.dart';

final Logger _logger = Logger("ProjectReference");

class ProjectReference extends Reference{
  ProjectReference(super.wsUrl);

  @override
  Stream<ProjectSnapshot> snapshots(){
    return super.snapshots().map((snapshot){
      if (snapshot is ProjectSnapshot)
        return snapshot;
      else{
        _logger.severe("Snapshot Type is not ProjectSnapshot");
        throw Exception("Unexpected Snapshot Type");
      }
    });
  }

  @override
  Stream<ProjectSnapshot> parseMessage(Stream broadcast) {
    // controller for stream ID:1
    StreamController<ProjectSnapshot> controller = StreamController<ProjectSnapshot>();
    broadcast.listen((event) {
      // convert string event to ProjectSnapshot object
      Map<String, dynamic> jsonEvent = jsonDecode(event);
      controller.sink.add(ProjectSnapshot(
        jsonEvent['data']['id'].toString(),
        jsonEvent['data']['name'],
        jsonEvent['data']['value']
      ));
    });
    return controller.stream;
  }

  Future<void> createJournal(String name) async {
    _logger.fine("createJournal() name: " + name);
    try{
      Map<String, dynamic> jsonData = {
        "type": "add_journal",
        "data": {"name": "$name"}
      };
      _logger.fine("createJournal() Message: " + jsonData.toString());
      await update(jsonData);
    }catch(e, stackTrace){
      _logger.severe("createJournal() Exception: ", e, stackTrace);
    }
  }

  Future<void> deleteJournal(String name) async {
    _logger.fine("removeJournal() name: " + name);
    try{
      Map<String, dynamic> jsonData = {
        "type": "remove_journal",
        "data": {"name": "$name"}
      };
      _logger.fine("removeJournal() Message: " + jsonData.toString());
      await update(jsonData);
    }catch(e, stackTrace){
      _logger.severe("removeJournal() Exception: ", e, stackTrace);
    }
  }
}
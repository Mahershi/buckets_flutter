import 'dart:async';
import 'dart:convert';
import 'package:buckets/buckets.dart';
import 'package:logging/logging.dart';

final Logger _logger = Logger("JournalReference");

class JournalReference extends MinJournalReference {
  JournalReference(
  super.wsUrl, {Map<String, Map<String, dynamic>>? filters}
  ) : _filters = filters ?? const {};
  final Map<String, Map<String, dynamic>> _filters;

  static const int _maxEtListSize = 20;

  bool _isScalar(dynamic v) =>
      v is int || v is double || v is String || v is bool;

  bool _isScalarList(dynamic v) =>
      v is List && v.every(_isScalar);

  dynamic _normalizeEt(dynamic value) {
    if (_isScalar(value)) return [value.toString()];

    if (_isScalarList(value)){
      return (value as List).map((v) => v.toString()).toList();
    }

    throw ArgumentError(
      'ET must be int/double/string/bool OR List of those',
    );
  }

  @override
  Future<bool> configureQuery(Stream stream) {
    Map<String, dynamic> query = {
      "filters": _filters,
    };
    _logger.info("Configuring Query with ${query}");
    _logger.warning("Only one operator can be applied on a field. If multiple set, latest will be considered, limitation from backend.");
    Completer<bool> completer = Completer<bool>();
    late StreamSubscription sub;
    sub = stream.listen((event){
      Map<String, dynamic> json = jsonDecode(event);
      if (json['type'] == 'query'){
        if(checkQueryResponse(json)){
          completer.complete(true);
          _logger.fine("Query configured successfully!");
          sub.cancel();
        }else{
          completer.complete(false);
          _logger.severe("Error configuring query!");
          sub.cancel();
        }
      }else if (json['type'] == 'error'){
        _logger.severe("Error configuring query: ${json['error']}");
      }
      _logger.warning('Unknown event while waiting for query configuration: ${json['type']}');
    });
    wsHandler.sendMessage({
      "type": "query",
      "data": query
    });
    return completer.future;

  }

  JournalReference where(String field, {
    dynamic equalTo,
    dynamic lessThan,
    dynamic lessThanEqualTo,
    dynamic greaterThan,
    dynamic greaterThanEqualTo,
    dynamic regEx
  }){
    final ops = {
      "et": equalTo,
      "lt": lessThan,
      "le": lessThanEqualTo,
      "gt": greaterThan,
      "ge": greaterThanEqualTo,
      "re": regEx
    }..removeWhere((k, v) => v == null);

    if (ops.length != 1) {
      throw ArgumentError("Exactly one operator must be provided to where()");
    }

    final op = ops.keys.first;
    var value = ops.values.first;

    if (op == "et") {
      if (value is List) {
        if (value.length > _maxEtListSize) {
          throw ArgumentError(
              "ET supports max $_maxEtListSize values"
          );
        }
        if (value.isEmpty) {
          throw ArgumentError("ET list cannot be empty");
        }
        // optional: prevent nested lists/maps
        for (final v in value) {
          if (v is List || v is Map) {
            throw ArgumentError("ET list must contain primitive values only");
          }
        }

      }
      value = _normalizeEt(value);
    }

    final newFilters = Map<String, Map<String, dynamic>>.from(_filters);

    newFilters.putIfAbsent(field, ()=>{});
    newFilters[field]![op] = value;

    return JournalReference(
      // couldn't pass handler bcz then they would share broadcast stream.
      wsUrl,
      filters: newFilters,
    );
  }

  bool checkQueryResponse(Map<String, dynamic> event){
    // what if query or data key itself not sent.
    return event['data']['query'] == 'Success';
  }

  JournalSnapshot eventMap(Map<String, dynamic> event){
    switch(event['type']){
      case 'update':
        return _update(event);
      case 'update_record':
        return _update_record(event);
      case 'remove_record':
        return _remove_record(event);
    }
    _logger.warning("Unexpected message: ${event['type']}");
    return JournalSnapshot.empty();
    // return JournalSnapshot("", "", <String, dynamic>{});
  }


  // TODO: will probably return a list of Record Snapshots
  @override
  Stream<JournalSnapshot> snapshots(){
    return super.snapshots().map((snapshot){
      if (snapshot is JournalSnapshot){
        print("returning JournalSnapshot");
        return snapshot;
      }
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
      print(jsonEvent);
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
      print(recordDump['name']);
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


  // Future<void> createRecord(String name) async {
  //   _logger.fine("createRecord() name: " + name);
  //   try{
  //     Map<String, dynamic> jsonData = {
  //       "type": "add_record",
  //       "data": {"name": "$name"}
  //     };
  //     _logger.fine("createRecord() Message: " + jsonData.toString());
  //     await update(jsonData);
  //   }catch(e, stackTrace){
  //     _logger.severe("createRecord() Exception: ", e, stackTrace);
  //   }
  // }
  //
  // Future<void> deleteRecord(String name) async {
  //   _logger.fine("removeRecord() name: " + name);
  //   try{
  //     Map<String, dynamic> jsonData = {
  //       "type": "remove_record",
  //       "data": {"name": "$name"}
  //     };
  //     _logger.fine("removeRecord() Message: " + jsonData.toString());
  //     await update(jsonData);
  //   }catch(e, stackTrace){
  //     _logger.severe("removeRecord() Exception: ", e, stackTrace);
  //   }
  // }

}
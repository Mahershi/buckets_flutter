import 'dart:async';
import 'dart:convert';
import 'package:buckets/buckets.dart';
import 'package:logging/logging.dart';

import '../models/exceptions.dart';

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
      _logger.fine(json);
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
      } else {
        _logger.warning('Unknown event while waiting for query configuration: ${json['type']}');
      }

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
      default:
        _logger.warning("Ignoring non-data event: ${event['type']}");
        throw const BucketsParseException();
    }
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

  // this logic has custom logic mapping based on event type
  // cannot directly use _baseParse from parent.
  // any change in parent _baseParse, need to be propagated here as well
  @override
  Stream<JournalSnapshot> parseMessage(Stream broadcast) {
    late StreamController<JournalSnapshot> controller;
    StreamSubscription? subscription;
    controller = StreamController<JournalSnapshot>(
      onCancel: () async {
        await subscription?.cancel();
      },
    );
    subscription = broadcast.listen(
          (event) {
        try {
          final jsonEvent = jsonDecode(event);
          final type = jsonEvent['type'];
          switch (type) {
            case 'update':
            case 'update_record':
            case 'remove_record':
            controller.add(eventMap(jsonEvent));
            break;

            case 'query':
            case 'authentication':
            // expected control events → ignore
            break;

            default:
            _logger.warning("Unknown event type: $type");
            // ignore, but DO NOT emit empty snapshot
          }
        } catch (e) {
          controller.addError(
            BucketsParseException(cause: e),
          );
        }
      },
      onError: (error) {
        controller.addError(error);
      },
      onDone: () {
        controller.close();
      },
      cancelOnError: false,
    );
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
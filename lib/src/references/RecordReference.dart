import 'dart:async';
import 'dart:convert';

import 'package:buckets/src/references/Reference.dart';
import 'package:buckets/src/snapshots/RecordSnapshot.dart';
import 'package:logging/logging.dart';

import '../config.dart';

final Logger _logger = Logger("RecordReference");

class RecordReference extends Reference{
  RecordReference(super.wsUrl);

  @override
  Stream<RecordSnapshot> snapshots(){
    return super.snapshots().map((snapshot){
      if (snapshot is RecordSnapshot)
        return snapshot;
      else{
        _logger.severe("Snapshot Type is not RecordSnapshot");
        throw Exception("Unexpected Snapshot Type");
      }
    });
  }

  @override
  Stream<RecordSnapshot> parseMessage(Stream broadcast) {
    // controller for stream ID:1
    StreamController<RecordSnapshot> controller = StreamController<RecordSnapshot>();
    broadcast.listen((event) {
      // convert string event to ProjectSnapshot object
      Map<String, dynamic> jsonEvent = jsonDecode(event);
      controller.sink.add(RecordSnapshot(
          jsonEvent['data']['id'].toString(),
          jsonEvent['data']['name'],
          jsonEvent['data']['value']
      ));

    });
    return controller.stream;
  }

  @override
  Map<String, dynamic> _set(String field, {dynamic value=''}) {
    return <String, dynamic>{
      "type": "add_field",
      "data": {
        "key": field,
        "value": value
      }
    };
  }

  Map<String, dynamic> _set_array_element(String array_path, String value, String type){
    return <String, dynamic>{
      "type": "add_array_element",
      "data": {
        "key": array_path,
        "value": value,
        "type": type
      }
    };
  }

  Map<String, dynamic> _remove_array_element(String array_path, String value){
    return <String, dynamic>{
      "type": "remove_array_element",
      "data": {
        "key": array_path,
        "value": value,
      }
    };
  }

  Map<String, dynamic> _update_array_element(String array_path, String value, String new_value){
    return <String, dynamic>{
      "type": "update_array_element",
      "data": {
        "key": array_path,
        "value": value,
        "new_value": new_value
      }
    };
  }

  // To set a string field.
  // Note, all the set* methods will receive the initial Update snapshot on the websocket connection
  // It can be ignored for now.
  Future<void> setString({String? field, String? value}) async {
    _logger.fine("setString() field: " + field! + ", value: " + value!);
    try{
      Map<String, dynamic> jsonData = _set(field, value: value);
      jsonData['data']['type'] = Config.typeMap['STRING'].toString();
      _logger.fine("setString() Message: " + jsonData.toString());
      await update(jsonData);
    }catch(e, stackTrace){
      _logger.severe("setString() Exception: ", e, stackTrace);
    }
  }

  Future<void> setInt({String? field, int? value}) async {
    _logger.fine("setInt() field: " + field! + ", value: " + value!.toString());
    try{
      Map<String, dynamic> jsonData = _set(field, value: value.toString());
      jsonData['data']['type'] = Config.typeMap['NUMBER'].toString();
      _logger.fine("setInt() Message: " + jsonData.toString());
      await update(jsonData);
    }catch(e, stackTrace){
      _logger.severe("setInt() Exception: ", e, stackTrace);
    }
  }

  Future<void> setDouble({String? field, double? value}) async {
    _logger.fine("setDouble() field: " + field! + ", value: " + value!.toString());
    try{
      Map<String, dynamic> jsonData = _set(field, value: value.toString());
      jsonData['data']['type'] = Config.typeMap['NUMBER'].toString();
      _logger.fine("setDouble() Message: " + jsonData.toString());
      await update(jsonData);
    }catch(e, stackTrace){
      _logger.severe("setDouble() Exception: ", e, stackTrace);
    }
  }

  Future<void> setBool({String? field, bool? value}) async {
    _logger.fine("setBool() field: " + field! + ", value: " + value!.toString());
    try{
      Map<String, dynamic> jsonData = _set(field, value: value.toString());
      jsonData['data']['type'] = Config.typeMap['BOOLEAN'].toString();
      _logger.fine("setBool() Message: " + jsonData.toString());
      await update(jsonData);
    }catch(e, stackTrace){
      _logger.severe("setBool() Exception: ", e, stackTrace);
    }
  }

  Future<void> removeField({String? field}) async {
    _logger.fine("removeField() Field: " + field!);
    try{
      Map<String, dynamic> jsonData = {
        "type": "remove_field",
        "data": {
          "key": field
        }
      };
      _logger.fine("removeField() Message: " + jsonData.toString());
      await update(jsonData);
    }catch(e, stackTrace){
      _logger.severe("removeField() Exception: ", e, stackTrace);
    }
  }

  // TODO: Implement adding of Array inside of Map on the backend.
  Map<String, dynamic> _populate_map_fields({Map<dynamic, dynamic> data = const {}}){
    Map<String, dynamic> fields = {};
    data.forEach((key, value) async {
      fields[key] = {};
      if (value.runtimeType == String){
        fields[key]['value'] = value;
        fields[key]['type'] = Config.typeMap['STRING'].toString();
      }else if(value.runtimeType == bool){
        fields[key]['value'] = value;
        fields[key]['type'] = Config.typeMap['BOOLEAN'].toString();
      }else if(value.runtimeType == int || value.runtimeType == double){
        fields[key]['value'] = value;
        fields[key]['type'] = Config.typeMap['NUMBER'].toString();
      }else if(value is Map){
        fields[key]['value'] = _populate_map_fields(data: value);
        fields[key]['type'] = Config.typeMap['MAP'].toString();
      }else if(value is List){
        fields[key]['value'] = _populate_array_fields(items: value);
        fields[key]['type'] = Config.typeMap['ARRAY'].toString();
      }else{
        // Unsupported Data Type Array inside Map.
        // TODO: Handle Exception.
        _logger.warning("setMap() Unsupported Data Type");
      }
    });

    return fields;
  }

  // Recursively sets a Map field considering presence of sub maps. Adv Testing pending, basics tested.
  Future<void> setMap({String? field, Map<dynamic, dynamic> data = const {}}) async {
    _logger.fine("setMap() field: " + field!, ", data:" + data.toString());
    try{
      // Create the empty map field
      Map<String, dynamic> jsonData = _set(field, value: {});
      jsonData['data']['type'] = Config.typeMap['MAP'].toString();
      _logger.fine("setMap() Message: " + jsonData.toString());

      // Set Map key value pairs.
      Map<String, dynamic> fields = _populate_map_fields(data: data);
      jsonData['data']['value'] = fields;
      await update(jsonData);

    }catch(e, stackTrace){
      _logger.severe("setMap() Exception: ", e, stackTrace);
    }
  }

  List<Map<String, dynamic>> _populate_array_fields(
      {List<dynamic> items = const []}){
    List<Map<String, dynamic>> fields = [];

    for (var item in items){
      Map<String, dynamic> field = {};
      if (item.runtimeType == String){
        field['value'] = item;
        field['type'] = Config.typeMap['STRING'].toString();
      }else if(item.runtimeType == bool){
        field['value'] = item;
        field['type'] = Config.typeMap['BOOLEAN'].toString();
      }else if(item.runtimeType == int || item.runtimeType == double){
        field['value'] = item;
        field['type'] = Config.typeMap['NUMBER'].toString();
      }else if(item is Map){
        field['value'] = _populate_map_fields(data: item);
        field['type'] = Config.typeMap['MAP'].toString();
      }
      fields.add(field);
    }
    return fields;
  }

  // Creates Array if not existing and adds the element if any passed.
  // NOTE: support added for an Array of Maps - but not supported by backend yet
  Future<void> setArray({String? field, List<dynamic> items = const []}) async {
    _logger.fine("setArray() field: " + field! + ", items: " + items.toString());
    try{
      Map<String, dynamic> jsonData = _set(field, value: []);
      jsonData['data']['type'] = Config.typeMap['ARRAY'].toString();
      _logger.fine("setArray() Message: " + jsonData.toString());

      List<Map<String, dynamic>> fields = _populate_array_fields(items: items);
      jsonData['data']['value'] = fields;

      await update(jsonData);

    }catch(e, stackTrace){
      _logger.severe("setArray() Exception: ", e, stackTrace);
    }
  }

  // TODO: field here needs to be prepared by user i.e. in case of hierarchy.
  // EG: user needs to send SubB1.B2....BN
  // Does not create Array field if it does not exists. Adds the element if the array field exists.
  Future<void> setArrayElement({String? field, dynamic value}) async{
    _logger.fine("setArrayElement() field: " + field! + ", value: " + value.toString());
    try{
      Map<String, dynamic>? jsonData;
      bool send = false;
      if (value.runtimeType == String){
        jsonData = _set_array_element(field, value, Config.typeMap['STRING'].toString());
        send = true;
      }else if(value.runtimeType == bool){
        jsonData = _set_array_element(field, value.toString(), Config.typeMap['BOOLEAN'].toString());
        send = true;
      }else if(value.runtimeType == int || value.runtimeType == double){
        jsonData = _set_array_element(field, value.toString(), Config.typeMap['NUMBER'].toString());
        send = true;
      }else{
        _logger.warning("Invalid Datataype in Add Array Element: Supported Types: STRING, INTEGER, DOUBLE, BOOLEAN");
      }
      if (send){
        _logger.fine("setArrayElement() Message: " + jsonData.toString());
        await update(jsonData!);
      }
    }catch(e, stackTrace){
      _logger.severe("setArrayElement() Exception: ", e, stackTrace);
    }
  }

  Future<void> updateArrayElement({String? field, dynamic value, dynamic newValue}) async{
    _logger.fine("updateArrayElement() field: " + field! + ", value: " + value.toString() + ", newValue: " + newValue.toString());
    try{
      // TODO: does not yet support updating the 'type'
      Map<String, dynamic> jsonData = _update_array_element(field, value, newValue);
      _logger.fine("updateArrayElement() Message: " + jsonData.toString());

      await update(jsonData);
    }catch(e, stackTrace){
      _logger.severe("updateArrayElement() Exception: ", e, stackTrace);
    }
  }

  Future<void> removeArrayElement({String? field, dynamic value}) async{
    _logger.fine("removeArrayElement() field: " + field! + ", value: " + value.toString());
    try{
      Map<String, dynamic> jsonData = _remove_array_element(field, value);
      _logger.fine("removeArrayElement() Message: " + jsonData.toString());
      await update(jsonData);
    }catch(e, stackTrace){
      _logger.severe("updateArrayElement() Exception: ", e, stackTrace);
    }
  }

}
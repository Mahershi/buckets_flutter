// TODO: delete, client api will only have client functionalities

import 'dart:convert';

import 'package:buckets/buckets.dart';
import 'package:buckets/src/config.dart';
import 'package:buckets/src/exceptions.dart';
import 'package:buckets/src/snapshot_bloc.dart';
import 'package:logging/logging.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

final Logger _logger = Logger("UserBucket");

class UserBucket{
  final String _id;
  final User _user;
  final Bucket _bucket;
  final Access _access;
  final String _joinedAt;

  String get id => _id;
  User get user => _user;
  Bucket get bucket => _bucket;
  Access get access => _access;
  String get joinedAt => _joinedAt;

  UserBucket(this._id, this._user, this._bucket, this._access, this._joinedAt);

  WebSocketChannel? _wsChannel;
  SnapshotBloc? _snapshotBloc;

  BucketSnapshot? _prevSnapshot;


  Map<String, dynamic> _set(String field, String value){
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

  WebSocketChannel _updateChannel(){
    _logger.info("Opening WS: " + Config.wsHost + Config.webSocketURL + _bucket.id);
    Uri uri = Uri.parse('${Config.wsHost}${Config.webSocketURL}${_bucket.id}/?Authorization=' + BucketAuth.headers()["Authorization"]!);
    return WebSocketChannel.connect(
      uri,
    );
  }

  // To set a string field.
  // Note, all the set* methods will receive the initial Update snapshot on the websocket connection
  // It can be ignored for now.
  Future<void> setString({String? field, String? value}) async {
    _logger.fine("setString() field: " + field! + ", value: " + value!);
    try{
      WebSocketChannel localWSChannel = _updateChannel();
      Map<String, dynamic> jsonData = _set(field!, value!);
      jsonData['data']['type'] = Config.typeMap['STRING'].toString();

      _logger.fine("setString() Message: " + jsonData.toString());

      localWSChannel.sink.add(jsonEncode(jsonData));
      await localWSChannel.sink.close();
    }catch(e){
      _logger.severe("setString() Exception: " + e.toString());
    }
  }

  Future<void> setInt({String? field, int? value}) async {
    _logger.fine("setInt() field: " + field! + ", value: " + value!.toString());
    try{
      WebSocketChannel localWSChannel = _updateChannel();

      Map<String, dynamic> jsonData = _set(field!, value.toString());
      jsonData['data']['type'] = Config.typeMap['NUMBER'].toString();

      _logger.fine("setInt() Message: " + jsonData.toString());

      localWSChannel.sink.add(jsonEncode(jsonData));
      await localWSChannel.sink.close();
    }catch(e){
      _logger.severe("setInt() Exception: " + e.toString());
    }
  }

  Future<void> setDouble({String? field, double? value}) async {
    _logger.fine("setDouble() field: " + field! + ", value: " + value!.toString());
    try{
      WebSocketChannel localWSChannel = _updateChannel();

      Map<String, dynamic> jsonData = _set(field, value.toString());
      jsonData['data']['type'] = Config.typeMap['NUMBER'].toString();
      _logger.fine("setDouble() Message: " + jsonData.toString());

      localWSChannel.sink.add(jsonEncode(jsonData));
      await localWSChannel.sink.close();
    }catch(e){
      _logger.severe("setDouble() Exception: " + e.toString());
    }
  }

  Future<void> setBool({String? field, bool? value}) async {
    _logger.fine("setBool() field: " + field! + ", value: " + value!.toString());
    try{
      WebSocketChannel localWSChannel = _updateChannel();

      Map<String, dynamic> jsonData = _set(field!, value.toString());
      jsonData['data']['type'] = Config.typeMap['BOOLEAN'].toString();
      _logger.fine("setBool() Message: " + jsonData.toString());
      localWSChannel.sink.add(jsonEncode(jsonData));
      await localWSChannel.sink.close();
    }catch(e){
      _logger.severe("setBool() Exception: " + e.toString());
    }
  }

  /*
  * To create a Map datatype. Technically creates a Sub Bucket on the backend side. Therefore known as Bucket.
  * */
  Future<void> createEmptyMap({String? field}) async {
    _logger.fine("createEmptyMap() field: " + field!);
    try{
      WebSocketChannel localWSChannel = _updateChannel();

      Map<String, dynamic> jsonData = _set(field!, '');
      jsonData['data']['type'] = Config.typeMap['BUCKET'].toString();
      _logger.fine("createEmptyMap() Message: " + jsonData.toString());

      localWSChannel.sink.add(jsonEncode(jsonData));
      await localWSChannel.sink.close();
    }catch(e){
      print(e);
    }
  }


  // Creates Array if not existing and adds the element is any passed.
  Future<void> setArray({String? field, List<dynamic> items = const []}) async {
    _logger.fine("setArray() field: " + field! + ", items: " + items.toString());
    try{

      // Created the array first, if it exists, existing data is NOT lost.
      WebSocketChannel localWSChannel = _updateChannel();
      Map<String, dynamic> jsonData = _set(field!, '');
      jsonData['data']['type'] = Config.typeMap['ARRAY'].toString();
      _logger.fine("setArray() Message: " + jsonData.toString());

      localWSChannel.sink.add(jsonEncode(jsonData));

      // Close the channel as the element addition will open its own channel.
      // if this is not awaited, the first element addition might try to use this and fail due to close in process.
      await localWSChannel.sink.close();

      // Future.forEach so that each iteration waits for the prev one to finish. to respect the indexing.
      // TODO: need to optimized to use existing WS Channel.
      Future.forEach(items, (element) async {
        await setArrayElement(field: field, value: element);
      });
    }catch(e){
      _logger.severe("setArray() Exception: " + e.toString());
    }
  }

  // TODO: field here needs to be prepared by user i.e. in case of hierarchy.
  // EG: user needs to send SubB1.B2....BN
  // Does not create Array field if it does not exists. Adds the element if the array field exists.
  Future<void> setArrayElement({String? field, dynamic value}) async{
    _logger.fine("setArrayElement() field: " + field! + ", value: " + value.toString());
    try{
      WebSocketChannel localWSChannel = _updateChannel();

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
        print("Invalid Datataype in Add Array Element: Supported Types: STRING, INTEGER, DOUBLE, BOOLEAN");
      }
      if (send){
        _logger.fine("setArrayElement() Message: " + jsonData.toString());
        localWSChannel.sink.add(jsonEncode(jsonData));
      }

      await localWSChannel.sink.close();
    }catch(e){
      _logger.severe("setArrayElement() Exception: " + e.toString());
    }
  }

  Future<void> updateArrayElement({String? field, dynamic value, dynamic newValue}) async{
    _logger.fine("updateArrayElement() field: " + field! + ", value: " + value.toString() + ", newValue: " + newValue.toString());
    try{
      WebSocketChannel localWSChannel = _updateChannel();

      Map<String, dynamic> jsonData = _update_array_element(field, value, newValue);
      _logger.fine("updateArrayElement() Message: " + jsonData.toString());
      localWSChannel.sink.add(jsonEncode(jsonData));

      // TODO: does not yet support updating value type.

      await localWSChannel.sink.close();
    }catch(e){
      _logger.severe("updateArrayElement() Exception: " + e.toString());
    }
  }

  Future<void> removeArrayElement({String? field, dynamic value}) async{
    _logger.fine("removeArrayElement() field: " + field! + ", value: " + value.toString());
    try{
      WebSocketChannel localWSChannel = _updateChannel();
      Map<String, dynamic> jsonData = _remove_array_element(field, value);
      _logger.fine("removeArrayElement() Message: " + jsonData.toString());
      localWSChannel.sink.add(jsonEncode(jsonData));
      await localWSChannel.sink.close();
    }catch(e){
      _logger.severe("updateArrayElement() Exception: " + e.toString());
    }
  }




  // Recursively sets a Map field considering presence of sub maps. Adv Testing pending, basics tested.
  // TODO: field here needs to be prepared by user i.e. in case of hierarchy.
  // EG: user needs to send SubB1.B2....BN
  Future<void> setMap({String? field, Map<dynamic, dynamic> data = const {}}) async {
    _logger.fine("setMap() field: " + field!, ", data:" + data.toString());
    try{
      WebSocketChannel localWSChannel = _updateChannel();

      // Create the empty map field
      Map<String, dynamic> jsonData = _set(field, '');
      jsonData['data']['type'] = Config.typeMap['BUCKET'].toString();
      _logger.fine("setMap() Message: " + jsonData.toString());
      localWSChannel.sink.add(jsonEncode(jsonData));

      // Set Map key value pairs.
      // TODO: Implement adding of Array inside of Map.
      data.forEach((key, value) async {
        if (value.runtimeType == String){
          await setString(field: field+"."+key, value: value);
        }else if(value.runtimeType == bool){
          await setBool(field: field+"."+key, value: value);
        }else if(value.runtimeType == int){
          await setInt(field: field+"."+key, value: value);
        }else if(value.runtimeType == double){
          await setDouble(field: field+"."+key, value: value);
        }else if(value is Map){
          // Aug 25: Seems to be working fine except optimization issue.
          // Recursive call for nested Maps
          // Need to attach bucket name for key hierarchy
          // SubBucket.SubBucket => hierarchy
          // TODO: this recusive call will create new WS conections. Improve to use the existing one.
          await setMap(field: field+'.'+key, data:value);
        }else{
          // Unsupported Data Type.
          // TODO: Handle Exception.
          _logger.warning("setMap() Unsupported Data Type");
        }
      });

      // Close after updating Map values.
      await localWSChannel.sink.close();
    }catch(e){
      _logger.severe("setMap() Exception: " + e.toString());
    }
  }

  Future<void> removeField({String? field}) async {
    _logger.fine("removeField() Field: " + field!);
    try{
      WebSocketChannel localWSChannel = _updateChannel();

      Map<String, dynamic> jsonData = {
        "type": "remove_field",
        "data": {
          "key": field
        }
      };
      _logger.fine("removeField() Message: " + jsonData.toString());
      localWSChannel.sink.add(jsonEncode(jsonData));
      await localWSChannel.sink.close();
    }catch(e){
      _logger.severe("removeField() Exception: " + e.toString());
    }
  }

  Future<void> _sendPrevSnapshot() async{
    await Future.delayed(Duration(seconds: 1));
    _snapshotBloc!.sink.add(
        _prevSnapshot!
    );
  }

  // TODO: Implement Reconnection in onDone in the _wsChannel.stream.listen
  Stream<BucketSnapshot> snapshots(){
    _logger.fine("snapshots() Requested");
    if (_wsChannel != null){
      _sendPrevSnapshot();
      _logger.fine("Sending PREV Snapshot()");
      return _snapshotBloc!.stream;
    }
    try{
      _logger.fine("URL: " + '${Config.wsHost}${Config.webSocketURL}${_bucket.id}/?Authorization=' + BucketAuth.headers()["Authorization"]!);
      Uri uri = Uri.parse('${Config.wsHost}${Config.webSocketURL}${_bucket.id}/?Authorization=' + BucketAuth.headers()["Authorization"]!);
      _wsChannel = WebSocketChannel.connect(
        uri,
      );

      // Create the local stream -> SnapshotBloc -> for this bucket.
      _logger.fine("Local SnapshotBloc Created");
      _snapshotBloc = SnapshotBloc();
      
      try {
        _wsChannel!.stream.listen((event) {
          Map<String, dynamic> jsonEvent = jsonDecode(event);

          // TODO: if its error, handle separately
          if (jsonEvent['type'] == 'update'){
            _prevSnapshot = BucketSnapshot.fromJson(
                jsonEvent['data']['id'].toString(),
                jsonEvent['data']['name'],
                jsonEvent['data']['value'],
                jsonEvent['type']
            );
            _snapshotBloc!.sink.add(
                _prevSnapshot!
            );
          }

        });
        _logger.fine("Snapshot Listener Attached!");
      } catch (e, s) {
        _logger.severe("snapshots() Excepetion: " + e.toString());
      }
      _logger.fine("snapshot() Success");
      return _snapshotBloc!.stream;
    }catch(e){
      _logger.severe("snapshots() Exception: " + e.toString());
      throw UnknownException("Error getting snapshots: ${e.toString()}");
    }
  }

  // Closes the web socket for snapshots, can reopen by calling snapshots() again.
  // does not affect set methods as they use different web socket connection.
  Future<void> disconnect() async {
    try{
      await _wsChannel!.sink.close();
      _wsChannel = null;
      await _snapshotBloc!.close();
      _logger.info("Closed Snapshot Stream!");
    }catch(e){
      _logger.severe("disconnect() Exception: " + e.toString());
    }

  }



}
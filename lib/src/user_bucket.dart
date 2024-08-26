import 'dart:convert';

import 'package:buckets/buckets.dart';
import 'package:buckets/src/access.dart';
import 'package:buckets/src/bucket.dart';
import 'package:buckets/src/bucket_snapshot.dart';
import 'package:buckets/src/config.dart';
import 'package:buckets/src/exceptions.dart';
import 'package:buckets/src/snashot_bloc.dart';
import 'package:buckets/src/user.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

// TODO: The problem here is having a single SnapshotBloc controlleer
// when multiple buckets are being read, their event goes through single SnapshotBlock hence all the listeners will get events
// from all the buckets irrespective of what they were meant to listen originally.

// TODO: Will need to create multiple SnapshotBloc object for individual UserBucket.

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



  WebSocketChannel _updateChannel(){
    print("Opening WS: " + Config.wsHost + Config.webSocketURL + _bucket.id);
    Uri uri = Uri.parse('${Config.wsHost}${Config.webSocketURL}${_bucket.id}/?Authorization=' + BucketAuth.headers()["Authorization"]!);
    return WebSocketChannel.connect(
      uri,
    );
  }

  // To set a string field.
  // Note, all the set* methods will receive the initial Update snapshot on the websocket connection
  // It can be ignored for now.
  Future<void> setString({String? field, String? value}) async {
    try{
      WebSocketChannel localWSChannel = _updateChannel();
      Map<String, dynamic> jsonData = _set(field!, value!);
      jsonData['data']['type'] = Config.typeMap['STRING'].toString();
      print(jsonData);
      localWSChannel.sink.add(jsonEncode(jsonData));
      await localWSChannel.sink.close();
    }catch(e){
      print(e);
    }
  }

  Future<void> setInt({String? field, int? value}) async {
    try{
      WebSocketChannel localWSChannel = _updateChannel();

      Map<String, dynamic> jsonData = _set(field!, value.toString());
      jsonData['data']['type'] = Config.typeMap['NUMBER'].toString();

      localWSChannel.sink.add(jsonEncode(jsonData));
      await localWSChannel.sink.close();
    }catch(e){
      print(e);
    }
  }

  Future<void> setDouble({String? field, double? value}) async {
    try{
      WebSocketChannel localWSChannel = _updateChannel();

      Map<String, dynamic> jsonData = _set(field!, value.toString());
      jsonData['data']['type'] = Config.typeMap['NUMBER'].toString();

      localWSChannel.sink.add(jsonEncode(jsonData));
      await localWSChannel.sink.close();
    }catch(e){
      print(e);
    }
  }

  Future<void> setBool({String? field, bool? value}) async {
    try{
      WebSocketChannel localWSChannel = _updateChannel();

      Map<String, dynamic> jsonData = _set(field!, value.toString());
      jsonData['data']['type'] = Config.typeMap['BOOLEAN'].toString();

      localWSChannel.sink.add(jsonEncode(jsonData));
      await localWSChannel.sink.close();
    }catch(e){
      print(e);
    }
  }

  /*
  * TODO: Will probably be use less because map will be created WITH some data and not empty.
  * To create a Map datatype. Technically creates a Sub Bucket on the backend side. Therefore known as Bucket.
  * */
  Future<void> createEmptyMap({String? field}) async {
    try{
      WebSocketChannel localWSChannel = _updateChannel();

      Map<String, dynamic> jsonData = _set(field!, '');
      jsonData['data']['type'] = Config.typeMap['BUCKET'].toString();

      localWSChannel.sink.add(jsonEncode(jsonData));
      await localWSChannel.sink.close();
    }catch(e){
      print(e);
    }
  }


  // Creates Array if not existing and adds the element is any passed.
  Future<void> setArray({String? field, List<dynamic> items = const []}) async {
    print(items);
    try{

      // Created the array first, if it exists, existing data is NOT lost.
      WebSocketChannel localWSChannel = _updateChannel();
      Map<String, dynamic> jsonData = _set(field!, '');
      jsonData['data']['type'] = Config.typeMap['ARRAY'].toString();
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
      print(e);
    }
  }

  // TODO: field here needs to be prepared by user i.e. in case of hierarchy.
  // EG: user needs to send SubB1.B2....BN
  // Does not create Array field if it does not exists. Adds the element if the array field exists.
  // TODO: handle exception in case array field does not exist -> Implement on backend first.
  // Always inserts at the end of array -> KNOWN Limitation.
  Future<void> setArrayElement({String? field, dynamic? value}) async{
    print("Element: " + value.toString());
    try{
      WebSocketChannel localWSChannel = _updateChannel();

      Map<String, dynamic> jsonData;

      if (value.runtimeType == String){
        jsonData = _set_array_element(field!, value, Config.typeMap['STRING'].toString());
        localWSChannel.sink.add(jsonEncode(jsonData));
      }else if(value.runtimeType == bool){
        jsonData = _set_array_element(field!, value.toString(), Config.typeMap['BOOLEAN'].toString());
        localWSChannel.sink.add(jsonEncode(jsonData));
      }else if(value.runtimeType == int || value.runtimeType == double){
        jsonData = _set_array_element(field!, value.toString(), Config.typeMap['NUMBER'].toString());
          localWSChannel.sink.add(jsonEncode(jsonData));
      }else{
        print("Invalid Datataype in Add Array Element: Supported Types: STRING, INTEGER, DOUBLE, BOOLEAN");
      }

      await localWSChannel.sink.close();
    }catch(e){
      print(e);
    }
  }


  // Recursively sets a Map field considering presence of sub maps. Adv Testing pending, basics tested.
  // TODO: field here needs to be prepared by user i.e. in case of hierarchy.
  // EG: user needs to send SubB1.B2....BN
  Future<void> setMap({String? field, Map<dynamic, dynamic> data = const {}}) async {
    try{
      WebSocketChannel localWSChannel = _updateChannel();

      // Create the empty map field
      Map<String, dynamic> jsonData = _set(field!, '');
      jsonData['data']['type'] = Config.typeMap['BUCKET'].toString();
      print(jsonData);
      localWSChannel.sink.add(jsonEncode(jsonData));

      // Set Map key value pairs.
      data.forEach((key, value) async {
        print(value.runtimeType);
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
          print("Adding Sub Map: " + value.toString());
          // Recursive call for nested Maps
          // Need to attach bucket name for key hierarchy
          // SubBucket.SubBucket => hierarchy
          // TODO: this recusive call will create new WS conections. Improve to use the existing one.
          await setMap(field: field+'.'+key, data:value);
        }else{
          // Unsupported Data Type.
          // TODO: Handle Exception.
          print("Unsupported Type");
        }
      });


      // Close after updating Map values.
      await localWSChannel.sink.close();
    }catch(e){
      print(e);
    }
    print("Finished");
  }

  Future<void> removeField({String? field}) async {
    try{
      WebSocketChannel localWSChannel = _updateChannel();

      Map<String, dynamic> jsonData = {
        "type": "remove_field",
        "data": {
          "key": field
        }
      };

      localWSChannel.sink.add(jsonEncode(jsonData));
      await localWSChannel.sink.close();
    }catch(e){
      print(e);
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
    if (_wsChannel != null){
      _sendPrevSnapshot();
      return _snapshotBloc!.stream;
    }
    try{
      Uri uri = Uri.parse('${Config.wsHost}${Config.webSocketURL}${_bucket.id}/?Authorization=' + BucketAuth.headers()["Authorization"]!);
      _wsChannel = WebSocketChannel.connect(
        uri,
      );


      // TODO: creating khudka SnapshotBloc object then how is it sharing with other bucket as per another TODO task? Test!
      // TODO: this has been basic tested and doesnt seem to overlap with other UserBuckets. Intense testing is pending.
      // Create the local stream -> SnapshotBloc -> for this bucket.
      _snapshotBloc = SnapshotBloc();
      
      _wsChannel!.stream.listen((event) {
        Map<String, dynamic> jsonEvent = jsonDecode(event);
        _prevSnapshot = BucketSnapshot.fromJson(
            jsonEvent['data']['id'].toString(),
            jsonEvent['data']['name'],
            jsonEvent['data']['content'],
            jsonEvent['type']
        );
        _snapshotBloc!.sink.add(
          _prevSnapshot!
        );
      });

      return _snapshotBloc!.stream;
    }catch(e){
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
    }catch(e){
      print(e);
    }

  }



}
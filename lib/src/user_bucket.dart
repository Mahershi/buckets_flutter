import 'dart:convert';

import 'package:buckets/buckets.dart';
import 'package:buckets/src/access.dart';
import 'package:buckets/src/bucket.dart';
import 'package:buckets/src/bucket_snapshot.dart';
import 'package:buckets/src/config.dart';
import 'package:buckets/src/exceptions.dart';
import 'package:buckets/src/snashot_bloc.dart';
import 'package:buckets/src/user.dart';
import 'package:web_socket_channel/io.dart';

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

  IOWebSocketChannel? _wsChannel;
  SnapshotBloc? _snapshotBloc;


  Map<String, dynamic> _set(String field, String value){
    return <String, dynamic>{
      "type": "add_field",
      "data": {
        "key": field,
        "value": value
      }
    };
  }

  IOWebSocketChannel _updateChannel(){
    return IOWebSocketChannel.connect(
        '${Config.wsHost}${Config.webSocketURL}${_bucket.id}/',
        headers: BucketAuth.headers()
    );
  }

  // To set a string field.
  // Note, all the set* methods will receive the initial Update snapshot on the websocket connection
  // It can be ignored for now.
  Future<void> setString({String? field, String? value}) async {
    try{
      IOWebSocketChannel localWSChannel = _updateChannel();

      Map<String, dynamic> jsonData = _set(field!, value!);
      jsonData['data']['type'] = Config.typeMap['STRING'].toString();

      localWSChannel.sink.add(jsonEncode(jsonData));
      await localWSChannel.sink.close();
    }catch(e){
      print(e);
    }
  }

  Future<void> setInt({String? field, int? value}) async {
    try{
      IOWebSocketChannel localWSChannel = _updateChannel();

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
      IOWebSocketChannel localWSChannel = _updateChannel();

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
      IOWebSocketChannel localWSChannel = _updateChannel();

      Map<String, dynamic> jsonData = _set(field!, value.toString());
      jsonData['data']['type'] = Config.typeMap['BOOLEAN'].toString();

      localWSChannel.sink.add(jsonEncode(jsonData));
      await localWSChannel.sink.close();
    }catch(e){
      print(e);
    }
  }

  Future<void> removeField({String? field}) async {
    try{
      IOWebSocketChannel localWSChannel = _updateChannel();

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

  Stream<BucketSnapshot> snapshots(){
    print(_wsChannel != null);
    if (_wsChannel != null){
      print("Returnined existing");
      return _snapshotBloc!.stream;
    }
    try{
      print("Creating new");
      // final wsURL = Uri.parse('${Config.host}${Config.webSocketURL}${_bucket.id}/');
      _wsChannel = IOWebSocketChannel.connect(
          '${Config.wsHost}${Config.webSocketURL}${_bucket.id}/',
        headers: BucketAuth.headers()
      );

      // Create the local stream -> SnapshotBloc -> for this bucket.
      _snapshotBloc = SnapshotBloc();
      
      _wsChannel!.stream.listen((event) {
        Map<String, dynamic> jsonEvent = jsonDecode(event);
        _snapshotBloc!.sink.add(
          BucketSnapshot.fromJson(
            jsonEvent['data']['id'].toString(),
            jsonEvent['data']['name'],
            jsonEvent['data']['content'],
            jsonEvent['type']
          )
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
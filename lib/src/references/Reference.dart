// parent reference class
// will have methods for
// 1. snapshots
// 2. closing snapshots
// 3. sending msgs

import 'dart:async';
import 'dart:convert';
import 'package:buckets/src/WSHandler.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../snapshots/Snapshot.dart';

/*
Handles WS Connection, Authentication, Buffering prev snapshot to send to new consumers
TODO: implement disconnection of WS channel for live snapshots
 */
abstract class Reference<T>{
  WSHandler? _wsHandler;
  // stream ID:2
  StreamController<Snapshot>? controller;
  Snapshot? _prevSnapshot;

  Reference(String wsUrl){
    _wsHandler = WSHandler(wsUrl);
  }

  Future<void> _sendPrevSnapshot() async{
    await Future.delayed(Duration(seconds: 1));
    controller!.sink.add(
        _prevSnapshot!
    );
  }

  // close snapshot listener.
  void close() {
    try{
      _prevSnapshot = null;
      _wsHandler!.close();
      controller!.sink.close();
    }catch(e){
      print("Error Closing Snapshot listener: " + e.toString());
    }
  }


  Stream<Snapshot> snapshots() {
    // if controller already initialized, ws already open.
    // if its closed manually, it doesnt become null
    if (controller != null && !controller!.isClosed){
      print("Returning Prev Snapshot");
      _sendPrevSnapshot();
      return controller!.stream;
    }
    print("Not prev snapshot");
    controller = StreamController<Snapshot>.broadcast();

    _wsHandler!.openAuthenticatedChannel().then((success) {
      if (success){
        parseMessage(_wsHandler!.broadcast!).listen(
              (snapshot) {
            // Pass the snapshots from parseMessage to the controller stream
            _prevSnapshot = snapshot;
            controller!.add(snapshot);
          },
          onError: (error) {
            // Handle errors in parseMessage stream
            print(error);
            controller!.addError(error);
            controller!.close();
          },
          onDone: () {
            // Close the controller stream once done
            controller!.close();
          },
        );
      }
      else{
        controller!.addError("Authentication Failure");
        controller!.close();
      }

    }).catchError((error) {
      // Handle errors in WebSocket connection or authentication
      controller!.addError(error);
      controller!.close();
    });
    return controller!.stream;
  }

  // create the pipeline for respective snapshot -> project, journal or record and return its stream
  Stream<Snapshot> parseMessage(Stream broadcast);

  // opens channel, pushed update msg, close channel.
  // return true/false on success.
  Future<bool> update(Map<String, dynamic> message) async {
    try{
      final channel = await _wsHandler!.updateChannel();
      // channel could be null or a WSChannel object
      if (channel != null){
        channel.sink.add(jsonEncode(message));
        await channel.sink.close();
        return true;
      }
    }catch(e){
      // TODO: exception handling. Also look into completer.onError
    }
    return false;
  }
}
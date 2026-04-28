// parent reference class
// will have methods for
// 1. snapshots
// 2. closing snapshots
// 3. sending msgs

import 'dart:async';
import 'dart:convert';
import 'package:buckets/src/WSHandler.dart';
import 'package:logging/logging.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../snapshots/Snapshot.dart';

final Logger _logger = Logger('Reference');

/*
Handles WS Connection, Authentication, Buffering prev snapshot to send to new consumers
TODO: implement disconnection of WS channel for live snapshots
 */
abstract class Reference<T>{
  // created wsUrl just cz wanted to store the String url
  // and use it in where() in JournalReference to chanin object creation.
  // couldn't pass handler bcz then they would share broadcast stream.
  final String wsUrl;
  WSHandler? _wsHandler;
  // stream ID:2
  StreamController<Snapshot>? controller;
  Snapshot? _prevSnapshot;

  Snapshot get prevSnapshot => _prevSnapshot!;
  StreamSubscription? _subscription;

  Reference(this.wsUrl){
    _wsHandler = WSHandler(this.wsUrl);
  }

  // Exposed WS Handler, we don't like it but the channel obj in it is private.
  // maybe we will change this later.
  WSHandler get wsHandler => _wsHandler!;

  Future<void> _sendPrevSnapshot() async{
    _logger.fine("Sending Previous Snapshot... delayed 1 second");
    await Future.delayed(Duration(seconds: 1));

    // TODO: wrap below in try catch. if user switches veryfast
    // this might get before being sent.
    // no issues other than that.
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
      _logger.fine("Reference Closed!");
    }catch(e, stackTrace){
      _logger.severe("Error closing Reference, Exception: ", e, stackTrace);
    }
  }

  // returns true once query is configured.
  // to denote completion of handshake and query building.
  // initiate snapshot receiver (parseMessage after this)
  // pass thj
  Future<bool> configureQuery(Stream stream) async {
    _logger.info("called configureQuery()");
    return true;
  }


  Stream<Snapshot> snapshots() {
    // if controller already initialized, ws already open.
    // if its closed manually, it doesnt become null
    if (controller != null && !controller!.isClosed){
      _sendPrevSnapshot();
      return controller!.stream;
    }
    controller = StreamController<Snapshot>.broadcast(
      onCancel: () async {
        print("Consumer broadcast cancelled!");
        await _subscription?.cancel();
        close();
      }
    );

    _wsHandler!.openAuthenticatedChannel().then((success) {
      if (success){
        configureQuery(_wsHandler!.broadcast).then((success){
          _logger.info("Query Configuration Status: ${success}");
          if (success){
            // track this subscription to cancel when consumer broadcast (Stream ID 2)closes.
            _subscription = parseMessage(_wsHandler!.broadcast).listen(
                  (snapshot) {
                // Pass the snapshots from parseMessage to the controller stream
                _prevSnapshot = snapshot;
                controller!.add(snapshot);
              },
              onError: (error) {
                // Handle errors in parseMessage stream
                controller!.addError(error);
                controller!.close();
              },
              onDone: () {
                // Close the controller stream once done
                controller!.close();
              },
            );
          }
        });

      }
      else{
        _logger.severe("WS Authentication Failure");
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

  // opens channel, pushes update msg, close channel.
  // return true/false on success.
  Future<bool> update(Map<String, dynamic> message) async {
    try{
      var channel = await _wsHandler!.updateChannel();
      // channel could be null or a WSChannel object
      if (channel != null){
        channel = channel as WebSocketChannel;
        // no need to configure query for update channel.
        channel.sink.add(jsonEncode(message));
        await channel.sink.close();

        return true;
      }
    }catch(e, stackTrace){
      // TODO: exception handling. Also look into completer.onError
    }
    return false;
  }
}
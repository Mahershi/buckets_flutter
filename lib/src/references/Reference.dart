// parent reference class
// will have methods for
// 1. snapshots
// 2. closing snapshots
// 3. sending msgs
// TODO: upgrade to generic Reference (cleaner API)
/**
* Below example:
*
* abstract class Reference<T extends Snapshot> {
    Stream<T> parseMessage(Stream broadcast);
    }

  class RecordReference extends Reference<RecordSnapshot>
* */

import 'dart:async';
import 'dart:convert';
import 'package:buckets/buckets.dart';
import 'package:buckets/src/WSHandler.dart';
import 'package:logging/logging.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/exceptions.dart';
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

  static const int _maxRetries = 5;
  int _retryCount = 0;

  Stream<Snapshot> snapshots() {
    if (controller != null && !controller!.isClosed) {
      _sendPrevSnapshot();
      return controller!.stream;
    }

    controller = StreamController<Snapshot>.broadcast(
      onCancel: () async {
        _logger.info("Consumer broadcast cancelled!");
        _retryCount = 0; // reset on intentional cancel
        await _subscription?.cancel();
        close();
      },
    );

    _connect(); // extracted method
    return controller!.stream;
  }

  Future<void> _connect() async {
    try {
      await _wsHandler!.openAuthenticatedChannel(); // now throws on failure

      _retryCount = 0;
      _logger.info("Starting parse message sub");
      _subscription = parseMessage(_wsHandler!.broadcast).listen(
            (snapshot) {
              _logger.info("parseMessage got snapshot");
          _prevSnapshot = snapshot;
          controller?.add(snapshot);
        },
        onError: (error) {
          _logger.severe("Stream error: $error");
          controller?.addError(error);

          // only retry for recoverable errors
          if (_isRecoverable(error)) {
            _retryConnection();
          } else {
            controller?.close();
          }
        },
        onDone: () {
          _logger.info("Stream done — attempting reconnect");
          _retryConnection();
        },
      );

      final success = await configureQuery(_wsHandler!.broadcast);
      _logger.info("Query Configuration Status: $success");

      if (!success) {
        throw const BucketsQueryException();
      }

    } catch (error) {
      _logger.severe("WS connection error: $error");
      controller?.addError(error);
      if (_isRecoverable(error)) {
        _retryConnection();
      } else {
        controller?.close();
      }
    }
  }

  Future<void> _retryConnection() async {
    if (controller == null || controller!.isClosed) return; // intentionally cancelled

    if (_retryCount >= _maxRetries) {
      _logger.severe("Max retries reached — giving up");
      controller!.addError(
        BucketsMaxRetriesExceededException(retries: _maxRetries),
      );
      controller!.close();
      return;
    }

    _retryCount++;
    final delay = Duration(seconds: _retryCount * 2); // 2s, 4s, 6s, 8s, 10s
    _logger.info("Retry $_retryCount/$_maxRetries in ${delay.inSeconds}s");

    await Future.delayed(delay);
    await _subscription?.cancel();
    _wsHandler!.close();
    _connect();
  }

  // any change in this baseParse need to be propagated in JournalReference.parseMessage
  Stream<T> baseParse<T>(
      Stream broadcast,
      T Function(Map<String, dynamic>) converter,
      ) {
    late StreamController<T> controller;
    StreamSubscription? subscription;
    controller = StreamController<T>(
      onCancel: () async {
        await subscription?.cancel();
      },
    );
    subscription = broadcast.listen(
          (event) {
        try {
          final jsonEvent = jsonDecode(event);
          final type = jsonEvent['type'];
          // known non-data/control events
          if (type == 'query' || type == 'authentication') {
            return;
          }

          final data = jsonEvent['data'];
          final parsed = converter(data);

          controller.add(parsed);
        } catch (e) {
          controller.addError(
            BucketsParseException(cause: e),
          );
        }
      },
      onError: (error) {
        // propagate but DO NOT close
        controller.addError(error);
      },
      onDone: () {
        controller.close();
      },
      cancelOnError: false,
    );
    return controller.stream;
  }

  // Stream<Snapshot> snapshots() {
  //   // if controller already initialized, ws already open.
  //   // if its closed manually, it doesnt become null
  //   if (controller != null && !controller!.isClosed){
  //     _sendPrevSnapshot();
  //     return controller!.stream;
  //   }
  //   controller = StreamController<Snapshot>.broadcast(
  //     onCancel: () async {
  //       print("Consumer broadcast cancelled!");
  //       await _subscription?.cancel();
  //       close();
  //     }
  //   );
  //
  //   _wsHandler!.openAuthenticatedChannel().then((success) {
  //     if (success){
  //       configureQuery(_wsHandler!.broadcast).then((success){
  //         _logger.info("Query Configuration Status: ${success}");
  //         if (success){
  //           // track this subscription to cancel when consumer broadcast (Stream ID 2)closes.
  //           _subscription = parseMessage(_wsHandler!.broadcast).listen(
  //                 (snapshot) {
  //               // Pass the snapshots from parseMessage to the controller stream
  //               _prevSnapshot = snapshot;
  //               controller!.add(snapshot);
  //             },
  //             onError: (error) {
  //               // Handle errors in parseMessage stream
  //               controller!.addError(error);
  //               controller!.close();
  //             },
  //             onDone: () {
  //               // Close the controller stream once done
  //               controller!.close();
  //             },
  //           );
  //         }
  //       });
  //
  //     }
  //     else{
  //       _logger.severe("WS Authentication Failure");
  //       controller!.addError("Authentication Failure");
  //       controller!.close();
  //     }
  //
  //   }).catchError((error) {
  //     // Handle errors in WebSocket connection or authentication
  //     controller!.addError(error);
  //     controller!.close();
  //   });
  //   return controller!.stream;
  // }

  // create the pipeline for respective snapshot -> project, journal or record and return its stream
  Stream<Snapshot> parseMessage(Stream broadcast);

  // opens channel, pushes update msg, close channel.
  // return true/false on success.
  Future<void> update(Map<String, dynamic> message) async {
    try{
      var channel = await _wsHandler!.updateChannel();
      // channel could be null or a WSChannel object
      if (channel == null){
        throw const BucketsConnectionException(
          message: "Failed to establish update channel",
        );
      }
      channel.sink.add(jsonEncode(message));
      await channel.sink.close();

    }catch(e, stackTrace){
      if (e is BucketsException) rethrow;
      throw BucketsUnknownException(cause: e);
    }
  }

  bool _isRecoverable(dynamic error) {
    return error is BucketsConnectionException ||
        error is BucketsConnectionTimeoutException ||
        error is BucketsConnectionDroppedException;
  }
}
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:buckets/src/models/exceptions.dart';
import 'package:logging/logging.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../buckets.dart';


final Logger _logger = Logger("WSHandler");

class WSHandler{
  WebSocketChannel? _channel;
  final String wsUrl;
  WSHandler(this.wsUrl);
  Stream? _broadcast;

  Stream get broadcast => _broadcast!;

  Future<bool> openAuthenticatedChannel() async {
    _channel = _openUnauthenticatedChannel(wsUrl);
    Completer<bool> completer = Completer<bool>();
    try{

      await _channel!.ready.timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw BucketsConnectionTimeoutException()
      );

      _broadcast = _channel!.stream.asBroadcastStream();
      _logger.fine("opening unauthenticated WS Connection Success");

      // listen for close separately
      _broadcast!.handleError((error) {
        _logger.severe("WS stream error: $error");
      }).listen(
        null,
        onDone: () {
          final closeCode = _channel?.closeCode;
          final closeReason = _channel?.closeReason;
          _logger.info("WS closed — code: $closeCode, reason: $closeReason");

          // normal closure codes: 1000, 1001 — no retry needed
          // everything else — retry
          _onWsClosed(closeCode);
        },
      );

      // stream ID:0
      broadcast.listen((event) {
        Map<String, dynamic> json = jsonDecode(event);
        if (json['type'] == 'error'){
          _logger.severe("Channel authentication failed");
          if (!completer.isCompleted) {
            completer.completeError(
              const BucketsAuthException(),
            );
          }
        }else if(json['type'] == 'authentication'){
          if (json['data']['authentication'] == 'Success'){
            _logger.fine("Channel authentication success");
            if (!completer.isCompleted) {
              completer.complete(true);
            }
          }else{
            _logger.severe("Channel authentication failed");
            if (!completer.isCompleted) {
              completer.completeError(
                const BucketsAuthException(),
              );
            }
          }
        }
      });
      await authenticate(_channel!);

      return completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          _logger.severe("WS Auth timeout — server did not respond in time");
          throw const BucketsAuthTimeoutException();
        },
      );
    }on SocketException catch(e, stackTrace){
      _logger.severe("Channel SocketException: ", e, stackTrace);
      if (!completer.isCompleted) {
        completer.completeError(
          BucketsConnectionException(cause: e),
        );
      }
    } catch(e, stackTrace){
      _logger.severe("Channel Unknown Exception: ", e, stackTrace);
      if (!completer.isCompleted) {
        completer.completeError(
          BucketsUnknownException(cause: e),
        );
      }
    }

    return completer.future;
  }

  void _onWsClosed(int? closeCode) {
    const normalCloseCodes = [1000, 1001];
    if (normalCloseCodes.contains(closeCode)) {
      _logger.info("WS closed cleanly — no retry");
    } else {
      _logger.warning("WS closed unexpectedly (code: $closeCode) — signalling retry");
      // this feeds back into _retryConnection via the onDone handler in snapshots()
    }
  }

  Future<dynamic> updateChannel() async {
    WebSocketChannel uws = _openUnauthenticatedChannel(wsUrl);
    Completer<WebSocketChannel?> completer = Completer<WebSocketChannel?>();
    try{
      await uws.ready;
      _logger.fine("_updateChannel WS Connection Success");

      uws.stream.listen((event) {
        try{
          final json = jsonDecode(event);
          if (json['type'] == 'error'){
            _logger.severe("_updateChannel authentication failed");
            completer.complete(null);
            if (!completer.isCompleted) completer.complete(null);
          }else if(json['type'] == 'authentication'){
            if (json['data']['authentication'] == 'Success'){
              _logger.severe("_updateChannel authentication success");
              if (!completer.isCompleted) completer.complete(uws);
            }else{
              _logger.severe("_updateChannel authentication failed");
              if (!completer.isCompleted) completer.complete(null);
            }
          }
        }catch(e){
          _logger.severe("_updateChannel parse error", e);
          if (!completer.isCompleted) completer.complete(null);
        }
      });
      await authenticate(uws);
      _logger.fine("_updateChannel WS Authentication Sent");
      return completer.future;
    }on SocketException catch(e, stackTrace){
      _logger.severe("_updateChannel SocketException", e, stackTrace);
      if (!completer.isCompleted) completer.complete(null);
    } catch(e, stackTrace){
      _logger.severe("_updateChannel Unknown Exception", e, stackTrace);
      if (!completer.isCompleted) completer.complete(null);
    }
    return completer.future;
  }

  static _openUnauthenticatedChannel(String wsUrl){
    _logger.fine("Opening Unauthenticated WS: " + wsUrl);
    Uri uri = Uri.parse('${wsUrl}/');
    return WebSocketChannel.connect(
      uri,
    );
  }

  /*
  Originally didnt need to pass channel object as it is stored in class.
  But for updateChannel we need differet chanel object
  So have to pass the object here
   */
  authenticate(WebSocketChannel channel) async {
    _logger.fine("Sending Auth message over channel: " + channel.toString());
    channel.sink.add(
      jsonEncode(BucketAuth.auth_message())
    );
  }

  sendMessage(Map<String, dynamic> message) async {
    _channel!.sink.add(jsonEncode(message));
  }

  void close(){
    try {
      _channel!.sink.close();
      _logger.fine("Channel Closed!");
    }catch(e, stackTrace){
      _logger.severe("Error Closing WSChannel: ", e, stackTrace);
    }
  }
}
import 'dart:async';
import 'dart:convert';
import 'dart:io';
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
      await _channel!.ready;
      _broadcast = _channel!.stream.asBroadcastStream();
      _logger.fine("opening unauthenticated WS Connection Success");
      // stream ID:0
      broadcast!.listen((event) {
        Map<String, dynamic> json = jsonDecode(event);
        if (json['type'] == 'error'){
          try{
            completer.complete(false);
            _logger.severe("Channel authentication failed");
          }catch(e){
            _logger.severe("Received error msg from server after authentication success!");
            _logger.severe(json['error']);
          }
        }else if(json['type'] == 'authentication'){
          if (json['data']['authentication'] == 'Success'){
            try{
              completer.complete(true);
              _logger.fine("Channel authentication success");
            }catch(e){
              _logger.warning("Received duplicate authentication success event!");
            }
          }else{
            try{
              completer.complete(false);
              _logger.severe("Channel authentication failed");
            }catch(e){
              _logger.warning("Received back to back failure events!");
            }
          }
        }
      });
      await authenticate(_channel!);

      // returns false or true based on auth result.
      return completer.future;
    }on SocketException catch(e, stackTrace){
      _logger.severe("Channel SocketException: ", e, stackTrace);
      completer.complete(false);
    } catch(e, stackTrace){
      _logger.severe("Channel Unknown Exception: ", e, stackTrace);
      completer.complete(false);
    }
    return completer.future;
  }

  Future<dynamic> updateChannel() async {
    WebSocketChannel uws = _openUnauthenticatedChannel(wsUrl);
    Completer<WebSocketChannel?> completer = Completer<WebSocketChannel?>();
    try{
      await uws.ready;
      _logger.fine("_updateChannel WS Connection Success");
      uws.stream.listen((event) {
        Map<String, dynamic> json = jsonDecode(event);
        if (json['type'] == 'error'){
          completer.complete(null);
          _logger.severe("_updateChannel authentication failed");
        }else if(json['type'] == 'authentication'){
          if (json['data']['authentication'] == 'Success'){
            completer.complete(uws);
            _logger.severe("_updateChannel authentication success");
          }else{
            completer.complete(null);
            _logger.severe("_updateChannel authentication failed");
          }
        }
      });
      await authenticate(uws);
      _logger.fine("_updateChannel WS Authentication Sent");
      return completer.future;
    }on SocketException catch(e, stackTrace){
      _logger.severe("_updateChannel SocketException: ", e, stackTrace);
      completer.complete(null);
    } catch(e, stackTrace){
      _logger.severe("_updateChannel Unknown Exception", e, stackTrace);
      completer.complete(null);
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

  close(){
    try {
      _channel!.sink.close();
      _logger.fine("Channel Closed!");
    }catch(e, stackTrace){
      _logger.severe("Error Closing WSChannel: ", e, stackTrace);
    }
  }
}
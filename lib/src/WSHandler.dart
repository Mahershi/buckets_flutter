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
  Stream? broadcast;

  Future<bool> openAuthenticatedChannel() async {
    _channel = _openUnauthenticatedChannel(wsUrl);
    Completer<bool> completer = Completer<bool>();
    try{
      await _channel!.ready;
      broadcast = _channel!.stream.asBroadcastStream();
      _logger.info("opening unauthenticated WS Connection Success");
      // stream ID:0
      broadcast!.listen((event) {

        Map<String, dynamic> json = jsonDecode(event);
        if (json['type'] == 'error'){
          completer.complete(false);
          _logger.severe("Channel authentication failed");
        }else if(json['type'] == 'authentication'){
          if (json['data']['authentication'] == 'Success'){
            completer.complete(true);
            _logger.severe("Channel authentication success");
          }else{
            print("failed auth");
            completer.complete(false);
            _logger.severe("Channel authentication failed");
          }
        }

      });

      await authenticate(_channel!);

      // returns false or true based on auth result.
      return completer.future;
    }on SocketException catch(e){
      _logger.severe("Channel SocketException: ", e.toString());
      completer.complete(false);
    } catch(e){
      _logger.severe("Channel Unknown Exception: ", e.toString());
      completer.complete(false);
    }
    return completer.future;
  }

  // TODO: changes/update
   Future<dynamic> updateChannel() async {
    WebSocketChannel uws = _openUnauthenticatedChannel(wsUrl);
    Completer<WebSocketChannel?> completer = Completer<WebSocketChannel?>();

    try{
      await uws.ready;
      _logger.info("_updateChannel WS Connection Success");
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
      _logger.info("_updateChannel WS Authentication Sent");
      return completer.future;
    }on SocketException catch(e){
      _logger.severe("_updateChannel SocketException: ", e.toString());
      completer.complete(null);
    } catch(e){
      _logger.severe("_updateChannel Unknown Exception: ", e.toString());
      completer.complete(null);
    }
    return completer.future;
  }

  static _openUnauthenticatedChannel(String wsUrl){
    _logger.info("Opening Unauthenticated WS: " + wsUrl);
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
    channel.sink.add(
      jsonEncode(BucketAuth.auth_message())
    );
  }

  close(){
    try {
      _channel!.sink.close();
    }catch(e){
      print("Error Closing WSChannel: " + e.toString());
    }

  }
}
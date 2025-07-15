import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import '../config.dart';

final Logger _logger = Logger("JWTTokenHandler");

class JWTTokenHandler{
  String _accessToken;
  final String _refreshToken;

  late bool _shouldRefresh;
  late int _refreshInterval;  // minutes

  // Only used to check whether success in refresh during test.
  bool refreshed = false;

  JWTTokenHandler(this._accessToken, this._refreshToken){
    _shouldRefresh = true;
    // Server is set to 15 minutes
    _refreshInterval = 14;

    refreshToken();
    _logger.fine("JWT Initialized");
  }

  void stop(){
    _shouldRefresh = false;
    _logger.fine("Stopped JWT Refresh!");
  }

  // Async method to refresh token in background
  // TODO: if stop is called, this loop doesnt stop until it finished its wait of _refreshInterval. there is no event handling.
  void refreshToken() async {
    _logger.fine("JWT Refresh Loop triggered");
    while(_shouldRefresh){
      await Future.delayed(Duration(minutes: _refreshInterval), (){});
      refreshed = false;
      try{
        _logger.fine("Refreshing access token...");
        _logger.fine("JWT Refresh URL: " + Config.host + Config.tokenRefreshURL);
        var response = await http.post(
            Uri.parse(Config.host + Config.tokenRefreshURL),
            body: {
              'refresh': _refreshToken
            }
        );
        _logger.fine("JWT Refresh Status Code: " + response.statusCode.toString());
        if (response.statusCode == 200){
          var json = jsonDecode(response.body);
          _accessToken = json['access'];
          refreshed = true;
          _logger.fine("JWT Refresh Success!");
        }else{
          _logger.severe("Refreshing JWT Failed: " + response.statusCode.toString());
          refreshed = false;
        }
      }catch(e, stackTrace){
        _logger.severe("JWT Refresh Exception: ", e, stackTrace);
        refreshed = false;
      }

    }
    _logger.fine("JWT Refresh Loop Exited!");
  }

  Map<String, String> authHeader(){
    return {
      "Authorization": "Bearer $_accessToken"
    };
  }

  Map<String, dynamic> authWSMessage(){
    return {
      "type": "authentication",
      "data": {
        "authentication": "Bearer $_accessToken"
      }
    };
  }
}
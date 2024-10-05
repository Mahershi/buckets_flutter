import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import 'config.dart';

final Logger _logger = Logger("JWTToken");

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
    _logger.info("JWT Init");
  }

  void stop(){
    _shouldRefresh = false;
    _logger.info("Stopped JWT Refresh!");
  }

  // Async method to refresh token in background
  void refreshToken() async {
    while(_shouldRefresh){
      // print("Waiting for refresh");
      await Future.delayed(Duration(minutes: _refreshInterval), (){});
      refreshed = false;
      try{
        _logger.info("Refreshing access token...");
        _logger.info("URL: " + Config.host + Config.tokenRefreshURL);
        var response = await http.post(
            Uri.parse(Config.host + Config.tokenRefreshURL),
            body: {
              'refresh': _refreshToken
            }
        );
        _logger.info("Status Code: " + response.statusCode.toString());
        if (response.statusCode == 200){
          var json = jsonDecode(response.body);
          _accessToken = json['access'];
          refreshed = true;
          _logger.info("JWT Refresh Success!");
        }else{
          _logger.severe("Refreshing JWT Failed: " + response.statusCode.toString());
          refreshed = false;
        }
      }catch(e){
        // print("Refresh Exception: ");
        // print(e);
        _logger.severe("JWT Refresh Exception: " + e.toString());
        refreshed = false;
      }

    }

  }

  Map<String, String> authHeader(){
    return {
      "Authorization": "Bearer $_accessToken"
    };
  }
}
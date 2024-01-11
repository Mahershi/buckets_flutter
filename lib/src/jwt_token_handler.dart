import 'dart:convert';

import 'package:http/http.dart' as http;

import 'config.dart';


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
  }

  void stop(){
    _shouldRefresh = false;
  }

  // Async method to refresh token in background
  void refreshToken() async {
    while(_shouldRefresh){
      refreshed = false;
      try{
        var response = await http.post(
            Uri.parse(Config.host + Config.tokenRefreshURL),
            body: {
              'refresh': _refreshToken
            }
        );
        if (response.statusCode == 200){
          var json = jsonDecode(response.body);
          _accessToken = json['access'];
          refreshed = true;
        }else{
          refreshed = false;
        }
      }catch(e){
        refreshed = false;
      }
      await Future.delayed(Duration(minutes: _refreshInterval), (){});
    }

  }

  Map<String, String> authHeader(){
    return {
      "Authorization": "Bearer $_accessToken"
    };
  }
}
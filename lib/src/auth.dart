import 'dart:convert';

import 'package:buckets/src/config.dart';
import 'package:buckets/src/jwt_token_handler.dart';
import 'package:buckets/src/user.dart';
import 'package:http/http.dart' as http;

class BucketAuth{
  static late User _curUser;
  static late JWTTokenHandler _jwtTokenHandler;
  static bool _loggedIn = false;

  // TODO: Fetching the current user is not yet integrated as we have every thing based on JWT.
  static User get curUser => _curUser;
  static bool get loggedIn => _loggedIn;

  // Private constructor to prevent object creation.
  BucketAuth._();

  static Future<bool> loginWithCredentials(String email, String password) async {
    _loggedIn = false;
    try{
      var response = await http.post(
        Uri.parse(Config.host + Config.tokenURL),
        body: {
          "email": email,
          "password": password
        }
      );
      if (response.statusCode == 200){
        var json = jsonDecode(response.body);
        _jwtTokenHandler = JWTTokenHandler(json['access'], json['refresh']);
        _loggedIn = true;
        return true;
      }
      return false;
    }catch(e){
      print(e);
      return false;
    }
  }

  static Map<String, String> headers(){
    if(_loggedIn){
      return _jwtTokenHandler.authHeader();
    }
    return <String, String>{};
  }

  static void logout(){
    // Notify JWT to no longer refresh token due to logout.
    _loggedIn = false;
    _jwtTokenHandler.stop();
  }
}
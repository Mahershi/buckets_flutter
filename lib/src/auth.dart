import 'dart:convert';

import 'package:buckets/src/config.dart';
import 'package:buckets/src/jwt_token_handler.dart';
import 'package:buckets/src/user.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

final Logger _logger = Logger('BucketAuth');

class BucketAuth{
  // unused.... _curUser var.
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
      _logger.info("Auth URL: " + Config.host + Config.tokenURL);
      var response = await http.post(
        Uri.parse(Config.host + Config.tokenURL),
        body: {
          "email": email,
          "password": password
        },
      );
      _logger.info("Auth Status Code: " + response.statusCode.toString());
      if (response.statusCode == 200){


        var json = jsonDecode(response.body);
        _jwtTokenHandler = JWTTokenHandler(json['access'], json['refresh']);
        _loggedIn = true;
        _logger.info("User Logged In");

        await setCurUser();

        return true;
      }
      _logger.warning("Auth failed");
      return false;
    }catch(e){
      _logger.severe("Auth Exception: " + e.toString());
      return false;
    }
  }

  static Future<void> setCurUser() async {
    try{
      _logger.info("Auth User URL: " + Config.host + Config.userURL);
      var response = await http.get(
        Uri.parse(Config.host + Config.userURL),
        headers: headers()
      );
      if (response.statusCode == 200){
        var json = jsonDecode(response.body);
        if (json['success']){
          _curUser = User(json['data']['id'].toString(), json['data']['name'], json['data']['email']);
          print("cur user initalized");
        }
        return ;
      }
      print(response.statusCode);
      print(response.body);
      _logger.warning("_curUser init Failed");
    }catch(e){
      _logger.severe("Auth Exception: " + e.toString());
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
    _logger.info("User Logging out!");
    _loggedIn = false;
    _jwtTokenHandler.stop();
    _curUser = User("-1", "", "");
  }
}
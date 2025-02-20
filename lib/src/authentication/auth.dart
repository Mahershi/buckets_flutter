import 'dart:convert';

import 'package:buckets/buckets.dart';
import 'package:buckets/src/models/Project.dart';
import 'package:buckets/src/config.dart';
import 'package:buckets/src/authentication/jwt_token_handler.dart';
import 'package:buckets/src/models/project_client.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

final Logger _logger = Logger('BucketAuth');

class BucketAuth{
  // unused.... _curUser var.
  static late User _curUser;
  static late ProjectClient _curClient;
  static late JWTTokenHandler _clientJwtTokenHandler;
  static late JWTTokenHandler _userJwtTokenHandler;
  static bool _loggedIn = false;

  // TODO: Fetching the current user is not yet integrated as we have every thing based on JWT.
  static ProjectClient get curClient => _curClient;
  static bool get loggedIn => _loggedIn;
  static User get curUser => _curUser;

  // Private constructor to prevent object creation.
  BucketAuth._();

  static Future<bool> clientLogin(String clientId, String clientKey) async {
    _loggedIn = false;
    try{
      _logger.info("Auth URL: " + Config.host + Config.clientTokenURL);
      var response = await http.post(
        Uri.parse(Config.host + Config.clientTokenURL),
        body: {
          "client_id": clientId,
          "client_key": clientKey
        },
      );
      _logger.info("Auth Status Code: " + response.statusCode.toString());
      if (response.statusCode == 200){

        var json = jsonDecode(response.body);
        _clientJwtTokenHandler = JWTTokenHandler(json['access'], json['refresh']);
        _loggedIn = true;
        _logger.info("Client Logged In");

        return await _getClient();
      }
      _logger.warning("Auth failed");
      return false;
    }catch(e){
      _logger.severe("clientLogin excep: " + e.toString());
      return false;
    }
  }

  // TODO: Block usage, no more user login
  static Future<bool> userLoginWithCredentials(String email, String password) async {
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
        _userJwtTokenHandler = JWTTokenHandler(json['access'], json['refresh']);
        _loggedIn = true;
        _logger.info("User Logged In");

        await _setCurUser();

        return true;
      }
      _logger.warning("Auth failed");
      return false;
    }catch(e){
      _logger.severe("userLoginWithCreds Excep: " + e.toString());
      return false;
    }
  }

  static Future<bool> _getClient() async {
    try{
      _logger.info("Auth getClient URL: " + Config.host + Config.getClient);
      var response = await http.get(
          Uri.parse(Config.host + Config.getClient),
          headers: headers()
      );
      if (response.statusCode == 200){
        var json = jsonDecode(response.body);
        if (json['success']){
          _curClient = ProjectClient(
              json['data']['id'].toString(),
            json['data']['name'],
            json['data']['client_id'],
            json['data']['client_key'] ?? '',
            json['data']['is_active'],
            json['data']['is_default'],
            Project(
                json['data']['project']['id'].toString(),
                json['data']['project']['name'],
                json['data']['project']['created_at']
            ),
            Access(
                json['data']['access']['id'].toString(),
                json['data']['access']['type']
            )
          );
          _logger.fine("CurClient Initialized");
        }
        return true;
      }
      print(response.statusCode);
      print(response.body);
      _logger.warning("_curUser init Failed");
    }catch(e){
      _logger.severe("getClient excep: " + e.toString());
    }
    return false;
  }

  static Future<void> _setCurUser() async {
    try{
      _logger.info("Auth User URL: " + Config.host + Config.userURL);
      var response = await http.get(
          Uri.parse(Config.host + Config.userURL),
          headers: user_auth_header()
      );
      if (response.statusCode == 200){
        var json = jsonDecode(response.body);
        if (json['success']){
          _curUser = User(json['data']['id'].toString(), json['data']['name'], json['data']['email']);
          _logger.info('Current User initialized');
        }
        return ;
      }
      print(response.statusCode);
      print(response.body);
      _logger.warning("_curUser init Failed");
    }catch(e){
      _logger.severe("SetCurUser Excep: " + e.toString());
    }
  }

  //client auth headers
  static Map<String, String> headers(){
    if(_loggedIn){
      return _clientJwtTokenHandler.authHeader();
    }
    return <String, String>{};
  }

  // user auth headers
  static Map<String, String> user_auth_header(){
    if(_loggedIn){
      return _userJwtTokenHandler.authHeader();
    }
    return <String, String>{};
  }

  // client auth message
  static Map<String, dynamic> auth_message(){
    if(_loggedIn){
      return _clientJwtTokenHandler.authWSMessage();
    }
    return <String, dynamic>{};
  }

  static void closeClient(){
    _logger.info("Client Closing!");
    _loggedIn = false;
    _clientJwtTokenHandler.stop();
    _curClient = ProjectClient.empty();
  }

  static void logout(){
    // Notify JWT to no longer refresh token due to logout.
    _logger.info("User Logging out!");
    _userJwtTokenHandler.stop();
    _curUser = User.empty();
  }
}
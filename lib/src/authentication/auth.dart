import 'dart:convert';

import 'package:buckets/buckets.dart';
import 'package:buckets/src/config.dart';
import 'package:buckets/src/authentication/jwt_token_handler.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

final Logger _logger = Logger('BucketAuth');

class BucketAuth{
  // unused.... _curUser var.
  static late User _curUser;
  static late ProjectClient _curClient;
  static late JWTTokenHandler _clientJwtTokenHandler;
  static late JWTTokenHandler _userJwtTokenHandler;
  static bool _clientLoggedIn = false;
  static bool _userLoggedIn = false;

  // TODO: Fetching the current user is not yet integrated as we have every thing based on JWT.
  static ProjectClient get curClient => _curClient;
  static bool get loggedIn => _clientLoggedIn;
  static bool get userLoggedIn => _userLoggedIn;
  static User get curUser => _curUser;

  // Private constructor to prevent object creation.
  BucketAuth._();

  static Future<bool> clientLogin(String clientId, String clientKey) async {
    _clientLoggedIn = false;
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
        _clientLoggedIn = true;
        _logger.info("Client Logged In");

        return await _getClient();
      }
      _logger.warning("Client Auth failed");
      return false;
    }catch(e){
      _logger.severe("clientLogin() Exception: " + e.toString());
      return false;
    }
  }

  // only used on the dashboard.
  static Future<bool> userLoginWithCredentials(String email, String password) async {
    _userLoggedIn = false;
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
        _userLoggedIn = true;
        _logger.info("User Logged In");
        await _setCurUser();

        return true;
      }
      _logger.warning("User Auth failed");
      return false;
    }catch(e){
      _logger.severe("userLoginWithCredentials() Exception: " + e.toString());
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
      _logger.info('Response Code ' + response.statusCode.toString());
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
                json['data']['project']['created_at'],
                json['data']['project']['is_active']
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
      _logger.warning("_curUser init Failed");
    }catch(e){
      _logger.severe("getClient Exception: " + e.toString());
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
      _logger.info('Response Code ' + response.statusCode.toString());
      if (response.statusCode == 200){
        var json = jsonDecode(response.body);
        if (json['success']){
          _curUser = User(json['data']['id'].toString(), json['data']['name'], json['data']['email']);
          _logger.info('Current User initialized');
        }
        return ;
      }
      _logger.warning("_curUser init Failed");
    }catch(e){
      _logger.severe("SetCurUser Exception: " + e.toString());
    }
  }

  //client auth headers
  static Map<String, String> headers(){
    if(_clientLoggedIn){
      return _clientJwtTokenHandler.authHeader();
    }
    return <String, String>{};
  }

  // user auth headers
  static Map<String, String> user_auth_header(){
    if(_userLoggedIn){
      return _userJwtTokenHandler.authHeader();
    }
    return <String, String>{};
  }

  // client auth message
  static Map<String, dynamic> auth_message(){
    if(_clientLoggedIn){
      return _clientJwtTokenHandler.authWSMessage();
    }
    return <String, dynamic>{};
  }

  static void closeClient(){
    _logger.info("Closing client...");
    _clientLoggedIn = false;
    _clientJwtTokenHandler.stop();
    _curClient = ProjectClient.empty();
    _logger.info("ProjectClient closed!");
  }

  static void logout(){
    // Notify JWT to no longer refresh token due to logout.
    _userJwtTokenHandler.stop();
    _curUser = User.empty();
    _logger.info("User logged out!");
  }
}
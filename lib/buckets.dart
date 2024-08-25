library buckets;

import 'dart:convert';

import 'src/access.dart';
import 'src/auth.dart';
import 'src/bucket.dart';
import 'src/config.dart';
import 'src/exceptions.dart';
import 'src/user.dart';
import 'src/user_bucket.dart';
import 'package:http/http.dart' as http;

export 'src/auth.dart' show BucketAuth;
export 'src/user_bucket.dart' show UserBucket;
export 'src/bucket_snapshot.dart' show BucketSnapshot;
export 'src/user.dart' show User;
export 'src/bucket.dart' show Bucket;
export 'src/access.dart' show Access;
export 'src/field_type.dart' show FieldType;



class Buckets{
  static final Map<String, UserBucket> _loadedUserBuckets = <String, UserBucket>{};

  static void switchToDevelopment(){
    Config.setEnvironment(Environment.DEVELOPMENT);
  }
  static void switchToStaging(){
    Config.setEnvironment(Environment.STAGING);
  }

  static Future<UserBucket> bucket(String bucketId) async {
    if (BucketAuth.loggedIn){
      if(_loadedUserBuckets.containsKey(bucketId)){
        print("Returning exisintg bucket");
        return _loadedUserBuckets[bucketId]!;
      }

      try{
        var response = await http.get(
          Uri.parse(
            "${Config.host}${Config.userBucketURL}?bucket_id=$bucketId" ,
          ),
          headers: BucketAuth.headers()
        );
        if(response.statusCode == 200){
          var jsonData = jsonDecode(response.body)['data'];

          UserBucket ub = UserBucket(
              jsonData['id'].toString(),
              User(jsonData['user']['id'].toString(), jsonData['user']['name'], jsonData['user']['email']),
              Bucket(jsonData['bucket']['id'].toString(), jsonData['bucket']['name'], jsonData['bucket']['created_at']),
              Access(jsonData['access']['id'].toString(), jsonData['access']['type']),
              jsonData['joined_at']
          );

          _loadedUserBuckets[bucketId] = ub;
          return ub;
        }
        else{
          var jsonData = jsonDecode(response.body);

          if (response.statusCode == 400){
            throw BucketNotFound("Error Fetching Bucket: ${response.statusCode}: ${jsonData['error']}");
          }
          else if(response.statusCode == 401){
            throw UnauthAccess("Error Fetching Bucket: ${response.statusCode}: ${jsonData['error']}");
          }else{
            throw UnknownException("Error Fetching Bucket: ${response.statusCode}: ${jsonData['error']}");
          }
        }
      } on UnknownException catch(e){
        throw UnknownException("Error Fetching Bucket: ${e.toString()}");
      }
    }else{
      throw UnauthAccess("User not logged in! Use BucketAuth to login user!");
    }
  }
}

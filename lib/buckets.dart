library buckets;

import 'package:buckets/src/models/Project.dart';
import 'package:buckets/src/models/project_client.dart';
import 'package:logging/logging.dart';


import 'src/authentication/auth.dart';
import 'src/config.dart';
import 'src/models/exceptions.dart';
import 'src/user_bucket.dart';
import 'src/logger.dart';
import 'package:http/http.dart' as http;

export 'src/authentication/auth.dart' show BucketAuth;
export 'src/user_bucket.dart' show UserBucket;
export 'src/bucket_snapshot.dart' show BucketSnapshot;
export 'src/models/user.dart' show User;
export 'src/models/bucket.dart' show Bucket;
export 'src/models/access.dart' show Access;
export 'src/models/field_type.dart' show FieldType;
export 'src/models/Project.dart' show Project;
export 'src/models/Journal.dart' show Journal;
export 'src/models/Record.dart' show Record;
export 'src/models/user_project.dart' show UserProject;
export 'src/models/project_client.dart' show ProjectClient;
export 'src/client.dart' show Client;
export 'src/references/ProjectReference.dart' show ProjectReference;
export 'src/references/RecordReference.dart' show RecordReference;
export 'src/references/JournalReference.dart' show JournalReference;
export 'src/snapshots/RecordSnapshot.dart' show RecordSnapshot;
export 'src/snapshots/ProjectSnapshot.dart' show ProjectSnapshot;
export 'src/snapshots/JournalSnapshot.dart' show JournalSnapshot;

final Logger _logger = Logger('Buckets');

class Buckets{
  static final Map<String, UserBucket> _loadedUserBuckets = <String, UserBucket>{};

  static void setLogLevel({Level level=Level.WARNING}){
    setupLogging(level);
  }

  static void switchToDevelopment(){
    Config.setEnvironment(Environment.DEVELOPMENT);
  }
  static void switchToStaging(){
    Config.setEnvironment(Environment.STAGING);
  }

  static ProjectClient client(){
    if (BucketAuth.loggedIn)
      return BucketAuth.curClient;
    throw UnauthAccess("Client not Authenticated! Use BucketAuth.clientLogin()");
  }

  static Project project() {
    if (BucketAuth.loggedIn){
      try{
        return BucketAuth.curClient.project;
      }catch(e){
        _logger.warning("Unknown Exception when fetching Project!");
        throw UnauthAccess("User not logged in! Use BucketAuth to login user!");
      }
    }else{
      _logger.warning("User not logged in! Use BucketAuth to login user!");
      throw UnknownException("Error Fetching Project");
    }
  }

  // // TODO: DELETE, wont need this as client api will not grep all UserBucket
  // // or any user related transactions.
  // static Future<UserBucket> bucket(String bucketId) async {
  //   if (BucketAuth.loggedIn){
  //     if(_loadedUserBuckets.containsKey(bucketId)){
  //       return _loadedUserBuckets[bucketId]!;
  //     }
  //
  //     try{
  //       _logger.info("Bucket URL: ${Config.host}${Config.userBucketURL}?bucket_id=$bucketId");
  //       var response = await http.get(
  //         Uri.parse(
  //           "${Config.host}${Config.userBucketURL}?bucket_id=$bucketId" ,
  //         ),
  //         headers: BucketAuth.headers()
  //       );
  //       _logger.info("Status Code: " + response.statusCode.toString());
  //       if(response.statusCode == 200){
  //         var jsonData = jsonDecode(response.body)['data'];
  //
  //         UserBucket ub = UserBucket(
  //             jsonData['id'].toString(),
  //             User(jsonData['user']['id'].toString(), jsonData['user']['name'], jsonData['user']['email']),
  //             Bucket(jsonData['bucket']['id'].toString(), jsonData['bucket']['name'], jsonData['bucket']['created_at'], jsonData['bucket']['is_active']),
  //             Access(jsonData['access']['id'].toString(), jsonData['access']['type']),
  //             jsonData['joined_at']
  //         );
  //         _logger.info("Created UserBucket Object");
  //         _loadedUserBuckets[bucketId] = ub;
  //         return ub;
  //       }
  //       else{
  //         var jsonData = jsonDecode(response.body);
  //         _logger.severe("Error Fetching Bucket: ${response.statusCode}: ${jsonData['error']}");
  //         if (response.statusCode == 400){
  //           throw BucketNotFound("Error Fetching Bucket: ${response.statusCode}: ${jsonData['error']}");
  //         }
  //         else if(response.statusCode == 401){
  //           throw UnauthAccess("Error Fetching Bucket: ${response.statusCode}: ${jsonData['error']}");
  //         }else{
  //           throw UnknownException("Error Fetching Bucket: ${response.statusCode}: ${jsonData['error']}");
  //         }
  //       }
  //     } on UnknownException catch(e){
  //       _logger.severe("Error Fetching Bucket: ${e.toString()}");
  //       throw UnknownException("Error Fetching Bucket: ${e.toString()}");
  //     }
  //   }else{
  //     _logger.warning("User not logged in! Use BucketAuth to login user!");
  //     throw UnauthAccess("User not logged in! Use BucketAuth to login user!");
  //   }
  // }
}

library buckets;

import 'package:buckets/src/models/Project.dart';
import 'package:buckets/src/models/project_client.dart';
import 'package:logging/logging.dart';


import 'src/authentication/auth.dart';
import 'src/config.dart';
import 'src/models/exceptions.dart';
import 'src/logger.dart';
import 'package:http/http.dart' as http;

export 'src/authentication/auth.dart' show BucketAuth;
export 'src/models/user.dart' show User;
export 'src/models/bucket.dart' show Bucket;
export 'src/models/access.dart' show Access;
export 'src/models/field_type.dart' show FieldType;
export 'src/models/Project.dart' show Project;
export 'src/models/Journal.dart' show Journal;
export 'src/models/Record.dart' show Record;
export 'src/models/user_project.dart' show UserProject;
export 'src/models/project_client.dart' show ProjectClient;
export 'src/references/ProjectReference.dart' show ProjectReference;
export 'src/references/RecordReference.dart' show RecordReference;
export 'src/references/MinJournalReference.dart' show MinJournalReference;
export 'src/references/JournalReference.dart' show JournalReference;
export 'src/snapshots/RecordSnapshot.dart' show RecordSnapshot;
export 'src/snapshots/ProjectSnapshot.dart' show ProjectSnapshot;
export 'src/snapshots/MinJournalSnapshot.dart' show MinJournalSnapshot;
export 'src/snapshots/JournalSnapshot.dart' show JournalSnapshot;
export 'src/models/exceptions.dart';

final Logger _logger = Logger('Buckets');

class Buckets {
  static void setLogLevel({Level level = Level.WARNING}) {
    setupLogging(level);
  }

  static Level getLogLevel() {
    return Logger.root.level;
  }

  static void switchToDevelopment() {
    Config.setEnvironment(Environment.DEVELOPMENT);
  }

  static void switchToStaging() {
    Config.setEnvironment(Environment.STAGING);
  }

  static ProjectClient client() {
    if (BucketAuth.loggedIn) {
      return BucketAuth.curClient;
    }

    throw const BucketsAuthException(
      message: "Client not authenticated. Call BucketAuth.clientLogin()",
    );
  }

  static Project project() {
    if (!BucketAuth.loggedIn) {
      _logger.warning("User not logged in! Use BucketAuth to login user!");
      throw const BucketsAuthException(
        message: "User not authenticated. Call BucketAuth.login()",
      );
    }

    try {
      return BucketAuth.curClient.project;
    } catch (e, stackTrace) {
      _logger.warning(
        "Error fetching project from client",
        e,
        stackTrace,
      );

      throw BucketsUnknownException(
        message: "Failed to fetch project",
        cause: e,
      );
    }
  }
}

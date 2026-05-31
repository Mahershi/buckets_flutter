// TODO: why is this gitignored
import 'package:logging/logging.dart';

final Logger _logger = Logger("Config");

enum Environment {DEVELOPMENT, STAGING}

class Config{
  static String _host = "http://localhost:8000/";
  static String _wsHost = "ws://localhost:8000/";
  static int _port = 8000;
  static Environment _currentEnvironment = Environment.DEVELOPMENT;

  static const String _tokenURL = 'api/token/';
  static const String _clientTokenURL = 'api/client-token/';
  static const String _tokenRefreshURL = 'api/token/refresh/';
  static const String _userBucketURL = 'app/user-buckets/bucket';
  static const String _webSocketURL = 'bucket/stream/';
  static const String _getClient = 'app/project-client/me';
  static const String _getJournal = 'app/journal/';
  static const String _count = 'count';
  static const String _getJournalByName = 'app/journal/me';
  static const String _getRecord = 'record';
  static const String _hasRecord = 'has_record';
  static const String _projectWebSocketURL = 'project/stream/';
  static const String _journalWebSocketURL = 'journal/stream/';
  static const String _exjournalWebSocketURL = 'exjournal/stream/';
  static const String _recordWebSocketURL = 'record/stream/';
  static const String _storage = 'app/storage/';
  static const String _media = 'media/projects/';

  static const String _userURL = 'app/user/me';

  static Environment get currentEnvironment => _currentEnvironment;
  static String get host => _host;
  static String get wsHost => _wsHost;
  static int get port => _port;
  static String get tokenURL => _tokenURL;
  static String get clientTokenURL => _clientTokenURL;
  static String get tokenRefreshURL => _tokenRefreshURL;
  static String get userBucketURL => _userBucketURL;
  static String get webSocketURL => _webSocketURL;
  static String get userURL => _userURL;
  static String get getClient => _getClient;
  static String get getJournal => _getJournal;
  static String get count => _count;
  static String get getJournalByName => _getJournalByName;
  static String get getRecord => _getRecord;
  static String get hasRecord => _hasRecord;
  static String get projectWebSocketURL => _projectWebSocketURL;
  static String get journalWebSocketURL => _journalWebSocketURL;
  static String get exjournalWebSocketURL => _exjournalWebSocketURL;
  static String get recordWebSocketURL => _recordWebSocketURL;
  static String get storage => _storage;
  static String get media => _media;

  static const Map<String, int> typeMap = {
    "STRING": 1,
    "NUMBER": 2,
    "BOOLEAN": 3,
    "ARRAY": 4,
    "MAP": 5
  };

  static void setEnvironment(Environment env){
    switch(env){
      case Environment.DEVELOPMENT:
        // this is default.
        Config._currentEnvironment = env;
        _logger.fine("ENVIRONMENT: DEVELOPMENT");
        break;
      case Environment.STAGING:
        Config._host = "https://api.buckets.mahershi.com/";
        Config._wsHost = "wss://api.buckets.mahershi.com/";
        Config._port = 9999;
        Config._currentEnvironment = env;
        _logger.fine("ENVIRONMENT: STAGING");
    }
  }
}
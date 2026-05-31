import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:http/http.dart' as http;

import '../../buckets.dart';
import '../config.dart';
import 'exceptions.dart';

final Logger _logger = Logger('Journal');

class Journal {
  final Project _project;
  final String _name;
  final String _id;
  final String _created_at;
  final String _created_by_user;

  String get id => _id;
  String get name => _name;
  String get created_at => _created_at;
  String get created_by_user => _created_by_user;
  Project get project => _project;

  Journal(this._project, this._id, this._name, this._created_at, this._created_by_user);

  Journal.empty():
      _project = Project.empty(),
    _id = '',
    _name = '',
    _created_at = '',
    _created_by_user = '';

  // this will create record with the name if it does not exist.
  Future<Record> record(String record) async {
    try {
      final url = "${Config.host}${Config.getJournal}${_id}/${Config.getRecord}/?project_id=${_project.id}";
      _logger.fine("Fetching record URL: $url");

      final response = await http.post(
        Uri.parse(url),
        body: {
          "record": record,
        },
        headers: BucketAuth.headers(),
      );
      _logger.fine("Fetch Record StatusCode ${response.statusCode}");
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body)['data'];
        return Record(
          this,
          jsonData['id'].toString(),
          jsonData['name'].toString(),
          jsonData['created_at'].toString(),
        );
      }

      throw BucketsServerException(
        message: "Failed to fetch record",
        cause: {
          "statusCode": response.statusCode,
          "body": response.body,
        },
      );

    } on SocketException catch (e) {
      throw BucketsConnectionException(
        message: "Network error while fetching record",
        cause: e,
      );
    } catch (e, stackTrace) {
      _logger.warning("Error Fetching Record", e, stackTrace);
      if (e is BucketsException) rethrow;
      throw BucketsUnknownException(
        message: "Unexpected error while fetching record",
        cause: e,
      );
    }
  }

  Future<bool> recordExists(String record) async {
    try {
      final url = "${Config.host}${Config.getJournal}${_id}/${Config.hasRecord}/?project_id=${_project.id}";
      _logger.fine("Check record exists: $url");
      final response = await http.post(
        Uri.parse(url),
        body: {
          "record": record,
        },
        headers: BucketAuth.headers(),
      );

      if (response.statusCode == 200) return true;
      if (response.statusCode == 404) return false;

      throw BucketsServerException(
        message: "Unexpected response while checking record existence",
        cause: {
          "statusCode": response.statusCode,
          "body": response.body,
        },
      );

    } on SocketException catch (e) {
      throw BucketsConnectionException(
        message: "Network error while checking record existence",
        cause: e,
      );
    } catch (e, stackTrace) {
      _logger.warning("Error checking record existence", e, stackTrace);
      if (e is BucketsException) rethrow;
      throw BucketsUnknownException(
        message: "Unexpected error while checking record existence",
        cause: e,
      );
    }
  }

  Future<int> count({List<Map<String, dynamic>>? filters}) async {
    try {
      final url = "${Config.host}${Config.getJournal}${_id}/${Config.count}/?project_id=${_project.id}";
      _logger.fine("Count URL: $url");
      final response = await http.post(
        Uri.parse(url),
        body: jsonEncode({
          "filters": filters ?? [],
        }),
        headers: {
          ...BucketAuth.headers(),
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['data']['count'] as int;
      }
      throw BucketsServerException(
        message: "Failed to fetch count",
        cause: {
          "statusCode": response.statusCode,
          "body": response.body,
        },
      );

    } on SocketException catch (e) {
      throw BucketsConnectionException(
        message: "Network error while fetching count",
        cause: e,
      );
    } catch (e, stackTrace) {
      _logger.warning("Error fetching count", e, stackTrace);
      if (e is BucketsException) rethrow;
      throw BucketsUnknownException(
        message: "Unexpected error while fetching count",
        cause: e,
      );
    }
  }

  bool isNull(){
    return this._id == '';
  }
  //
  // // default returns reference to Extended Journal
  // // if type give, returns MinJournal (for dashboard)
  // T getReference<T>(){
  //   if (T == MinJournalReference) {
  //     String wsUrl = '${Config.wsHost}${Config.journalWebSocketURL}${this._id}';
  //     return MinJournalReference(wsUrl) as T;
  //   }else {
  //     String wsUrl = '${Config.wsHost}${Config.exjournalWebSocketURL}${this._id}';
  //     return JournalReference(wsUrl) as T;
  //   }
  // }
  //
  JournalReference getReference(){
    String wsUrl = '${Config.wsHost}${Config.exjournalWebSocketURL}${this._id}';
    return JournalReference(wsUrl);
  }

  MinJournalReference getMinReference(){
    String wsUrl = '${Config.wsHost}${Config.journalWebSocketURL}${this._id}';
    return MinJournalReference(wsUrl);
  }
}
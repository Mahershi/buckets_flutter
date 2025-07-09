import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:http/http.dart' as http;

import '../../buckets.dart';
import '../config.dart';
import '../references/JournalReference.dart';
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

  // Will create the record if doesnt exist
  // TODO: test pending.
  Future<Record> record(String record) async {
    try{
      _logger.info("Fetching record URL: ${Config.host}${Config.getJournal}${_id}/${Config.getRecord}?record=${record}");
      _logger.info("Client Auth Header: ${BucketAuth.headers()}");
      var response = await http.post(
          Uri.parse(
              "${Config.host}${Config.getJournal}${_id}/${Config.getRecord}/?project_id=${_project.id}",
          ),
          body: {
            "record": record
          },
          headers: BucketAuth.headers()
      );
      _logger.info("Fetch Record StatusCode ${response.statusCode}");
      if (response.statusCode == 200){
        var jsonData = jsonDecode(response.body)['data'];
        _logger.fine("Fetched Record JSON: " + jsonData.toString());
        return Record(
          this,
          jsonData['id'].toString(),
          jsonData['name'].toString(),
          jsonData['created_at'].toString()
        );
      }else{
        _logger.severe("${response.body}");
      }
    }catch(e, stackTrace){
      _logger.warning("Error Fetching Record", e, stackTrace);
      throw UnknownException("Error Fetching Record");
    }
    return Record.empty();
  }

  bool isNull(){
    return this._id == '';
  }

  // default returns reference to Extended Journal
  // if type give, returns MinJournal (for dashboard)
  T getReference<T>(){
    if (T == MinJournalReference) {
      String wsUrl = '${Config.wsHost}${Config.journalWebSocketURL}${this._id}';
      return MinJournalReference(wsUrl) as T;
    }else {
      String wsUrl = '${Config.wsHost}${Config.exjournalWebSocketURL}${this._id}';
      return JournalReference(wsUrl) as T;
    }
  }
  //
  // JournalReference getReference(){
  //   String wsUrl = '${Config.wsHost}${Config.exjournalWebSocketURL}${this._id}';
  //   return JournalReference(wsUrl);
  // }
}
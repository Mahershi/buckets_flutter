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

  // TODO: get record by name and not id. Record names in journal will be unique
  // TODO: add a create:bool field, pass to API, if not exists, create record.
  Future<Record> record(String recordId) async {
    try{
      _logger.info("Fetching record URL: ${Config.host}${Config.getJournal}${_id}/${Config.getRecord}?record_id=${recordId}");
      var response = await http.get(
          Uri.parse(
              "${Config.host}${Config.getJournal}${_id}/${Config.getRecord}?record_id=${recordId}"
          ),
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
      }
    }catch(e){
      _logger.warning("Error Fetching Record");
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
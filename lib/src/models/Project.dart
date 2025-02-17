import 'dart:convert';

import 'package:buckets/src/references/ProjectReference.dart';
import 'package:logging/logging.dart';
import 'package:http/http.dart' as http;
import '../../buckets.dart';
import '../config.dart';
import 'Journal.dart';
import 'exceptions.dart';

final Logger _logger = Logger('Project');


class Project{
  final String _id;
  final String _name;
  final String _created_at;

  String get name => _name;
  String get id => _id;
  String get created_at => _created_at;

  Project(this._id, this._name, this._created_at);

  // Using in empty client when client logs out.
  Project.empty() :
        _id = '',
        _name = '',
        _created_at = '';

  Future<Journal> journal(String journalId) async {
    try{
      var response = await http.get(
          Uri.parse(
            "${Config.host}${Config.getJournal}$journalId" ,
          ),
          headers: BucketAuth.headers()
      );
      if (response.statusCode == 200){
        var jsonData = jsonDecode(response.body)['data'];
        return Journal(
            this,
            jsonData['id'].toString(),
            jsonData['name'],
            jsonData['created_at'],
            jsonData['created_by_user'] ?? ''
        );
      }
    }catch(e){
      _logger.warning("Error Fetching Journal");
      throw UnknownException("Error Fetching Journal");
    }
    return Journal.empty();
  }

  bool isNull(){
    return this._id == '';
  }

  ProjectReference getReference(){
    String wsUrl = '${Config.wsHost}${Config.projectWebSocketURL}${this._id}';
    return ProjectReference(wsUrl);
  }
}
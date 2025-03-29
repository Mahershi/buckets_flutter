import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../buckets.dart';
import '../config.dart';
import 'exceptions.dart';
import 'dart:io';
import 'package:path/path.dart';
import 'package:mime/mime.dart';

final Logger _logger = Logger('Project');


class Project{
  final String _id;
  final String _name;
  final String _created_at;
  final bool _is_active;

  String get name => _name;
  String get id => _id;
  String get created_at => _created_at;
  bool get is_active => _is_active;

  Project(this._id, this._name, this._created_at, this._is_active);

  // Using in empty client when client logs out.
  Project.empty() :
        _id = '',
        _name = '',
        _created_at = '',
        _is_active=true;

  Future<Journal> journal(String journalId) async {
    try{
      _logger.info("Fetching journal URL: ${Config.host}${Config.getJournal}$journalId");
      var response = await http.get(
          Uri.parse(
            "${Config.host}${Config.getJournal}$journalId" ,
          ),
          headers: BucketAuth.headers()
      );
      _logger.info("Fetch Journal StatusCode ${response.statusCode}");
      if (response.statusCode == 200){
        var jsonData = jsonDecode(response.body)['data'];
        _logger.fine("Fetched Journal JSON: " + jsonData.toString());
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

  Future<String> putFile({File? file, String path=""}) async {
    if (file == null){
      return "";
    }
    try{
      _logger.info("File Upload URL: ${Config.host}${Config.storage}?project_id=${id}");
      var req = await http.MultipartRequest(
          "POST",
          Uri.parse(
            "${Config.host}${Config.storage}?project_id=${id}" ,
          ),
      )..headers.addAll(BucketAuth.headers())
      ..fields['path'] = path
      ..files.add(
        await http.MultipartFile.fromPath(
          'file',    // the "field name for the file obj"
          file.path,   // local path of the file
          contentType: MediaType.parse(lookupMimeType(file.path) ?? 'application/octet-stream')
        )
      );
      var response = await req.send();
      _logger.info("Status Code: ${response.statusCode}");
      if (response.statusCode == 201) {
        _logger.info("Upload Success!");
        var jsonResponse = jsonDecode(await response.stream.bytesToString());
        _logger.info(jsonResponse);
        String slug = jsonResponse['data']['url'];
        if (slug.startsWith('/')){
          slug = slug.substring(1,);
        }
        return "${Config.host}${slug}";
      } else {
        _logger.severe("Upload failed: ${response.statusCode}");
        var responseBody = await response.stream.bytesToString();
        _logger.info(responseBody);
      }
    }catch(e){
      _logger.severe("Error Uploading File: ${e.toString()}");
    }
    return "";
  }
}
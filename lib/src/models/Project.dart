import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../buckets.dart';
import '../config.dart';
import 'dart:io';
import 'package:mime/mime.dart';

import 'exceptions.dart';

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

  Future<Journal> journal(String journalName) async {
    try {

      final url = "${Config.host}${Config.getJournalByName}/?project_id=$_id";
      _logger.fine("Fetching journal URL: $url");
      final response = await http.post(
        Uri.parse(url),
        body: {
          "journal_name": journalName,
        },
        headers: BucketAuth.headers(),
      );
      _logger.fine("Fetch Journal StatusCode ${response.statusCode}");

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body)['data'];

        return Journal(
          this,
          jsonData['id'].toString(),
          jsonData['name'],
          jsonData['created_at'],
          jsonData['created_by_user'] ?? '',
        );
      }

      // handle non-200 properly
      throw BucketsServerException(
        message: "Failed to fetch journal",
        cause: {
          "statusCode": response.statusCode,
          "body": response.body,
        },
      );

    } on SocketException catch (e) {
      throw BucketsConnectionException(
        message: "Network error while fetching journal",
        cause: e,
      );
    } catch (e, stackTrace) {
      _logger.warning("Error Fetching Journal", e, stackTrace);
      if (e is BucketsException) rethrow;
      throw BucketsUnknownException(
        message: "Unexpected error while fetching journal",
        cause: e,
      );
    }
  }

  bool isNull(){
    return this._id == '';
  }

  ProjectReference getReference(){
    String wsUrl = '${Config.wsHost}${Config.projectWebSocketURL}${this._id}';
    return ProjectReference(wsUrl);
  }

  Future<String> putFile({File? file, String path = ""}) async {
    if (file == null) {
      throw const BucketsInvalidArgumentException("File cannot be null");
    }

    try {
      final url = "${Config.host}${Config.storage}?project_id=$id";
      _logger.fine("File Upload URL: $url");
      final req = http.MultipartRequest(
        "POST",
        Uri.parse(url),
      )
        ..headers.addAll(BucketAuth.headers())
        ..fields['path'] = path
        ..files.add(
          await http.MultipartFile.fromPath(
            'file', // field name for the file object in the api call
            file.path, // local path of the file
            contentType: MediaType.parse(
              lookupMimeType(file.path) ?? 'application/octet-stream',
            ),
          ),
        );

      final response = await req.send();
      _logger.fine("Status Code: ${response.statusCode}");
      final responseBody = await response.stream.bytesToString();
      if (response.statusCode == 201) {
        final jsonResponse = jsonDecode(responseBody);
        String slug = jsonResponse['data']['url'];
        if (slug.startsWith('/')) {
          slug = slug.substring(1);
        }
        return "${Config.host}$slug";
      }
      throw BucketsServerException(
        message: "File upload failed",
        cause: {
          "statusCode": response.statusCode,
          "body": responseBody,
        },
      );

    } on SocketException catch (e) {
      throw BucketsConnectionException(
        message: "Network error during file upload",
        cause: e,
      );
    } catch (e, stackTrace) {
      _logger.severe("Error Uploading File", e, stackTrace);

      if (e is BucketsException) rethrow;

      throw BucketsUnknownException(
        message: "Unexpected error during file upload",
        cause: e,
      );
    }
  }
}
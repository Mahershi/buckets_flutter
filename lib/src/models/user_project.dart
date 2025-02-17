import 'package:buckets/buckets.dart';

class UserProject{
  String _id;
  Project _project;
  Access _access;
  String _joined_at;

  Project get project => _project;
  String get id => _id;
  String get joined_at => _joined_at;
  Access get access => _access;

  UserProject(this._project, this._id, this._access, this._joined_at);

  UserProject.empty():
      _project = Project.empty(),
      _id = '',
      _access = Access.VIEWER,
      _joined_at = '';

  bool isNull(){
    return this._id == '';
  }

}
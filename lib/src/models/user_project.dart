import 'package:buckets/buckets.dart';

class UserProject{
  String _id;
  Project _project;
  Access _access;
  String _joined_at;
  User _user;

  Project get project => _project;
  String get id => _id;
  String get joined_at => _joined_at;
  Access get access => _access;
  User get user => _user;

  UserProject(this._project, this._id, this._access, this._joined_at, this._user);

  UserProject.empty():
      _project = Project.empty(),
      _id = '',
      _access = Access.VIEWER,
      _joined_at = '',
      _user = User.empty();

  bool isNull(){
    return this._id == '';
  }

}
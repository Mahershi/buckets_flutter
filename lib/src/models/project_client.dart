import 'package:buckets/buckets.dart';
import 'package:logging/logging.dart';
import 'Project.dart';


final Logger _logger = Logger("ProjectClient");

class ProjectClient {
  final String _id;
  final String _name;
  final String _clientId;
  final String _clientKey;
  final bool _isDefault;
  final bool _isActive;
  final Project _project;
  final Access _access;

  String get id => _id;

  String get name => _name;

  bool get isActive => _isActive;

  bool get isDefault => _isDefault;

  Project get project => _project;

  String get clientId => _clientId;

  String get clientKey => _clientKey;

  Access get access => _access;

  ProjectClient(this._id, this._name, this._clientId, this._clientKey, this._isActive,
      this._isDefault, this._project, this._access);

  // Used when logged out of client.
  ProjectClient.empty()
      : _id = '',
        _name = '',
        _clientId = '',
        _clientKey = '',
        _isActive = false,
        _isDefault = false,
        _project = Project.empty(),
  // TODO: giving viewer to new client temporary will change with flow
      _access = Access.VIEWER;
}
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
}
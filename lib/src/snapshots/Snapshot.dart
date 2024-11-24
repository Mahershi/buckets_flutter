abstract class Snapshot{
  // snapshot common method - none yet
  // could be like, toJson, etc
  String _id;
  String _name;
  Map<String, dynamic> _data;

  Snapshot(this._id, this._name, this._data);

  Map<String, dynamic> get data => _data;
  String get name => _name;
  String get id => _id;
}
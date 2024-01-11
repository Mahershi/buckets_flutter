class Bucket{
  final String _id;
  final String _name;
  final String _createdAt;

  String get id => _id;
  String get name => _name;
  String get createdAt => _createdAt;

  Bucket(this._id, this._name, this._createdAt);
}
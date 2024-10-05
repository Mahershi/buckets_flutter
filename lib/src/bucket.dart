class Bucket{
  final String _id;
  final String _name;
  final String _createdAt;
  final bool _is_active;

  String get id => _id;
  String get name => _name;
  String get createdAt => _createdAt;
  bool get is_active => _is_active;

  Bucket(this._id, this._name, this._createdAt, this._is_active);
}
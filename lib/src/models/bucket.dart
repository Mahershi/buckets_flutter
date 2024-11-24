class Bucket{
  final String _id;
  final String _name;
  final String _createdAt;
  final bool _isActive;

  String get id => _id;
  String get name => _name;
  String get createdAt => _createdAt;
  bool get is_active => _isActive;

  Bucket(this._id, this._name, this._createdAt, this._isActive);

  Bucket.empty()
      : _id = '',
        _name = '',
        _createdAt = '',
        _isActive = false;
}
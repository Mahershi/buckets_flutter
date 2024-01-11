class User{
  final String _id;
  final String _name;
  final String _email;

  String get id => _id;
  String get name => _name;
  String get email => _email;

  User(this._id, this._name, this._email);
}
final Map<String, dynamic> type_map = {
  'Owner': {
    'WRITE_ACCESS': true,
    'READ_ACCESS': true
  },
  'Editor': {
    'WRITE_ACCESS': true,
    'READ_ACCESS': true
  },
  'Viewer': {
    'WRITE_ACCESS': false,
    'READ_ACCESS': true
  },
};

class Access{
  final String _id;
  final String _type;

  String get type => _type;
  String get id => _id;

  bool _WRITE_ACCESS = false;
  bool _READ_ACCESS = false;

  bool get WRITE_ACCESS => _WRITE_ACCESS;
  bool get READ_ACCESS => _READ_ACCESS;

  Access(this._id, this._type){
    _WRITE_ACCESS = type_map[_type]['WRITE_ACCESS'];
    _READ_ACCESS = type_map[_type]['READ_ACCESS'];
  }

  static final Access OWNER = Access('1', 'Owner');
  static final Access EDITOR = Access('2', 'Editor');
  static final Access VIEWER = Access('3', 'Viewer');

  @override
  bool operator ==(Object other){
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is Access && this._id == other._id && this._type == other._type;
  }

  @override
  int get hashCode => _id.hashCode ^ _type.hashCode;
}
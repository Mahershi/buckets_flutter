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

  bool _WRITE_ACCESS = false;
  bool _READ_ACCESS = false;

  bool get WRITE_ACCESS => _WRITE_ACCESS;
  bool get READ_ACCESS => _READ_ACCESS;

  Access(this._id, this._type){
    _WRITE_ACCESS = type_map[_type]['WRITE_ACCESS'];
    _READ_ACCESS = type_map[_type]['READ_ACCESS'];
  }


}
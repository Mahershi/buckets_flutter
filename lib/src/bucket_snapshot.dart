import 'package:buckets/src/field_type.dart';

class BucketSnapshot{
  final String _id;
  final String _name;
  final Map<String, dynamic> _data;
  final String _snapshotType;

  String get id => _id;
  String get name => _name;
  String get snapshotType => _snapshotType;

  Map<String, dynamic> get data => _data;


  BucketSnapshot.fromJson(this._id, this._name, this._data, this._snapshotType);

  dynamic get(Object field){
    if (data.containsKey(field)){
      return data[field]['value'];
    }
    return null;
  }

  FieldType typeOf(Object field){
    if (data.containsKey(field)){
      return type_map[data[field]['type']];
    }
    return type_map['UNKNOWN'];
  }
}

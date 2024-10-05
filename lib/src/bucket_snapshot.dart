import 'package:buckets/buckets.dart';
import 'package:buckets/src/field_type.dart';
import 'package:logging/logging.dart';

final Logger _logger = Logger('BucketSnapshot');

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


  // Universal get method -> this will get the 'value' field for ANY type. Dict, Array or basic. in case of Dict, it return raw data.

  dynamic get(String field){
    List<String> parts = field.split('.');
    Map<String, dynamic> data = _data;
    for(var i=0; i<parts.length-1; i++){
      data = data[parts[i]]['value'];
    }
    field = parts.last;
    _logger.fine("get() data after dot iteration: " + data.toString());
    _logger.fine("get() field after dot iteration: " + field.toString());
    if (data.containsKey(field)){
      return data[field]['value'];
    }
    _logger.warning("get() field \'${field}\' not found");
    return null;
  }
  
  BucketSnapshot getMap(String field){
    List<String> parts = field.split('.');
    Map<String, dynamic> data = _data;
    for(var i=0; i<parts.length-1; i++){
      data = data[parts[i]]['value'];
    }
    field = parts.last;
    _logger.fine("getMap() data after dot iteration: " + data.toString());
    _logger.fine("getMap() field after dot iteration: " + field.toString());
    if(data.containsKey(field)){
      BucketSnapshot bs = BucketSnapshot.fromJson(_id, _name, data[field]['value'], _snapshotType);
      return bs;
    }
    _logger.warning("getMap() field \'${field}\' not found, returning BucketSnapshot with empty data");
    return BucketSnapshot.fromJson(_id, _name, {}, _snapshotType);
  }

  FieldType typeOf(String field){
    List<String> parts = field.split('.');
    Map<String, dynamic> data = _data;
    for(var i=0; i<parts.length-1; i++){
      data = data[parts[i]]['value'];
    }
    field = parts.last;
    _logger.fine("typeOf() data after dot iteration: " + data.toString());
    _logger.fine("typeOf() field after dot iteration: " + field.toString());
    if (data.containsKey(field)){
      return type_map[data[field]['type']];
    }
    _logger.warning("typeOf() field \'${field}\' not found");
    return type_map['UNKNOWN'];
  }
}

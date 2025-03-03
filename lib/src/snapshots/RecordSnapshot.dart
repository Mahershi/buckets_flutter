import 'package:logging/logging.dart';
import '../models/field_type.dart';
import '../../buckets.dart';
// import '../models/access.dart';
import 'Snapshot.dart';

final Logger _logger = Logger('RecordSnapshot');

class RecordSnapshot extends Snapshot{
  // here data is map
  /*
  {
    "field1": {"value": "ss", "created_at": "timestamp", "type": "STRING"},
    "field2": {}
  }
   */

  RecordSnapshot(String id, String name, Map<String, dynamic> data) : super(id, name, data);


  // Universal get method -> this will get the 'value' field for ANY type. Dict, Array or basic. in case of Dict, it return raw data.
  dynamic get(String field){
    List<String> parts = field.split('.');
    Map<String, dynamic> data = this.data;
    for(var i=0; i<parts.length-1; i++){
      data = data[parts[i]]['value'];
    }
    field = parts.last;
    // too much logging is lagging dashboard if very huge number of fields.
    // _logger.fine("get() data after dot iteration: " + data.toString());
    // _logger.fine("get() field after dot iteration: " + field.toString());
    if (data.containsKey(field)){
      return data[field]['value'];
    }
    _logger.warning("get() field \'${field}\' not found");
    return null;
  }

  RecordSnapshot getMap(String field){
    List<String> parts = field.split('.');
    Map<String, dynamic> data = this.data;
    for(var i=0; i<parts.length-1; i++){
      data = data[parts[i]]['value'];
    }
    field = parts.last;
    // too much logging is lagging dashboard if very huge number of fields.
    // _logger.fine("getMap() data after dot iteration: " + data.toString());
    // _logger.fine("getMap() field after dot iteration: " + field.toString());
    if(data.containsKey(field)){
      return RecordSnapshot(this.id, this.name, data[field]['value']);
      // BucketSnapshot bs = BucketSnapshot.fromJson(_id, _name, data[field]['value'], _snapshotType);
      // return bs;
    }
    _logger.warning("getMap() field \'${field}\' not found, returning BucketSnapshot with empty data");
    return RecordSnapshot(this.id, this.name, {});
    // return BucketSnapshot.fromJson(_id, _name, {}, _snapshotType);
  }

  FieldType typeOf(String field){
    List<String> parts = field.split('.');
    Map<String, dynamic> data = this.data;
    for(var i=0; i<parts.length-1; i++){
      data = data[parts[i]]['value'];
    }
    field = parts.last;
    // too much logging is lagging dashboard if very huge number of fields.
    // _logger.fine("typeOf() data after dot iteration: " + data.toString());
    // _logger.fine("typeOf() field after dot iteration: " + field.toString());
    if (data.containsKey(field)){
      return type_map[data[field]['type']];
    }
    _logger.warning("typeOf() field \'${field}\' not found");
    return type_map['UNKNOWN'];
  }
}
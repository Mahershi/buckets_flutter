import 'package:logging/logging.dart';

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
    _logger.fine("get() data after dot iteration: " + data.toString());
    _logger.fine("get() field after dot iteration: " + field.toString());
    if (data.containsKey(field)){
      return data[field]['value'];
    }
    _logger.warning("get() field \'${field}\' not found");
    return null;
  }
}
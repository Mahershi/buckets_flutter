import 'package:buckets/src/references/RecordReference.dart';
import 'package:logging/logging.dart';
import '../config.dart';
import 'Journal.dart';


final Logger _logger = Logger('Record');


class Record{
  final Journal _journal;
  final String _id;
  final String _name;
  final String _created_at;

  Journal get journal => _journal;
  String get name => _name;
  String get id => _id;
  String get created_at => _created_at;

  Record(this._journal, this._id, this._name, this._created_at);

  // Using in empty client when client logs out.
  Record.empty() :
        _journal = Journal.empty(),
        _id = '',
        _name = '',
        _created_at = '';

  bool isNull(){
    return this._id == '';
  }


  RecordReference getReference(){
    String wsUrl = '${Config.wsHost}${Config.recordWebSocketURL}${this._id}';
    return RecordReference(wsUrl);
  }
}
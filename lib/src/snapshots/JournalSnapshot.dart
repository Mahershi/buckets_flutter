import 'Snapshot.dart';

class JournalSnapshot extends Snapshot{
  // here data is map
  /*
  {
    "records": [
      {
        "name": "r1",
        "id": 1
      },
      {
        "name": "r22",
        "id": 2
      },
      ...
    ]
  }
   */

  JournalSnapshot(id, name, data) : super(id, name, data);
}
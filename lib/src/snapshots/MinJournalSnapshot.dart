import 'Snapshot.dart';

class MinJournalSnapshot extends Snapshot{
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

  MinJournalSnapshot(id, name, data) : super(id, name, data);
}
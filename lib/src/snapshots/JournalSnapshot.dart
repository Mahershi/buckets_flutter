import 'package:buckets/buckets.dart';

import 'Snapshot.dart';

// data field here will not be map
// it needs to be list of RecordSnapshot or something
// TODO: figure this out.
class JournalSnapshot extends MinJournalSnapshot{
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
  JournalSnapshot.empty() : super("", "", {"records": []});
}
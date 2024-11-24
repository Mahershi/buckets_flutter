import 'Snapshot.dart';

class ProjectSnapshot extends Snapshot{
  // here data is map
  /*
  {
    "journals": [
      {
        "name": "j1",
        "id": 1
      },
      {
        "name": "j2",
        "id": 2
      },
      ...
    ]
  }
   */

  ProjectSnapshot(id, name, data) : super(id, name, data);

  void toMe(){

  }
}
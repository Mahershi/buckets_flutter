import 'package:flutter_test/flutter_test.dart';
import 'package:buckets/src/jwt_token_handler.dart' as jwt;

void main(){
  test('Refresh JWT', () async {
    var jwtObj = jwt.JWTTokenHandler(
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoiYWNjZXNzIiwiZXhwIjoxNzA0Nzk0NzA2LCJpYXQiOjE3MDQ3ODc1MDYsImp0aSI6ImM2Y2IxMzkwMTE3YjQ2YjRhYzNhYjUyNDRmMDRjYjBkIiwidXNlcl9pZCI6M30.IMp7OmdnriCtIz646ErZvkpOqKD6859ws63D3UK5Dps",
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTcwNDg3MzkwNiwiaWF0IjoxNzA0Nzg3NTA2LCJqdGkiOiI2MzFjYTdlNzY1NWI0YTg5ODBlNDI2ZTllMDFkYTUxZSIsInVzZXJfaWQiOjN9.gMmGaPKYK06xt79bbRNKe5GcBPtXSUP2d1bcDuYGfz8"
    );
    // Random 3 sec wait for the asyn refresh call to finish.
    await Future.delayed(const Duration(seconds: 3), (){});
    expect(jwtObj.refreshed, true);
  });
}

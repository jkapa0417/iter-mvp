import 'package:test/test.dart';
import 'package:openapi/openapi.dart';

/// tests for UsersApi
void main() {
  final instance = Openapi().getUsersApi();

  group(UsersApi, () {
    //Future<UserProfile> getOrBootstrapMe() async
    test('test getOrBootstrapMe', () async {
      // TODO
    });
  });
}

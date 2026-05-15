import 'package:test/test.dart';
import 'package:openapi/openapi.dart';

/// tests for AuthApi
void main() {
  final instance = Openapi().getAuthApi();

  group(AuthApi, () {
    //Future<MeResponse> meHandler() async
    test('test meHandler', () async {
      // TODO
    });
  });
}

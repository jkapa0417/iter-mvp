import 'package:test/test.dart';
import 'package:openapi/openapi.dart';

/// tests for SystemApi
void main() {
  final instance = Openapi().getSystemApi();

  group(SystemApi, () {
    //Future<HealthResponse> health() async
    test('test health', () async {
      // TODO
    });
  });
}

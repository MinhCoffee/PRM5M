import 'dart:convert';

import 'package:flutter_application_1/core/services/cloudinary_storage_service.dart';
import 'package:flutter_application_1/core/services/firebase/firebase_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

CloudinaryStorageService _service(
  http.Client client, {
  String? uid = 'u1',
  String cloud = 'democloud',
  String preset = 'demo_preset',
}) =>
    CloudinaryStorageService(
      client: client,
      cloudName: cloud,
      uploadPreset: preset,
      currentUid: () => uid,
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('upload returns the real secure_url and sends the preset', () async {
    late http.BaseRequest sent;
    final client = MockClient.streaming((request, body) async {
      sent = request;
      final bytes = await body.toBytes();
      expect(utf8.decode(bytes), contains('demo_preset'));
      return http.StreamedResponse(
        Stream.value(utf8.encode(jsonEncode({
          'secure_url': 'https://res.cloudinary.com/democloud/raw/upload/x.csv',
          'public_id': 'reports/u1/x.csv',
          'bytes': 7,
        }))),
        200,
      );
    });

    final progress = <double>[];
    final result = await _service(client).uploadReport(
      fileName: 'a.csv',
      content: 'a,b\n1',
      classCode: 'SE1801',
      onProgress: progress.add,
    );

    expect(sent.url.toString(),
        'https://api.cloudinary.com/v1_1/democloud/raw/upload');
    expect(result.downloadUrl,
        'https://res.cloudinary.com/democloud/raw/upload/x.csv');
    expect(result.bytes, 7);
    expect(progress.last, 1.0);
  });

  test('uploaded file shows up in history for the same user only', () async {
    final client = MockClient((_) async => http.Response(
          jsonEncode({'secure_url': 'https://x/y.csv', 'public_id': 'p'}),
          200,
        ));
    await _service(client).uploadReport(
      fileName: 'a.csv',
      content: 'a',
      classCode: 'c',
    );

    final mine = await _service(client).getUploadedReports();
    final other = await _service(client, uid: 'u2').getUploadedReports();
    expect(mine.single.fileName, 'a.csv');
    expect(other, isEmpty);
  });

  test('HTTP error becomes StorageFailure and is not recorded', () async {
    final client = MockClient((_) async => http.Response(
          jsonEncode({'error': {'message': 'Upload preset not found'}}),
          400,
        ));
    final svc = _service(client);

    await expectLater(
      svc.uploadReport(fileName: 'a.csv', content: 'a', classCode: 'c'),
      throwsA(isA<StorageFailure>().having(
        (f) => f.userMessage,
        'message',
        contains('Upload preset not found'),
      )),
    );
    expect(await svc.getUploadedReports(), isEmpty);
  });

  test('200 without secure_url is rejected, never fabricated', () async {
    final client = MockClient((_) async => http.Response('{}', 200));
    await expectLater(
      _service(client)
          .uploadReport(fileName: 'a.csv', content: 'a', classCode: 'c'),
      throwsA(isA<StorageFailure>()),
    );
  });

  test('network error maps to a network failure', () async {
    final client = MockClient((_) async => throw http.ClientException('down'));
    await expectLater(
      _service(client)
          .uploadReport(fileName: 'a.csv', content: 'a', classCode: 'c'),
      throwsA(isA<StorageFailure>()
          .having((f) => f.kind, 'kind', StorageFailureKind.network)),
    );
  });

  test('signed-out user and missing config are reported', () async {
    final client = MockClient((_) async => http.Response('{}', 200));
    await expectLater(
      _service(client, uid: null)
          .uploadReport(fileName: 'a.csv', content: 'a', classCode: 'c'),
      throwsA(isA<StorageFailure>()
          .having((f) => f.kind, 'kind', StorageFailureKind.notSignedIn)),
    );
    await expectLater(
      _service(client, preset: '')
          .uploadReport(fileName: 'a.csv', content: 'a', classCode: 'c'),
      throwsA(isA<StorageFailure>()
          .having((f) => f.userMessage, 'message', contains('.env'))),
    );
  });
}

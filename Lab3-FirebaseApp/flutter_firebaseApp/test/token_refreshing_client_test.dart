import 'dart:convert';

import 'package:flutter_application_1/services/token_refreshing_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

auth.AuthClient _clientWithToken(http.Client base, String token) {
  return auth.authenticatedClient(
    base,
    auth.AccessCredentials(
      auth.AccessToken(
        'Bearer',
        token,
        DateTime.now().toUtc().add(const Duration(hours: 1)),
      ),
      null,
      const ['https://www.googleapis.com/auth/spreadsheets'],
    ),
  );
}

void main() {
  late List<String> seenTokens;
  late List<String> seenBodies;
  late MockClient server;

  setUp(() {
    seenTokens = [];
    seenBodies = [];
    // Google accepts only the "fresh" token and answers 401 to anything else.
    server = MockClient((request) async {
      seenTokens.add(request.headers['authorization'] ?? '');
      seenBodies.add(request.body);
      if (request.headers['authorization'] == 'Bearer fresh') {
        return http.Response('{"ok":true}', 200);
      }
      return http.Response(
        '{"error":"invalid_token"}',
        401,
        headers: {'www-authenticate': 'Bearer error="invalid_token"'},
      );
    });
  });

  test('401 with an expired token: refreshes once and replays the POST body',
      () async {
    final staleSeen = <String>[];
    var refreshCalls = 0;
    final client = TokenRefreshingClient(_clientWithToken(server, 'expired'), (
      stale,
    ) async {
      refreshCalls++;
      staleSeen.add(stale);
      return _clientWithToken(server, 'fresh');
    });

    final res = await client.post(
      Uri.parse('https://sheets.test/append'),
      body: jsonEncode({'row': 'HE176579'}),
    );

    expect(res.statusCode, 200);
    expect(refreshCalls, 1);
    expect(staleSeen, ['expired']);
    expect(seenTokens, ['Bearer expired', 'Bearer fresh']);
    // The replay must carry the same body, not an empty one.
    expect(seenBodies, ['{"row":"HE176579"}', '{"row":"HE176579"}']);
  });

  test('later requests reuse the refreshed token without refreshing again',
      () async {
    var refreshCalls = 0;
    final client = TokenRefreshingClient(_clientWithToken(server, 'expired'), (
      _,
    ) async {
      refreshCalls++;
      return _clientWithToken(server, 'fresh');
    });

    await client.get(Uri.parse('https://sheets.test/a'));
    await client.get(Uri.parse('https://sheets.test/b'));

    expect(refreshCalls, 1);
    expect(seenTokens.last, 'Bearer fresh');
  });

  test('requests that fail together trigger a single refresh', () async {
    var refreshCalls = 0;
    final client = TokenRefreshingClient(_clientWithToken(server, 'expired'), (
      _,
    ) async {
      refreshCalls++;
      await Future<void>.delayed(const Duration(milliseconds: 20));
      return _clientWithToken(server, 'fresh');
    });

    final results = await Future.wait([
      client.get(Uri.parse('https://sheets.test/a')),
      client.get(Uri.parse('https://sheets.test/b')),
      client.get(Uri.parse('https://sheets.test/c')),
    ]);

    expect(results.map((r) => r.statusCode), [200, 200, 200]);
    expect(refreshCalls, 1);
  });

  test('a valid token is sent as is and never refreshed', () async {
    var refreshCalls = 0;
    final client = TokenRefreshingClient(_clientWithToken(server, 'fresh'), (
      _,
    ) async {
      refreshCalls++;
      return _clientWithToken(server, 'fresh');
    });

    final res = await client.get(Uri.parse('https://sheets.test/a'));

    expect(res.statusCode, 200);
    expect(refreshCalls, 0);
    expect(seenTokens, ['Bearer fresh']);
  });

  test('still rejected after the refresh: error surfaces, no retry loop',
      () async {
    var refreshCalls = 0;
    final client = TokenRefreshingClient(_clientWithToken(server, 'expired'), (
      _,
    ) async {
      refreshCalls++;
      return _clientWithToken(server, 'also-bad');
    });

    await expectLater(
      client.get(Uri.parse('https://sheets.test/a')),
      throwsA(isA<auth.AccessDeniedException>()),
    );

    expect(refreshCalls, 1);
    expect(seenTokens, ['Bearer expired', 'Bearer also-bad']);
  });

  test('a plain 401 response (no www-authenticate header) also refreshes',
      () async {
    final tokens = <String>[];
    final headerless = MockClient((request) async {
      tokens.add(request.headers['authorization'] ?? '');
      return request.headers['authorization'] == 'Bearer fresh'
          ? http.Response('ok', 200)
          : http.Response('unauthorized', 401);
    });
    final client = TokenRefreshingClient(
      _clientWithToken(headerless, 'expired'),
      (_) async => _clientWithToken(headerless, 'fresh'),
    );

    final res = await client.get(Uri.parse('https://sheets.test/a'));

    expect(res.statusCode, 200);
    expect(tokens, ['Bearer expired', 'Bearer fresh']);
  });

  test('a failing refresh surfaces its error to the caller', () async {
    final client = TokenRefreshingClient(
      _clientWithToken(server, 'expired'),
      (_) async => throw StateError('user revoked access'),
    );

    await expectLater(
      client.get(Uri.parse('https://sheets.test/a')),
      throwsA(isA<StateError>()),
    );
  });
}

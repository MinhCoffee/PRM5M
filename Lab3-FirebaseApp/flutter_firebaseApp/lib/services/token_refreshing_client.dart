import 'dart:async';

import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;

/// Obtains a fresh Google client after [staleAccessToken] was rejected.
typedef AuthClientRefresher = Future<auth.AuthClient> Function(
  String staleAccessToken,
);

/// Adapts a native Google Sign-In [auth.AuthClient] to the
/// [auth.AutoRefreshingAuthClient] type required by `GSheets.withClient`.
///
/// The wrapped client carries one access token that expires after about an
/// hour, and nothing renews it. When Google answers 401 (`invalid_token`),
/// this client asks [_refresh] for a new client and replays the request once,
/// so a long session does not start failing every save.
class TokenRefreshingClient extends http.BaseClient
    implements auth.AutoRefreshingAuthClient {
  TokenRefreshingClient(this._inner, this._refresh);

  auth.AuthClient _inner;
  final AuthClientRefresher _refresh;
  Future<void>? _refreshing;

  @override
  auth.AccessCredentials get credentials => _inner.credentials;

  @override
  Stream<auth.AccessCredentials> get credentialUpdates =>
      const Stream<auth.AccessCredentials>.empty();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // A request body can be sent only once, so keep a copy for the replay.
    final replay = _copy(request);
    final usedToken = _inner.credentials.accessToken.data;
    try {
      final response = await _inner.send(request);
      if (response.statusCode != 401 || replay == null) return response;
      // Drain the failed response so its connection is released.
      await response.stream.drain<void>();
    } on auth.AccessDeniedException {
      // googleapis_auth does not hand back the 401: whenever the response has
      // a `www-authenticate` header (e.g. `error="invalid_token"`) it throws
      // this instead. That is the failure seen in the app, so handle it here.
      if (replay == null) rethrow;
    }
    await _refreshOnce(usedToken);
    return _inner.send(replay);
  }

  /// Several requests can fail together; only the first one refreshes.
  Future<void> _refreshOnce(String staleToken) {
    if (_inner.credentials.accessToken.data != staleToken) {
      // Another request already replaced the token.
      return Future<void>.value();
    }
    return _refreshing ??= _refresh(staleToken)
        .then((fresh) {
          _inner = fresh;
        })
        .whenComplete(() => _refreshing = null);
  }

  /// Only plain requests (what `gsheets` sends) can be copied for a replay.
  http.Request? _copy(http.BaseRequest request) {
    if (request is! http.Request) return null;
    return http.Request(request.method, request.url)
      ..headers.addAll(request.headers)
      ..bodyBytes = request.bodyBytes
      ..followRedirects = request.followRedirects
      ..maxRedirects = request.maxRedirects
      ..persistentConnection = request.persistentConnection;
  }

  @override
  void close() => _inner.close();
}

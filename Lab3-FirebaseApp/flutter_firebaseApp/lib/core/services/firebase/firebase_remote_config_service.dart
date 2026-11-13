import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_evidence_logger.dart';

abstract interface class IRemoteConfigService {
  Future<void> initialize();

  /// Fetches the latest template and activates it. Returns true only when a
  /// fetch succeeded; on failure the in-app defaults / last cached values stay.
  Future<bool> fetchAndActivate();
  double getDouble(String key, double defaultValue);
  bool getBool(String key, bool defaultValue);
  int getInt(String key, int defaultValue);
  String getString(String key, String defaultValue);
  Map<String, dynamic> getAllValues();

  /// A value the *user* chose in Settings. It wins over the remote value and is
  /// stored on the device only; it is not written to Firebase.
  Future<void> setLocalOverride(String key, dynamic value);
}

class FirebaseRemoteConfigService implements IRemoteConfigService {
  static const _prefPrefix = 'remote_config_override_';

  /// Lab 3 parameters that visibly change behaviour on the Home screen:
  /// - `show_banner` (bool): show/hide the announcement banner
  /// - `max_items` (int): max number of today's sessions listed
  /// plus `portal_announcement` (String): the banner text.
  static const Map<String, dynamic> defaults = {
    'max_items': 10,
    'show_banner': true,
    'portal_announcement':
        'Kỳ Fall 2026: Vui lòng nộp điểm danh trước 23h59 hàng ngày để đồng bộ dữ liệu FAP.',
    'attendance_warn_threshold': 0.15,
    'attendance_ban_threshold': 0.20,
    'enable_ai_assistant': true,
    'max_export_records': 500,
  };

  final Map<String, dynamic> _overrides = {};

  bool get _isFirebaseReady {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  FirebaseRemoteConfig? get _rc => _isFirebaseReady ? FirebaseRemoteConfig.instance : null;

  @override
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in defaults.keys) {
      final name = '$_prefPrefix$key';
      if (prefs.containsKey(name)) {
        final v = prefs.get(name);
        if (v != null) _overrides[key] = v;
      }
    }

    final rc = _rc;
    if (rc == null) {
      FirebaseEvidenceLogger.log(
        service: 'Remote Config',
        action: 'Using in-app defaults (Firebase not initialized)',
        payload: Map<String, dynamic>.from(defaults),
        isSuccess: false,
      );
      return;
    }

    try {
      await rc.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          // Debug: always fetch, so a Console change shows up on the next
          // refresh. Release: cache for 5 minutes to stay under fetch quotas.
          minimumFetchInterval:
              kDebugMode ? Duration.zero : const Duration(minutes: 5),
        ),
      );
      await rc.setDefaults(defaults);
      FirebaseEvidenceLogger.log(
        service: 'Remote Config',
        action: 'Initialized with defaults',
        payload: Map<String, dynamic>.from(defaults),
        isSuccess: true,
      );
    } catch (e) {
      debugPrint('Remote Config init failed: $e');
      FirebaseEvidenceLogger.log(
        service: 'Remote Config',
        action: 'Initialization failed, defaults in effect',
        payload: const {},
        isSuccess: false,
        errorMessage: e.toString(),
      );
    }
  }

  @override
  Future<bool> fetchAndActivate() async {
    final rc = _rc;
    if (rc == null) return false;

    try {
      final activated = await rc.fetchAndActivate();
      FirebaseEvidenceLogger.log(
        service: 'Remote Config',
        action: activated
            ? 'Fetched and activated new values'
            : 'Fetched; values unchanged or served from cache',
        payload: {
          'lastFetchStatus': rc.lastFetchStatus.name,
          ...getAllValues(),
        },
        isSuccess: true,
      );
      return true;
    } catch (e) {
      // Offline / throttled: the SDK keeps the last activated (or default)
      // values, so the app stays usable.
      FirebaseEvidenceLogger.log(
        service: 'Remote Config',
        action: 'Fetch failed, keeping cached/default values',
        payload: getAllValues(),
        isSuccess: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  @override
  double getDouble(String key, double defaultValue) {
    final o = _overrides[key];
    if (o is num) return o.toDouble();
    final rc = _rc;
    if (rc != null && defaults.containsKey(key)) return rc.getDouble(key);
    final d = defaults[key];
    return d is num ? d.toDouble() : defaultValue;
  }

  @override
  bool getBool(String key, bool defaultValue) {
    final o = _overrides[key];
    if (o is bool) return o;
    final rc = _rc;
    if (rc != null && defaults.containsKey(key)) return rc.getBool(key);
    final d = defaults[key];
    return d is bool ? d : defaultValue;
  }

  @override
  int getInt(String key, int defaultValue) {
    final o = _overrides[key];
    if (o is num) return o.toInt();
    final rc = _rc;
    if (rc != null && defaults.containsKey(key)) return rc.getInt(key);
    final d = defaults[key];
    return d is num ? d.toInt() : defaultValue;
  }

  @override
  String getString(String key, String defaultValue) {
    final o = _overrides[key];
    if (o is String) return o;
    final rc = _rc;
    if (rc != null && defaults.containsKey(key)) return rc.getString(key);
    final d = defaults[key];
    return d is String ? d : defaultValue;
  }

  @override
  Map<String, dynamic> getAllValues() {
    return {
      for (final key in defaults.keys)
        key: switch (defaults[key]) {
          bool d => getBool(key, d),
          int d => getInt(key, d),
          double d => getDouble(key, d),
          String d => getString(key, d),
          _ => defaults[key],
        },
    };
  }

  @override
  Future<void> setLocalOverride(String key, dynamic value) async {
    _overrides[key] = value;
    final prefs = await SharedPreferences.getInstance();
    final name = '$_prefPrefix$key';
    if (value is bool) {
      await prefs.setBool(name, value);
    } else if (value is double) {
      await prefs.setDouble(name, value);
    } else if (value is int) {
      await prefs.setInt(name, value);
    } else if (value is String) {
      await prefs.setString(name, value);
    }

    FirebaseEvidenceLogger.log(
      service: 'Remote Config',
      action: 'Local user override saved (device only)',
      payload: {'key': key, 'newValue': value},
    );
  }
}

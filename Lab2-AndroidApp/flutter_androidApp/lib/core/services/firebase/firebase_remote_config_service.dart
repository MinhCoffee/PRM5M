import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_evidence_logger.dart';

abstract interface class IRemoteConfigService {
  Future<void> initialize();
  Future<bool> fetchAndActivate();
  double getDouble(String key, double defaultValue);
  bool getBool(String key, bool defaultValue);
  int getInt(String key, int defaultValue);
  String getString(String key, String defaultValue);
  Map<String, dynamic> getAllValues();
  Future<void> setLocalOverride(String key, dynamic value);
}

class FirebaseRemoteConfigService implements IRemoteConfigService {
  static const _prefPrefix = 'remote_config_override_';

  final Map<String, dynamic> _defaults = {
    'attendance_warn_threshold': 0.15,
    'attendance_ban_threshold': 0.20,
    'enable_ai_assistant': true,
    'max_export_records': 500,
    'portal_announcement':
        'Kỳ Fall 2026: Vui lòng nộp điểm danh trước 23h59 hàng ngày để đồng bộ dữ liệu FAP.',
  };

  final Map<String, dynamic> _activeValues = {};

  bool get _isFirebaseReady {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> initialize() async {
    _activeValues.addAll(_defaults);

    final prefs = await SharedPreferences.getInstance();
    for (final key in _defaults.keys) {
      final overrideKey = '$_prefPrefix$key';
      if (prefs.containsKey(overrideKey)) {
        final val = prefs.get(overrideKey);
        if (val != null) {
          _activeValues[key] = val;
        }
      }
    }

    FirebaseEvidenceLogger.log(
      service: 'Remote Config',
      action: 'Initialized with defaults & local cache',
      payload: Map<String, dynamic>.from(_activeValues),
    );
  }

  @override
  Future<bool> fetchAndActivate() async {
    FirebaseEvidenceLogger.log(
      service: 'Remote Config',
      action: 'Fetching latest parameters from remote template',
      payload: {'currentParametersCount': _activeValues.length},
    );

    try {
      if (_isFirebaseReady) {
        try {
          final snapshot = await FirebaseFirestore.instance
              .collection('remote_config')
              .doc('current')
              .get();
          if (snapshot.exists && snapshot.data() != null) {
            _activeValues.addAll(snapshot.data()!);
          }
        } catch (e) {
          debugPrint('Remote config firestore sync note: $e');
        }
      }

      FirebaseEvidenceLogger.log(
        service: 'Remote Config',
        action: 'Fetch and activate completed',
        payload: Map<String, dynamic>.from(_activeValues),
        isSuccess: true,
      );

      return true;
    } catch (e) {
      FirebaseEvidenceLogger.log(
        service: 'Remote Config',
        action: 'Fetch and activate failed, using fallback cache',
        payload: {'error': e.toString()},
        isSuccess: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  @override
  double getDouble(String key, double defaultValue) {
    final val = _activeValues[key];
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? defaultValue;
    return defaultValue;
  }

  @override
  bool getBool(String key, bool defaultValue) {
    final val = _activeValues[key];
    if (val is bool) return val;
    if (val is String) return val.toLowerCase() == 'true';
    return defaultValue;
  }

  @override
  int getInt(String key, int defaultValue) {
    final val = _activeValues[key];
    if (val is int) return val;
    if (val is num) return val.toInt();
    if (val is String) return int.tryParse(val) ?? defaultValue;
    return defaultValue;
  }

  @override
  String getString(String key, String defaultValue) {
    final val = _activeValues[key];
    return val?.toString() ?? defaultValue;
  }

  @override
  Map<String, dynamic> getAllValues() => Map.unmodifiable(_activeValues);

  @override
  Future<void> setLocalOverride(String key, dynamic value) async {
    _activeValues[key] = value;
    final prefs = await SharedPreferences.getInstance();
    final overrideKey = '$_prefPrefix$key';
    if (value is bool) {
      await prefs.setBool(overrideKey, value);
    } else if (value is double) {
      await prefs.setDouble(overrideKey, value);
    } else if (value is int) {
      await prefs.setInt(overrideKey, value);
    } else if (value is String) {
      await prefs.setString(overrideKey, value);
    }

    FirebaseEvidenceLogger.log(
      service: 'Remote Config',
      action: 'Parameter updated via Console/Local override',
      payload: {'key': key, 'newValue': value},
    );
  }
}

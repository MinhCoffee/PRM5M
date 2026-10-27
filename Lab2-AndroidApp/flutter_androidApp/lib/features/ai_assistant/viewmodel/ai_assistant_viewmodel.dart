import 'package:flutter/foundation.dart';
import '../../../core/models/view_state.dart';
import '../../../core/services/firebase/firebase_analytics_service.dart';
import '../../../core/services/firebase/firebase_crashlytics_service.dart';
import '../../../core/services/firebase/firebase_messaging_service.dart';
import '../../../core/services/firebase/firebase_remote_config_service.dart';
import '../../../models/student.dart';
import '../../../services/attendance_notification_service.dart';
import '../../../services/attendance_stats_service.dart';

class AiAssistantData {
  final List<Student> students;
  final List<String> messages;
  final double warnThreshold;
  final double banThreshold;
  final bool isFeatureEnabled;

  const AiAssistantData({
    required this.students,
    required this.messages,
    required this.warnThreshold,
    required this.banThreshold,
    required this.isFeatureEnabled,
  });
}

class AiAssistantViewModel extends ChangeNotifier {
  final AttendanceStatsService _statsService;
  final AttendanceNotificationService _notificationService;
  final IRemoteConfigService _remoteConfigService;
  final IMessagingService _messagingService;
  final IAnalyticsService _analyticsService;
  final ICrashlyticsService _crashlyticsService;

  ViewState<AiAssistantData> _state = ViewState.initial();
  ViewState<AiAssistantData> get state => _state;

  final List<String> _messages = [];
  String? _selectedStudentId;
  String? get selectedStudentId => _selectedStudentId;

  AiAssistantViewModel({
    required AttendanceStatsService statsService,
    required AttendanceNotificationService notificationService,
    required IRemoteConfigService remoteConfigService,
    required IMessagingService messagingService,
    required IAnalyticsService analyticsService,
    required ICrashlyticsService crashlyticsService,
  })  : _statsService = statsService,
        _notificationService = notificationService,
        _remoteConfigService = remoteConfigService,
        _messagingService = messagingService,
        _analyticsService = analyticsService,
        _crashlyticsService = crashlyticsService;

  Future<void> loadAssistant() async {
    _state = ViewState.loading();
    notifyListeners();

    try {
      await _statsService.load();
      final isEnabled = _remoteConfigService.getBool('enable_ai_assistant', true);

      final missing = _statsService.sessionsMissingAttendance();
      final atRisk = _statsService.studentsByRiskStatus();

      _messages.clear();

      if (missing.isNotEmpty) {
        _messages.add(
          'Nhắc nhở tự động: Có ${missing.length} ca học chưa điểm danh hoặc còn ở trạng thái nháp: ${missing.take(5).map((m) => "${m.session.subjectCode} ${m.session.classCode} (${m.session.sessionDate})").join("; ")}.',
        );
      }

      if (atRisk.isNotEmpty) {
        final banned = atRisk.where((r) => r.status == StudentRiskStatus.banned).length;
        final warning = atRisk.where((r) => r.status == StudentRiskStatus.warning).length;
        _messages.add(
          'Cảnh báo chuyên cần: Phát hiện $banned sinh viên cấm thi và $warning sinh viên cảnh báo vắng.',
        );
      }

      if (missing.isEmpty && atRisk.isEmpty) {
        _messages.add(
          'Quét chuyên cần hoàn tất: Tất cả ca học đã được điểm danh đầy đủ và không có sinh viên vi phạm ngưỡng.',
        );
      }

      // Dispatch local FCM alert if risk is detected
      if (atRisk.isNotEmpty) {
        await _messagingService.sendLocalNotification(
          title: 'Cảnh báo AI Chuyên Cần',
          body: 'Phát hiện sinh viên chạm ngưỡng cảnh báo vắng.',
        );
      }

      final students = [..._statsService.students]
        ..sort((a, b) => a.fullName.compareTo(b.fullName));

      if (students.isNotEmpty) {
        _selectedStudentId ??= students.first.studentId;
      }

      _state = ViewState.data(
        AiAssistantData(
          students: students,
          messages: List.unmodifiable(_messages),
          warnThreshold: _statsService.warnThreshold,
          banThreshold: _statsService.banThreshold,
          isFeatureEnabled: isEnabled,
        ),
      );

      _analyticsService.logScreenView('ai_assistant_screen');
      notifyListeners();
    } catch (e, st) {
      _crashlyticsService.recordError(e, st, reason: 'Failed to load AI Assistant');
      _state = ViewState.error('Không thể khởi động AI Assistant: $e');
      notifyListeners();
    }
  }

  void setSelectedStudent(String? studentId) {
    _selectedStudentId = studentId;
    notifyListeners();
  }

  void queryAtRiskStudents() {
    final rows = _statsService.studentsByRiskStatus();
    final warningRows =
        rows.where((row) => row.status == StudentRiskStatus.warning).toList();
    final bannedRows =
        rows.where((row) => row.status == StudentRiskStatus.banned).toList();

    final text = rows.isEmpty
        ? 'AI quét tất cả các môn: Không có sinh viên nào vượt ngưỡng cảnh báo vắng.'
        : [
            'AI quét toàn trường: Ngưỡng cảnh báo >=${(_statsService.warnThreshold * 100).toStringAsFixed(0)}%, cấm thi >=${(_statsService.banThreshold * 100).toStringAsFixed(0)}%.',
            if (bannedRows.isNotEmpty)
              'Cấm thi: ${bannedRows.take(6).map((r) => "${r.student.studentCode} ${r.student.fullName} (${(r.absenceRate * 100).toStringAsFixed(1)}%)").join("; ")}.',
            if (warningRows.isNotEmpty)
              'Cảnh báo: ${warningRows.take(6).map((r) => "${r.student.studentCode} ${r.student.fullName} (${(r.absenceRate * 100).toStringAsFixed(1)}%)").join("; ")}.',
          ].join(' ');

    _messages.add(text);
    _analyticsService.logEvent('ai_query_at_risk', {'resultsCount': rows.length});
    _updateDataMessages();
  }

  void queryHighestAbsenceSubject() {
    final subjects = _statsService.subjectStats(usePolicyThresholds: true)
      ..sort((a, b) => b.absenceRate.compareTo(a.absenceRate));

    if (subjects.isEmpty) {
      _messages.add('Không có dữ liệu môn học nào để phân tích.');
    } else {
      final top = subjects.first;
      _messages.add(
        'Môn học/lớp có tỷ lệ vắng cao nhất là ${top.subjectCode} - Lớp ${top.classCode} (${(top.absenceRate * 100).toStringAsFixed(1)}% vắng, ${top.absentCount}/${top.recordsCount} lượt vắng).',
      );
    }
    _analyticsService.logEvent('ai_query_highest_subject', {});
    _updateDataMessages();
  }

  void queryStudentHistory() {
    final id = _selectedStudentId;
    if (id == null) return;

    final student = _statsService.students.firstWhere(
      (s) => s.studentId == id,
      orElse: () => Student(
        studentId: id,
        studentName: 'Unknown',
        classId: '',
        email: '',
      ),
    );

    final row = _statsService.studentStatsAcrossAllSubjects(
      student,
      usePolicyThresholds: true,
    );

    final subjects = _statsService.subjectStatsForStudent(
      student,
      usePolicyThresholds: true,
    );

    final subjectDetail = subjects.isEmpty
        ? 'Chưa có lượt điểm danh chi tiết nào.'
        : subjects
            .map((s) =>
                '${s.subjectCode}: vắng ${s.absentCount}/${s.recordsCount} buổi (${(s.absenceRate * 100).toStringAsFixed(1)}%)')
            .join('; ');

    _messages.add(
      'Lịch sử sinh viên ${student.studentCode} - ${student.fullName}: Tổng cộng vắng ${row.absentCount}/${row.sessionsHeld} buổi (${(row.absenceRate * 100).toStringAsFixed(1)}%), trạng thái: ${row.status.value.toUpperCase()}. Chi tiết: $subjectDetail',
    );

    _analyticsService.logEvent('ai_query_student_history', {'studentId': id});
    _updateDataMessages();
  }

  void _updateDataMessages() {
    if (_state.hasData && _state.data != null) {
      final current = _state.data!;
      _state = ViewState.data(
        AiAssistantData(
          students: current.students,
          messages: List.unmodifiable(_messages),
          warnThreshold: current.warnThreshold,
          banThreshold: current.banThreshold,
          isFeatureEnabled: current.isFeatureEnabled,
        ),
      );
      notifyListeners();
    }
  }
}

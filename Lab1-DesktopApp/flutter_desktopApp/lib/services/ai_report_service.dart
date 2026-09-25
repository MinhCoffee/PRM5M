import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/attendance_record.dart';
import '../models/student.dart';

class AIReportService {
  final String? apiKey;
  final String provider;

  AIReportService({this.apiKey, String? provider})
      : provider = provider ?? dotenv.env['AI_PROVIDER'] ?? 'gemini';

  Future<String> generateSummary({
    required List<AttendanceRecord> records,
    required List<Student> students,
    required String classId,
  }) async {
    final key = apiKey ?? dotenv.env['AI_API_KEY'] ?? '';

    // If key is empty or placeholder, generate smart rule-based report directly
    if (key.isEmpty || key.contains('your_api_key')) {
      return _generateLocalSmartReport(records, students, classId);
    }

    try {
      if (provider.toLowerCase() == 'claude') {
        return await _callClaudeAPI(key, records, students, classId);
      } else if (provider.toLowerCase() == 'openai') {
        return await _callOpenAI(key, records, students, classId);
      } else {
        // Default to Gemini API
        return await _callGeminiAPI(key, records, students, classId);
      }
    } catch (e) {
      debugPrint('AI API Call failed ($e). Falling back to smart offline report generator.');
      final fallbackReport = _generateLocalSmartReport(records, students, classId);
      return '$fallbackReport\n\n*(Lưu ý: Báo cáo trên được khởi tạo bởi Bộ phân tích Offline do kết nối AI API bị gián đoạn: $e)*';
    }
  }

  Future<String> _callGeminiAPI(
    String key,
    List<AttendanceRecord> records,
    List<Student> students,
    String classId,
  ) async {
    final prompt = _buildPrompt(records, students, classId);
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$key');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
      if (text != null && text.toString().isNotEmpty) {
        return text.toString();
      }
    }
    throw Exception('Gemini API Error ${response.statusCode}: ${response.body}');
  }

  Future<String> _callClaudeAPI(
    String key,
    List<AttendanceRecord> records,
    List<Student> students,
    String classId,
  ) async {
    final prompt = _buildPrompt(records, students, classId);
    final url = Uri.parse('https://api.anthropic.com/v1/messages');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': key,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': 'claude-3-5-sonnet-20241022',
        'max_tokens': 600,
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['content'][0]['text'] as String;
    }
    throw Exception('Claude API Error ${response.statusCode}: ${response.body}');
  }

  Future<String> _callOpenAI(
    String key,
    List<AttendanceRecord> records,
    List<Student> students,
    String classId,
  ) async {
    final prompt = _buildPrompt(records, students, classId);
    final url = Uri.parse('https://api.openai.com/v1/chat/completions');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $key',
      },
      body: jsonEncode({
        'model': 'gpt-4o-mini',
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
        'max_tokens': 600,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['choices'][0]['message']['content'] as String;
    }
    throw Exception('OpenAI API Error ${response.statusCode}: ${response.body}');
  }

  String _buildPrompt(List<AttendanceRecord> records, List<Student> students, String classId) {
    final dataSummary = _buildDataSummary(records, students);
    return '''
Bạn là trợ lý AI quản lý giảng dạy của trường Đại học.
Dữ liệu điểm danh của lớp $classId ngày ${DateFormat('dd/MM/yyyy').format(DateTime.now())}:

$dataSummary

Hãy viết một BÁO CÁO TÓM TẮT ĐIỂM DANH chuyên nghiệp bằng tiếng Việt (khoảng 150-250 từ) gồm các mục:
1. 📊 TỔNG QUAN ĐIỂM DANH (Sĩ số, số lượng có mặt, vắng mặt, tỷ lệ %).
2. ⚠️ DANH SÁCH SINH VIÊN VẮNG MẶT (Liệt kê MSSV, Họ tên, Ghi chú nếu có).
3. 💡 ĐÁNH GIÁ & KHUYẾN NGHỊ DÀNH CHO GIẢNG VIÊN (Cảnh báo sinh viên có nguy cơ vắng nhiều, đề xuất nhắc nhở/gửi email).
''';
  }

  String _buildDataSummary(List<AttendanceRecord> records, List<Student> students) {
    final buffer = StringBuffer();
    final present = records.where((r) => r.status == 'Present').length;
    final absent = records.where((r) => r.status == 'Absent').length;
    final total = students.length;

    buffer.writeln('Tổng sĩ số lớp: $total');
    buffer.writeln('Có mặt: $present | Vắng mặt: $absent');
    buffer.writeln('Chi tiết:');

    for (final r in records) {
      final student = students.firstWhere(
        (s) => s.studentId == r.studentId,
        orElse: () => Student(studentId: r.studentId, studentName: 'Chưa rõ', classId: r.classId, email: ''),
      );
      final noteStr = r.note.isNotEmpty ? ' (Ghi chú: ${r.note})' : '';
      buffer.writeln('- MSSV: ${student.studentId} | Họ tên: ${student.studentName} | Trạng thái: ${r.status}$noteStr');
    }
    return buffer.toString();
  }

  String _generateLocalSmartReport(
    List<AttendanceRecord> records,
    List<Student> students,
    String classId,
  ) {
    final presentRecords = records.where((r) => r.status == 'Present').toList();
    final absentRecords = records.where((r) => r.status == 'Absent').toList();
    final total = students.length;
    final presentCount = presentRecords.length;
    final absentCount = absentRecords.length;
    final rate = total > 0 ? (presentCount / total * 100).toStringAsFixed(1) : '0';
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    final buffer = StringBuffer();
    buffer.writeln('====================================================');
    buffer.writeln('📋 BÁO CÁO TÓM TẮT ĐIỂM DANH TỰ ĐỘNG (AI ANALYTICS)');
    buffer.writeln('====================================================');
    buffer.writeln('• Lớp học: $classId');
    buffer.writeln('• Thời gian ghi nhận: $dateStr');
    buffer.writeln('');
    buffer.writeln('📊 1. TỔNG QUAN ĐIỂM DANH:');
    buffer.writeln('   - Tổng sĩ số: $total sinh viên');
    buffer.writeln('   - Số lượng có mặt: $presentCount sinh viên');
    buffer.writeln('   - Số lượng vắng mặt: $absentCount sinh viên');
    buffer.writeln('   - Tỷ lệ chuyên cần: $rate%');
    buffer.writeln('');

    if (absentCount == 0) {
      buffer.writeln('🎉 2. TRẠNG THÁI LỚP HỌC:');
      buffer.writeln('   Tuyệt vời! Lớp $classId đạt sĩ số 100% có mặt trong buổi học này.');
    } else {
      buffer.writeln('⚠️ 2. DANH SÁCH SINH VIÊN VẮNG MẶT:');
      var index = 1;
      for (final r in absentRecords) {
        final student = students.firstWhere(
          (s) => s.studentId == r.studentId,
          orElse: () => Student(studentId: r.studentId, studentName: 'N/A', classId: classId, email: ''),
        );
        final noteText = r.note.isNotEmpty ? ' [Ghi chú: ${r.note}]' : '';
        final emailText = student.email.isNotEmpty ? ' <${student.email}>' : '';
        buffer.writeln('   $index. [${student.studentId}] ${student.studentName}$emailText$noteText');
        index++;
      }
    }

    buffer.writeln('');
    buffer.writeln('💡 3. KHUYẾN NGHỊ HỆ THỐNG:');
    if (absentCount > 0) {
      buffer.writeln('   - Đề nghị phòng Cố vấn Học tập gửi email nhắc nhở cho $absentCount sinh viên vắng mặt.');
      buffer.writeln('   - Kiểm tra lý do nghỉ học và yêu cầu sinh viên nộp đơn xin phép (nếu có).');
    }
    if (double.tryParse(rate) != null && double.parse(rate) < 80) {
      buffer.writeln('   - 🚨 CẢNH BÁO: Tỷ lệ đi học của lớp ở mức thấp ($rate%). Cần rà soát tình hình học tập.');
    } else {
      buffer.writeln('   - Duy trì ổn định kỷ luật và tiến độ bài giảng.');
    }
    buffer.writeln('====================================================');

    return buffer.toString();
  }
}

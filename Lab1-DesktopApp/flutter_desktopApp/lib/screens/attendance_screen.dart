import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import '../models/attendance_record.dart';
import '../models/student.dart';
import '../services/ai_report_service.dart';
import '../services/google_sheet_service.dart';
import 'report_screen.dart';

class AttendanceScreen extends StatefulWidget {
  final List<Student> students;
  final String classId;
  final GoogleSheetService sheetService;

  const AttendanceScreen({
    super.key,
    required this.students,
    required this.classId,
    required this.sheetService,
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  late Map<String, String> _statusMap;
  late Map<String, String> _noteMap;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  DateTime _sessionDate = DateTime.now();
  String _sessionLabel = 'Buổi học chính';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _statusMap = {for (final s in widget.students) s.studentId: 'Present'};
    _noteMap = {for (final s in widget.students) s.studentId: ''};
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _markAll(bool present) {
    setState(() {
      final status = present ? 'Present' : 'Absent';
      for (final s in widget.students) {
        _statusMap[s.studentId] = status;
      }
    });
  }

  void _setStatus(String studentId, String status) {
    setState(() => _statusMap[studentId] = status);
  }

  Future<void> _pickSessionDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: _sessionDate,
    );
    if (selectedDate != null && mounted) {
      setState(() => _sessionDate = selectedDate);
    }
  }

  Future<void> _saveAndGenerateReport() async {
    final shouldSave = await _confirmSave();
    if (!shouldSave || !mounted) return;

    setState(() => _saving = true);
    final sessionId = 'SESSION_${DateTime.now().millisecondsSinceEpoch}';
    final records = widget.students.map((s) {
      return AttendanceRecord(
        sessionId: sessionId,
        date: _sessionDate,
        classId: widget.classId,
        studentId: s.studentId,
        status: _statusMap[s.studentId] ?? 'Present',
        note: _noteMap[s.studentId]!.isEmpty ? _sessionLabel : _noteMap[s.studentId]!,
      );
    }).toList();

    try {
      // 1. Save to Google Sheets / Local database
      await widget.sheetService.saveAttendance(records);

      // 2. Generate AI report summary
      final apiKey = dotenv.env['AI_API_KEY'] ?? '';
      final provider = dotenv.env['AI_PROVIDER'] ?? 'gemini';
      final aiService = AIReportService(apiKey: apiKey, provider: provider);

      final reportText = await aiService.generateSummary(
        records: records,
        students: widget.students,
        classId: widget.classId,
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ReportScreen(
            reportText: reportText,
            classId: widget.classId,
            records: records,
            students: widget.students,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Lỗi: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool> _confirmSave() async {
    final absentCount = _statusMap.values.where((status) => status == 'Absent').length;
    final excusedCount = _statusMap.values.where((status) => status == 'Excused').length;
    final lateCount = _statusMap.values.where((status) => status == 'Late').length;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Xác nhận chốt buổi điểm danh'),
            content: Text(
              'Lớp ${widget.classId}\n'
              'Ngày ${DateFormat('dd/MM/yyyy').format(_sessionDate)} · $_sessionLabel\n\n'
              'Có mặt: ${widget.students.length - absentCount - excusedCount - lateCount}\n'
              'Vắng: $absentCount · Có phép: $excusedCount · Đi muộn: $lateCount\n\n'
              'Sau khi lưu, dữ liệu sẽ được ghi vào Google Sheets.',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Kiểm tra lại')),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Chốt & lưu')),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final filteredStudents = widget.students.where((s) {
      final q = _searchQuery.toLowerCase();
      return s.studentName.toLowerCase().contains(q) ||
          s.studentId.toLowerCase().contains(q) ||
          s.email.toLowerCase().contains(q);
    }).toList();

    final presentCount = _statusMap.values.where((status) => status == 'Present').length;
    final absentCount = _statusMap.values.where((status) => status == 'Absent').length;
    final excusedCount = _statusMap.values.where((status) => status == 'Excused').length;
    final lateCount = _statusMap.values.where((status) => status == 'Late').length;
    final dateStr = DateFormat('dd/MM/yyyy').format(_sessionDate);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bảng điểm danh lớp ${widget.classId}'),
            Text(
              'Ngày $dateStr | Sĩ số: ${widget.students.length}',
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8)),
            ),

          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Chọn tất cả có mặt',
            icon: const Icon(Icons.done_all, color: Colors.green),
            onPressed: () => _markAll(true),
          ),
          IconButton(
            tooltip: 'Chọn tất cả vắng',
            icon: const Icon(Icons.remove_done, color: Colors.red),
            onPressed: () => _markAll(false),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Header Bar & Search Controls
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),

            child: Column(
              children: [
                Row(
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(dateStr),
                      onPressed: _pickSessionDate,
                    ),
                    const SizedBox(width: 12),
                    DropdownButton<String>(
                      value: _sessionLabel,
                      underline: const SizedBox.shrink(),
                      items: const [
                        DropdownMenuItem(value: 'Buổi học chính', child: Text('Buổi học chính')),
                        DropdownMenuItem(value: 'Buổi sáng', child: Text('Buổi sáng')),
                        DropdownMenuItem(value: 'Buổi chiều', child: Text('Buổi chiều')),
                        DropdownMenuItem(value: 'Buổi tối', child: Text('Buổi tối')),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _sessionLabel = value);
                      },
                    ),
                    const Spacer(),
                    _buildStatBadge('Có mặt', '$presentCount', Colors.green),
                    const SizedBox(width: 8),
                    _buildStatBadge('Đi muộn', '$lateCount', Colors.orange),
                    const SizedBox(width: 8),
                    _buildStatBadge('Có phép', '$excusedCount', Colors.blue),
                    const SizedBox(width: 8),
                    _buildStatBadge('Vắng', '$absentCount', Colors.red),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm theo họ tên, MSSV hoặc email...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ],
            ),
          ),
          // Student List / Table
          Expanded(
            child: filteredStudents.isEmpty
                ? const Center(child: Text('Không tìm thấy sinh viên tương ứng.'))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filteredStudents.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final student = filteredStudents[index];
                      final status = _statusMap[student.studentId] ?? 'Present';
                      final isPresent = status == 'Present';

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isPresent ? Colors.green.shade100 : Colors.red.shade100,
                          child: Text(
                            student.studentName.isNotEmpty ? student.studentName[0].toUpperCase() : '?',
                            style: TextStyle(
                              color: isPresent ? Colors.green.shade900 : Colors.red.shade900,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              student.studentName,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blueGrey.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                student.studentId,
                                style: const TextStyle(fontSize: 12, color: Colors.black87),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          student.email.isNotEmpty ? student.email : 'Không có email',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                          trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 180,
                              child: TextField(
                                decoration: const InputDecoration(
                                  hintText: 'Ghi chú...',
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (val) => _noteMap[student.studentId] = val,
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 135,
                              child: DropdownButtonFormField<String>(
                                initialValue: status,
                                isDense: true,
                                decoration: const InputDecoration(
                                  labelText: 'Trạng thái',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'Present', child: Text('Có mặt')),
                                  DropdownMenuItem(value: 'Late', child: Text('Đi muộn')),
                                  DropdownMenuItem(value: 'Excused', child: Text('Có phép')),
                                  DropdownMenuItem(value: 'Absent', child: Text('Vắng')),
                                ],
                                onChanged: (value) {
                                  if (value != null) _setStatus(student.studentId, value);
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          // Bottom Bar Action
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),

                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Quay lại'),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _saving ? null : _saveAndGenerateReport,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: Text(
                    _saving ? 'Đang lưu & Tổng hợp AI...' : 'Lưu & Tạo Báo Cáo AI',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.bold),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

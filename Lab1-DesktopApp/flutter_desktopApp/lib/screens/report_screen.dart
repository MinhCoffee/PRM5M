import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/attendance_record.dart';
import '../models/student.dart';
import '../services/file_service.dart';

class ReportScreen extends StatefulWidget {
  final String reportText;
  final String classId;
  final List<AttendanceRecord>? records;
  final List<Student>? students;

  const ReportScreen({
    super.key,
    required this.reportText,
    required this.classId,
    this.records,
    this.students,
  });

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final FileService _fileService = FileService();
  bool _exporting = false;

  Future<void> _exportReport() async {
    setState(() => _exporting = true);
    try {
      final path = await _fileService.exportReportToFile(widget.reportText, widget.classId);
      if (!mounted) return;
      if (path != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 Đã xuất file báo cáo thành công tại: $path'),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Lỗi xuất file: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _exportCsv() async {
    if (widget.records == null || widget.students == null) return;
    setState(() => _exporting = true);
    try {
      final path = await _fileService.exportAttendanceToCsv(
        widget.records!,
        widget.students!,
        widget.classId,
      );
      if (!mounted) return;
      if (path != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 Đã xuất CSV bảng điểm danh tại: $path'),
            backgroundColor: Colors.blue.shade700,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Lỗi xuất CSV: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.reportText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📋 Đã sao chép báo cáo vào bộ nhớ tạm!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Báo Cáo Tổng Hợp Điểm Danh (AI) - ${widget.classId}'),
        actions: [
          IconButton(
            tooltip: 'Sao chép nội dung',
            icon: const Icon(Icons.copy),
            onPressed: _copyToClipboard,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: SelectionArea(
                    child: SingleChildScrollView(
                      child: Text(
                        widget.reportText,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                  icon: const Icon(Icons.home),
                  label: const Text('Màn hình chính'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                ),
                const Spacer(),
                if (widget.records != null && widget.students != null) ...[
                  OutlinedButton.icon(
                    onPressed: _exporting ? null : _exportCsv,
                    icon: const Icon(Icons.table_chart, color: Colors.blue),
                    label: const Text('Xuất CSV Điểm Danh'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                FilledButton.icon(
                  onPressed: _exporting ? null : _exportReport,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: _exporting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save_alt),
                  label: Text(_exporting ? 'Đang xuất...' : 'Xuất Báo Cáo ra File (.txt)'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

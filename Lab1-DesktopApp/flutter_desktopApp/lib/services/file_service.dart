import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as excel_lib;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../models/attendance_record.dart';
import '../models/student.dart';

class FileService {
  /// Import student list from CSV file
  Future<List<Student>> importStudentsFromCsv(String classId, [String? filePath]) async {
    try {
      String? path = filePath;
      if (path == null) {
        final result = await FilePicker.platform.pickFiles(
          dialogTitle: 'Chọn file CSV danh sách sinh viên',
          type: FileType.custom,
          allowedExtensions: ['csv'],
        );
        if (result == null || result.files.single.path == null) return [];
        path = result.files.single.path!;
      }

      final file = File(path);
      final content = await file.readAsString();
      final rows = const CsvToListConverter().convert(content);

      final students = <Student>[];
      for (var i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.isEmpty || row.length < 2) continue;
        final studentId = row[0].toString().trim();
        final studentName = row[1].toString().trim();
        final email = row.length > 2 ? row[2].toString().trim() : '';
        final parsedClassId = row.length > 3 && row[3].toString().trim().isNotEmpty
            ? row[3].toString().trim()
            : classId;

        if (studentId.isNotEmpty && studentName.isNotEmpty) {
          students.add(Student(
            studentId: studentId,
            studentName: studentName,
            classId: parsedClassId,
            email: email,
          ));
        }
      }
      return students;
    } catch (e) {
      debugPrint('Error importing CSV: $e');
      rethrow;
    }
  }

  /// Import student list from Excel (.xlsx) file (FAP export)
  Future<List<Student>> importStudentsFromExcel(String classId, [String? filePath]) async {
    try {
      String? path = filePath;
      if (path == null) {
        final result = await FilePicker.platform.pickFiles(
          dialogTitle: 'Chọn file Excel FAP (.xlsx) danh sách sinh viên',
          type: FileType.custom,
          allowedExtensions: ['xlsx'],
        );
        if (result == null || result.files.single.path == null) return [];
        path = result.files.single.path!;
      }

      final bytes = File(path).readAsBytesSync();
      final excelFile = excel_lib.Excel.decodeBytes(bytes);
      if (excelFile.tables.isEmpty) return [];

      final sheetName = excelFile.tables.keys.first;
      final sheet = excelFile.tables[sheetName]!;

      final students = <Student>[];
      // Skip row 0 (Header)
      for (var i = 1; i < sheet.maxRows; i++) {
        final row = sheet.row(i);
        if (row.isEmpty) continue;

        final studentId = row[0]?.value?.toString().trim() ?? '';
        final studentName = row[1]?.value?.toString().trim() ?? '';
        final email = row.length > 2 ? (row[2]?.value?.toString().trim() ?? '') : '';
        final parsedClassId = row.length > 3 && (row[3]?.value?.toString().trim().isNotEmpty ?? false)
            ? row[3]!.value!.toString().trim()
            : classId;

        if (studentId.isNotEmpty && studentName.isNotEmpty) {
          students.add(Student(
            studentId: studentId,
            studentName: studentName,
            classId: parsedClassId,
            email: email,
          ));
        }
      }
      return students;
    } catch (e) {
      debugPrint('Error importing Excel: $e');
      rethrow;
    }
  }

  /// Export AI report to local file with file picker dialog
  Future<String?> exportReportToFile(String reportText, String classId) async {
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final defaultFileName = 'BaoCao_DiemDanh_${classId}_$timestamp.txt';

    try {
      final outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Lưu báo cáo điểm danh AI',
        fileName: defaultFileName,
        type: FileType.custom,
        allowedExtensions: ['txt', 'md'],
      );

      if (outputPath == null) return null;

      final file = File(outputPath);
      await file.writeAsString(reportText);
      return outputPath;
    } catch (e) {
      // Fallback: save to Documents folder automatically if GUI picker is cancelled or throws
      return await exportReportToDocuments(reportText, classId);
    }
  }

  /// Backup/fallback export method to Documents directory
  Future<String> exportReportToDocuments(String reportText, String classId) async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'BaoCao_DiemDanh_${classId}_$timestamp.txt';
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(reportText);
    return file.path;
  }

  /// Export raw attendance records to CSV file
  Future<String?> exportAttendanceToCsv(
    List<AttendanceRecord> records,
    List<Student> students,
    String classId,
  ) async {
    final studentMap = {for (final s in students) s.studentId: s.studentName};

    final List<List<dynamic>> rows = [
      ['SessionID', 'Date', 'ClassID', 'StudentID', 'StudentName', 'Status', 'Note'],
    ];

    for (final r in records) {
      rows.add([
        r.sessionId,
        DateFormat('yyyy-MM-dd HH:mm').format(r.date),
        r.classId,
        r.studentId,
        studentMap[r.studentId] ?? 'N/A',
        r.status,
        r.note,
      ]);
    }

    final csvContent = const ListToCsvConverter().convert(rows);
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final defaultFileName = 'DiemDanh_${classId}_$timestamp.csv';

    final outputPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Lưu bảng điểm danh CSV',
      fileName: defaultFileName,
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (outputPath == null) return null;

    final file = File(outputPath);
    await file.writeAsString(csvContent);
    return outputPath;
  }
}

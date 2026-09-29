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
  Future<List<Student>> importStudentsFromCsv(
    String classId, [
    String? filePath,
  ]) async {
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
      final rows = const CsvToListConverter(shouldParseNumbers: false)
          .convert(content);
      return _studentsFromRows(rows, classId);
    } catch (e) {
      debugPrint('Error importing CSV: $e');
      rethrow;
    }
  }

  /// Import student list from Excel (.xlsx) file (FAP export)
  Future<List<Student>> importStudentsFromExcel(
    String classId, [
    String? filePath,
  ]) async {
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
      final rows = List<List<dynamic>>.generate(sheet.maxRows, (rowIndex) {
        return sheet
            .row(rowIndex)
            .map((cell) => cell?.value?.toString() ?? '')
            .toList();
      });
      return _studentsFromRows(rows, classId);
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
  Future<String> exportReportToDocuments(
    String reportText,
    String classId,
  ) async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'BaoCao_DiemDanh_${classId}_$timestamp.txt';
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(reportText);
    return file.path;
  }

  Future<String?> exportCsvRows({
    required String dialogTitle,
    required String fileName,
    required List<List<dynamic>> rows,
  }) async {
    final csvContent = const ListToCsvConverter().convert(rows);
    try {
      final outputPath = await FilePicker.platform.saveFile(
        dialogTitle: dialogTitle,
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (outputPath == null) return null;

      final file = File(outputPath);
      await file.writeAsString(csvContent);
      return outputPath;
    } catch (e) {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}${Platform.pathSeparator}$fileName');
      await file.writeAsString(csvContent);
      return file.path;
    }
  }

  /// Export raw attendance records to CSV file
  Future<String?> exportAttendanceToCsv(
    List<AttendanceRecord> records,
    List<Student> students,
    String classId,
  ) async {
    final studentMap = {for (final s in students) s.studentId: s.studentName};

    final List<List<dynamic>> rows = [
      [
        'SessionID',
        'Date',
        'ClassID',
        'StudentID',
        'StudentName',
        'Status',
        'Note',
      ],
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

  List<Student> _studentsFromRows(
    List<List<dynamic>> rows,
    String fallbackClassId,
  ) {
    final nonEmptyRows = rows
        .where((row) => row.any((cell) => _cell(cell).isNotEmpty))
        .toList();
    if (nonEmptyRows.isEmpty) return [];

    final headers = nonEmptyRows.first.map(_headerKey).toList();
    final hasHeader = headers.any(_knownStudentHeader);
    final dataRows = hasHeader ? nonEmptyRows.skip(1) : nonEmptyRows;
    final seenIds = <String>{};
    final students = <Student>[];

    for (final row in dataRows) {
      final studentId = hasHeader
          ? _valueFor(row, headers, const ['studentid', 'id'])
          : _valueAt(row, 0);
      final studentCode = hasHeader
          ? _valueFor(row, headers, const [
              'studentcode',
              'rollnumber',
              'rollno',
              'roll',
            ])
          : studentId;
      final studentName = hasHeader
          ? _valueFor(row, headers, const ['fullname', 'studentname', 'name'])
          : _valueAt(row, 1);
      final email = hasHeader
          ? _valueFor(row, headers, const ['email', 'mail'])
          : _valueAt(row, 2);
      final parsedClassId = hasHeader
          ? _valueFor(row, headers, const ['classcode', 'classid', 'class'])
          : _valueAt(row, 3);
      final gender = hasHeader
          ? _valueFor(row, headers, const ['gender', 'sex'])
          : _valueAt(row, 4);
      final major = hasHeader
          ? _valueFor(row, headers, const ['major'])
          : _valueAt(row, 5);
      final photoUrl = hasHeader
          ? _valueFor(row, headers, const ['photourl', 'photo'])
          : _valueAt(row, 6);

      final resolvedId = studentId.isNotEmpty ? studentId : studentCode;
      final resolvedCode = studentCode.isNotEmpty ? studentCode : resolvedId;
      final resolvedClass = parsedClassId.isNotEmpty
          ? parsedClassId
          : fallbackClassId;
      final dedupeKey = resolvedId.toUpperCase();

      if (resolvedId.isEmpty ||
          studentName.isEmpty ||
          resolvedClass.isEmpty ||
          seenIds.contains(dedupeKey))
        continue;
      seenIds.add(dedupeKey);
      students.add(
        Student(
          studentId: resolvedId,
          studentCode: resolvedCode,
          studentName: studentName,
          classId: resolvedClass,
          email: email,
          gender: gender,
          major: major,
          photoUrl: photoUrl,
        ),
      );
    }

    return students;
  }

  bool _knownStudentHeader(String value) => const {
    'studentid',
    'studentcode',
    'rollnumber',
    'rollno',
    'fullname',
    'studentname',
    'classcode',
    'classid',
  }.contains(value);

  String _valueFor(List<dynamic> row, List<String> headers, List<String> keys) {
    for (final key in keys) {
      final index = headers.indexOf(key);
      if (index >= 0) return _valueAt(row, index);
    }
    return '';
  }

  String _valueAt(List<dynamic> row, int index) {
    if (index < 0 || index >= row.length) return '';
    return _cell(row[index]);
  }

  String _cell(Object? value) => value?.toString().trim() ?? '';

  String _headerKey(Object? value) =>
      _cell(value).toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
}

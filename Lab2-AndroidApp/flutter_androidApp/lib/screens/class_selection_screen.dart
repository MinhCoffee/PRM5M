import 'package:flutter/material.dart';
import '../models/student.dart';
import '../services/file_service.dart';
import '../services/google_sheet_service.dart';
import 'attendance_screen.dart';

class ClassSelectionScreen extends StatefulWidget {
  final GoogleSheetService sheetService;

  const ClassSelectionScreen({super.key, required this.sheetService});

  @override
  State<ClassSelectionScreen> createState() => _ClassSelectionScreenState();
}

class _ClassSelectionScreenState extends State<ClassSelectionScreen> {
  final _classIdController = TextEditingController(text: 'SE1801');
  final _fileService = FileService();
  bool _loading = false;
  String? _errorMessage;
  List<Student> _allStudentsCache = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _loading = true);
    try {
      await widget.sheetService.init();
      final students = await widget.sheetService.getAllStudents();
      setState(() {
        _allStudentsCache = students;
      });
    } catch (e) {
      debugPrint('Error loading initial class data: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _startAttendance([String? customClassId]) async {
    final classId = (customClassId ?? _classIdController.text).trim().toUpperCase();
    if (classId.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập Mã lớp học (Class ID)');
      return;
    }
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      var students = await widget.sheetService.getStudentsByClass(classId);

      if (students.isEmpty) {
        // If not found in Google Sheet, check local cache or prompt user
        students = _allStudentsCache.where((s) => s.classId.toUpperCase() == classId).toList();
      }

      if (students.isEmpty) {
        setState(() => _errorMessage =
            'Chưa có dữ liệu sinh viên cho lớp "$classId". Hãy import danh sách từ file FAP Excel hoặc CSV!');
        return;
      }

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AttendanceScreen(
            students: students,
            classId: classId,
            sheetService: widget.sheetService,
          ),
        ),
      );
    } catch (e) {
      setState(() => _errorMessage = 'Lỗi truy vấn dữ liệu lớp học: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _importFromExcel() async {
    final classId = _classIdController.text.trim().toUpperCase();
    if (classId.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập Class ID trước khi import');
      return;
    }

    try {
      final students = await _fileService.importStudentsFromExcel(classId);
      if (students.isEmpty) return;

      await widget.sheetService.appendStudents(students);
      await _loadInitialData();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 Đã import thành công ${students.length} sinh viên cho lớp $classId!'),
          backgroundColor: Colors.green.shade700,
        ),
      );
      _startAttendance(classId);
    } catch (e) {
      setState(() => _errorMessage = 'Lỗi import Excel: $e');
    }
  }

  Future<void> _importFromCsv() async {
    final classId = _classIdController.text.trim().toUpperCase();
    if (classId.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập Class ID trước khi import');
      return;
    }

    try {
      final students = await _fileService.importStudentsFromCsv(classId);
      if (students.isEmpty) return;

      await widget.sheetService.appendStudents(students);
      await _loadInitialData();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 Đã import thành công ${students.length} sinh viên cho lớp $classId!'),
          backgroundColor: Colors.green.shade700,
        ),
      );
      _startAttendance(classId);
    } catch (e) {
      setState(() => _errorMessage = 'Lỗi import CSV: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableClasses = _allStudentsCache.map((s) => s.classId.toUpperCase()).toSet().toList();
    if (!availableClasses.contains('SE1801')) availableClasses.add('SE1801');
    if (!availableClasses.contains('SE1802')) availableClasses.add('SE1802');

    final isLive = widget.sheetService.isLive;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.how_to_reg,
                            size: 32,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Điểm Danh Sinh Viên',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isLive ? Colors.green : Colors.orange,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isLive ? 'Google Sheets Live' : 'Local Cache Mode',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isLive ? Colors.green.shade700 : Colors.orange.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    TextField(
                      controller: _classIdController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: 'Mã lớp học (Class ID)',
                        hintText: 'Ví dụ: SE1801',
                        prefixIcon: const Icon(Icons.class_outlined),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => _classIdController.clear(),
                        ),
                      ),
                      onSubmitted: (_) => _startAttendance(),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        const Text(
                          'Lớp có sẵn: ',
                          style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                        ),
                        for (final cls in availableClasses)
                          ActionChip(
                            label: Text(cls),
                            onPressed: () {
                              _classIdController.text = cls;
                              _startAttendance(cls);
                            },
                          ),
                      ],
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: Colors.red.shade900, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _loading ? null : () => _startAttendance(),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.play_arrow),
                      label: Text(
                        _loading ? 'Đang tải dữ liệu...' : 'Bắt đầu điểm danh',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('HOẶC IMPORT FILE', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _importFromExcel,
                            icon: const Icon(Icons.table_view, color: Colors.green),
                            label: const Text('Excel FAP (.xlsx)'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _importFromCsv,
                            icon: const Icon(Icons.insert_drive_file, color: Colors.blue),
                            label: const Text('File CSV'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

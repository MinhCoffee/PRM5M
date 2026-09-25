import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/google_sheet_service.dart';

class SettingsScreen extends StatefulWidget {
  final GoogleSheetService sheetService;

  const SettingsScreen({super.key, required this.sheetService});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _spreadsheetIdController;
  late TextEditingController _aiApiKeyController;
  late String _selectedProvider;
  bool _testingConnection = false;
  String? _statusMessage;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    String readEnv(String key) {
      try {
        return dotenv.env[key] ?? '';
      } on NotInitializedError {
        return '';
      }
    }

    _spreadsheetIdController = TextEditingController(
      text: readEnv('SPREADSHEET_ID'),
    );
    _aiApiKeyController = TextEditingController(
      text: readEnv('AI_API_KEY'),
    );
    _selectedProvider = readEnv('AI_PROVIDER').isEmpty ? 'gemini' : readEnv('AI_PROVIDER');
  }

  @override
  void dispose() {
    _spreadsheetIdController.dispose();
    _aiApiKeyController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() {
      _testingConnection = true;
      _statusMessage = null;
    });

    final spreadsheetId = _spreadsheetIdController.text.trim();
    dotenv.env['SPREADSHEET_ID'] = spreadsheetId;
    dotenv.env['AI_API_KEY'] = _aiApiKeyController.text.trim();
    dotenv.env['AI_PROVIDER'] = _selectedProvider;

    final service = GoogleSheetService(spreadsheetId);
    final connected = await service.init();

    if (!mounted) return;
    setState(() {
      _testingConnection = false;
      _isSuccess = connected;
      _statusMessage = connected
          ? '✅ Kết nối Google Sheets thành công!'
          : (service.lastError ?? '⚠️ Không thể kết nối với Google Sheets. Chuyển sang Local Cache Mode.');
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cấu hình Hệ thống & Database'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.table_chart, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 12),
                            Text(
                              'Cấu hình Google Sheets',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        const Text(
                          'Nhập Spreadsheet ID từ URL Google Sheet của bạn:\n'
                          'https://docs.google.com/spreadsheets/d/[SPREADSHEET_ID]/edit',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _spreadsheetIdController,
                          decoration: const InputDecoration(
                            labelText: 'Spreadsheet ID',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.link),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.psychology, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 12),
                            Text(
                              'Cấu hình AI API Key',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedProvider,
                          decoration: const InputDecoration(

                            labelText: 'Nhà cung cấp AI',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.smart_toy),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'gemini', child: Text('Google Gemini (Khuyên dùng)')),
                            DropdownMenuItem(value: 'claude', child: Text('Anthropic Claude')),
                            DropdownMenuItem(value: 'openai', child: Text('OpenAI GPT')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedProvider = val);
                          },
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _aiApiKeyController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'AI API Key',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.key),
                            helperText: 'Nếu trống, ứng dụng sẽ dùng bộ tạo báo cáo quy tắc thông minh Offline.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_statusMessage != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _isSuccess
                          ? (isDark ? Colors.green.shade900 : Colors.green.shade50)
                          : (isDark ? Colors.orange.shade900 : Colors.orange.shade50),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isSuccess ? Colors.green : Colors.orange,
                      ),
                    ),
                    child: Text(
                      _statusMessage!,
                      style: TextStyle(
                        color: _isSuccess
                            ? (isDark ? Colors.green.shade100 : Colors.green.shade900)
                            : (isDark ? Colors.orange.shade100 : Colors.orange.shade900),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _testingConnection ? null : _testConnection,
                  icon: _testingConnection
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      _testingConnection ? 'Đang kiểm tra kết nối...' : 'Lưu cấu hình & Kiểm tra kết nối',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

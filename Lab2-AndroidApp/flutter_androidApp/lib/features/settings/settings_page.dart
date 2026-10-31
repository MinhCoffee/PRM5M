import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/state_view.dart';
import 'viewmodel/settings_viewmodel.dart';

class SettingsPage extends StatefulWidget {
  final SettingsViewModel viewModel;

  const SettingsPage({super.key, required this.viewModel});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _warnController = TextEditingController();
  final _banController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.viewModel.loadSettings().then((_) {
        final data = widget.viewModel.state.data;
        if (data != null) {
          _warnController.text = (data.warnThreshold * 100).toStringAsFixed(1);
          _banController.text = (data.banThreshold * 100).toStringAsFixed(1);
        }
      });
    });
  }

  @override
  void dispose() {
    _warnController.dispose();
    _banController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final warn = double.tryParse(_warnController.text.trim());
    final ban = double.tryParse(_banController.text.trim());

    if (warn == null || ban == null || warn >= ban || warn < 0 || ban > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ngưỡng cảnh báo phải nhỏ hơn ngưỡng cấm thi và nằm trong khoảng 0-100%.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    try {
      await widget.viewModel.saveThresholds(
        warn: warn / 100.0,
        ban: ban / 100.0,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật ngưỡng chuyên cần & đồng bộ Remote Config!'),
            backgroundColor: AppColors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi lưu cài đặt: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleSeed() async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Tạo lại dữ liệu mẫu (Seed Data)'),
            content: const Text(
              'Hành động này sẽ xóa dữ liệu cũ và sinh ngẫu nhiên lại danh sách sinh viên, ca học và điểm danh.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Tiến hành'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed || !mounted) return;

    try {
      final summary = await widget.viewModel.seedSampleData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã tạo thành công ${summary.subjectCount} môn, ${summary.classCount} lớp, ${summary.studentsAdded} sinh viên!',
            ),
            backgroundColor: AppColors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tạo dữ liệu mẫu: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        return StateView<SettingsData>(
          state: widget.viewModel.state,
          loadingMessage: 'Đang tải cài đặt hệ thống...',
          onRetry: () => widget.viewModel.loadSettings(),
          onData: (context, data) => _buildContent(context, data),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, SettingsData data) {
    final isSaving = widget.viewModel.isSaving;
    final isSeeding = widget.viewModel.isSeeding;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('Cài đặt hệ thống',
                style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 4),
            Text(
              'Điều chỉnh ngưỡng vắng chuyên cần, cấu hình Firebase Remote Config và công cụ kiểm thử.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),

            // Attendance Thresholds & Remote Config Live Parameters
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.tune, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Ngưỡng cảnh báo chuyên cần (Remote Config)',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Các giá trị này được đồng bộ từ Firebase Remote Config và áp dụng trên tất cả màn hình: Trang chủ, Lớp học, Điểm danh, Báo cáo và Trợ lý AI.',
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _warnController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Ngưỡng cảnh báo Warning (%)',
                              hintText: '15.0',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _banController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Ngưỡng cấm thi Banned (%)',
                              hintText: '20.0',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilledButton.icon(
                          onPressed: isSaving ? null : _handleSave,
                          icon: isSaving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(isSaving ? 'Đang lưu...' : 'Lưu cài đặt'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Sample Data Generation
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.science_outlined,
                            color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Tạo dữ liệu mẫu (Seed Data Generator)',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tự động sinh tập dữ liệu sinh viên, thời khóa biểu và ca học phục vụ kiểm thử bài Lab.',
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: isSeeding ? null : _handleSeed,
                      icon: isSeeding
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Icon(Icons.refresh),
                      label: Text(
                        isSeeding ? 'Đang tạo...' : 'Tạo lại toàn bộ dữ liệu mẫu',
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Diagnostic & Crashlytics Verification Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.bug_report_outlined,
                            color: AppColors.error),
                        const SizedBox(width: 8),
                        Text(
                          'Kiểm thử Crashlytics (Bằng chứng Lab)',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Kích hoạt một sự kiện ngoại lệ thử nghiệm để kiểm tra tính năng ghi nhận lỗi trên Firebase Console Crashlytics.',
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            widget.viewModel.triggerTestCrash();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Đã ném thử ngoại lệ Fatal Crash vào Firebase Crashlytics!',
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.warning_amber_rounded),
                          label: const Text('Ném thử lỗi (Test Crash)'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.errorText,
                          ),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: () async {
                            await widget.viewModel.triggerTestNonFatalError();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Đã gửi một Non-fatal Error lên Firebase Crashlytics thành công!',
                                  ),
                                  backgroundColor: AppColors.primary,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.report_problem_outlined),
                          label: const Text('Gửi Non-fatal Error'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

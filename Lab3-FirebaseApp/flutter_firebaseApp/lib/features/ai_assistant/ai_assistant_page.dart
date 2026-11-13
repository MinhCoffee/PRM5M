import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/state_view.dart';
import 'viewmodel/ai_assistant_viewmodel.dart';

class AiAssistantPage extends StatefulWidget {
  final AiAssistantViewModel viewModel;

  const AiAssistantPage({super.key, required this.viewModel});

  @override
  State<AiAssistantPage> createState() => _AiAssistantPageState();
}

class _AiAssistantPageState extends State<AiAssistantPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.viewModel.loadAssistant();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        return StateView<AiAssistantData>(
          state: widget.viewModel.state,
          loadingMessage: 'AI đang phân tích dữ liệu chuyên cần...',
          onRetry: () => widget.viewModel.loadAssistant(),
          onData: (context, data) => _buildContent(context, data),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, AiAssistantData data) {
    final narrow = MediaQuery.sizeOf(context).width < 700;

    return ListView(
      padding: EdgeInsets.all(narrow ? 16 : 24),
      children: [
        Row(
          children: [
            const Icon(
              Icons.auto_awesome,
              color: AppColors.primary,
              size: 28,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trợ lý AI AttendEase',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Phân tích tự động dựa trên quy chế vắng: >=${(data.warnThreshold * 100).toStringAsFixed(0)}% cảnh báo, >=${(data.banThreshold * 100).toStringAsFixed(0)}% cấm thi (Remote Config).',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Action Toolbar
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: () => widget.viewModel.queryAtRiskStudents(),
                  icon: const Icon(Icons.warning_amber_outlined),
                  label: const Text('Sinh viên có nguy cơ'),
                ),
                FilledButton.icon(
                  onPressed: () => widget.viewModel.queryHighestAbsenceSubject(),
                  icon: const Icon(Icons.leaderboard_outlined),
                  label: const Text('Môn có tỷ lệ vắng cao nhất'),
                ),
                SizedBox(
                  width: narrow ? double.infinity : 260,
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: widget.viewModel.selectedStudentId,
                    decoration: const InputDecoration(
                      labelText: 'Chọn sinh viên tra cứu',
                      isDense: true,
                    ),
                    items: data.students
                        .map(
                          (s) => DropdownMenuItem(
                            value: s.studentId,
                            child: Text(
                              '${s.studentCode} - ${s.fullName}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) =>
                        widget.viewModel.setSelectedStudent(val),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: data.students.isEmpty
                      ? null
                      : () => widget.viewModel.queryStudentHistory(),
                  icon: const Icon(Icons.history),
                  label: const Text('Tra cứu lịch sử'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),

        // AI Messages Feed
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.forum_outlined,
                        size: 20, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Hộp thoại tương tác AI',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const Divider(height: 24),
                if (data.messages.isEmpty)
                  const Text('Chọn một câu hỏi phía trên để AI phản hồi.')
                else
                  ...data.messages.reversed.map((msg) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.smart_toy_outlined,
                                color: AppColors.primary,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  msg,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

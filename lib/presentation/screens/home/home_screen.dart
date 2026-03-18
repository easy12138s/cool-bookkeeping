import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../providers/voice_bookkeeping_provider.dart';
import '../../widgets/batch_confirmation_card.dart';
import '../../widgets/record_list_widget.dart';
import '../../widgets/weekly_summary_card.dart';

/// 首页屏幕
/// 显示本周记账记录列表、统计卡片和语音记账入口
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final speechState = ref.watch(speechStateProvider);
    final recognizedText = ref.watch(recognizedTextProvider);

    // 监听批量确认卡片触发器
    ref.listen<bool>(showBatchConfirmationTriggerProvider, (previous, next) {
      if (next == true) {
        // 重置触发器
        ref.read(showBatchConfirmationTriggerProvider.notifier).state = false;
        // 显示批量确认弹窗
        showBatchConfirmationCard(context);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('酷记'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 语音识别状态显示（仅在录音或处理时显示）
          if (speechState != SpeechState.idle || recognizedText.isNotEmpty)
            _SpeechRecognitionStatus(
              speechState: speechState,
              recognizedText: recognizedText,
            ),

          // 本周统计卡片
          const WeeklySummaryCard(),

          // 记录列表
          const Expanded(
            child: RecordListWidget(),
          ),
        ],
      ),
    );
  }
}

/// 语音识别状态显示组件
class _SpeechRecognitionStatus extends ConsumerWidget {
  final SpeechState speechState;
  final String recognizedText;

  const _SpeechRecognitionStatus({
    required this.speechState,
    required this.recognizedText,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    String statusText;
    IconData statusIcon;
    Color statusColor;

    switch (speechState) {
      case SpeechState.listening:
        statusText = '正在聆听...';
        statusIcon = Icons.mic;
        statusColor = AppColors.brandPrimary;
        break;
      case SpeechState.processing:
        statusText = '处理中...';
        statusIcon = Icons.hourglass_top;
        statusColor = AppColors.brandSecondary;
        break;
      case SpeechState.error:
        statusText = '识别出错，请重试';
        statusIcon = Icons.error_outline;
        statusColor = AppColors.error;
        break;
      case SpeechState.idle:
        statusText = '识别完成';
        statusIcon = Icons.check_circle_outline;
        statusColor = AppColors.success;
        break;
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 24),
              const SizedBox(width: 12),
              Text(
                statusText,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (speechState == SpeechState.listening) ...[
                const SizedBox(width: 8),
                _buildVoiceWave(),
              ],
            ],
          ),
          if (recognizedText.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '识别内容：',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recognizedText,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 构建音波动画
  Widget _buildVoiceWave() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDot(0),
        const SizedBox(width: 4),
        _buildDot(1),
        const SizedBox(width: 4),
        _buildDot(2),
      ],
    );
  }

  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 4,
      height: 4 + (index * 2).toDouble(),
      decoration: BoxDecoration(
        color: AppColors.brandPrimary,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../providers/voice_bookkeeping_provider.dart';

/// 语音识别底部弹窗
/// 显示语音识别状态和识别内容
class VoiceRecognitionSheet extends ConsumerWidget {
  const VoiceRecognitionSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final speechState = ref.watch(speechStateProvider);
    final recognizedText = ref.watch(recognizedTextProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 顶部指示条
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // 状态图标
              _buildStatusIcon(speechState),
              const SizedBox(height: 16),

              // 状态标题
              _buildStatusTitle(speechState),
              const SizedBox(height: 8),

              // 状态描述
              _buildStatusDescription(speechState),
              const SizedBox(height: 24),

              // 识别内容显示
              if (recognizedText.isNotEmpty && speechState == SpeechState.listening)
                _buildRecognizedText(recognizedText),

              if (speechState == SpeechState.processing && recognizedText.isNotEmpty)
                _buildAnalyzingView(recognizedText),

              const SizedBox(height: 16),

              // 提示文字
              Text(
                speechState == SpeechState.listening
                    ? '松手结束录音'
                    : speechState == SpeechState.processing
                        ? '正在处理中...'
                        : '',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建状态图标
  Widget _buildStatusIcon(SpeechState state) {
    switch (state) {
      case SpeechState.listening:
        return Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.brandPrimary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.mic,
            size: 40,
            color: AppColors.brandPrimary,
          ),
        );
      case SpeechState.processing:
        return Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.brandSecondary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.brandPrimary),
            ),
          ),
        );
      case SpeechState.error:
        return Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.error_outline,
            size: 40,
            color: AppColors.error,
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  /// 构建状态标题
  Widget _buildStatusTitle(SpeechState state) {
    String title;
    switch (state) {
      case SpeechState.listening:
        title = '正在聆听';
        break;
      case SpeechState.processing:
        title = '智能分析中';
        break;
      case SpeechState.error:
        title = '识别出错';
        break;
      default:
        title = '';
    }

    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  /// 构建状态描述
  Widget _buildStatusDescription(SpeechState state) {
    String description;
    switch (state) {
      case SpeechState.listening:
        description = '请说出您的记账内容';
        break;
      case SpeechState.processing:
        description = '正在理解您的语音内容';
        break;
      case SpeechState.error:
        description = '请重试或手动输入';
        break;
      default:
        description = '';
    }

    return Text(
      description,
      style: const TextStyle(
        fontSize: 14,
        color: AppColors.textSecondary,
      ),
    );
  }

  /// 构建识别内容显示
  Widget _buildRecognizedText(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '识别内容',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建分析中视图
  Widget _buildAnalyzingView(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.brandPrimary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.psychology,
                size: 16,
                color: AppColors.brandPrimary,
              ),
              const SizedBox(width: 6),
              const Text(
                '已识别内容',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.brandPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.brandPrimary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.brandPrimary),
                ),
              ),
              SizedBox(width: 8),
              Text(
                '正在智能分析...',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.brandPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// 全局状态跟踪弹窗显示状态
bool _isVoiceSheetShowing = false;

/// 显示语音识别底部弹窗
/// 防止重复显示多个弹窗
void showVoiceRecognitionSheet(BuildContext context) {
  if (_isVoiceSheetShowing) return;
  _isVoiceSheetShowing = true;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    enableDrag: false,
    isDismissible: false,
    builder: (context) => const VoiceRecognitionSheet(),
  ).whenComplete(() {
    _isVoiceSheetShowing = false;
  });
}

/// 关闭语音识别底部弹窗
/// 安全关闭，避免误关闭其他路由
void hideVoiceRecognitionSheet(BuildContext context) {
  if (!_isVoiceSheetShowing) return;
  if (Navigator.of(context).canPop()) {
    Navigator.of(context).pop();
  }
}

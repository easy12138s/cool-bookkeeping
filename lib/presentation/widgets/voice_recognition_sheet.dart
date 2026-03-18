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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
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
              const SizedBox(height: 32),

              // 状态图标（带动画效果）
              _buildStatusIcon(speechState),
              const SizedBox(height: 24),

              // 状态标题
              _buildStatusTitle(speechState),
              const SizedBox(height: 8),

              // 状态描述
              _buildStatusDescription(speechState),
              const SizedBox(height: 32),

              // 识别内容显示
              if (recognizedText.isNotEmpty && speechState == SpeechState.listening)
                _buildRecognizedText(recognizedText),

              if (speechState == SpeechState.processing && recognizedText.isNotEmpty)
                _buildAnalyzingView(recognizedText),

              if (speechState == SpeechState.error)
                _buildErrorView(),

              const SizedBox(height: 24),

              // 底部提示
              _buildBottomHint(speechState),
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
        return _buildAnimatedMicIcon();
      case SpeechState.processing:
        return Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.brandPrimary, AppColors.brandLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.brandPrimary.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        );
      case SpeechState.error:
        return Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.error_outline,
            size: 44,
            color: AppColors.error,
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  /// 构建带动画的麦克风图标
  Widget _buildAnimatedMicIcon() {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.brandPrimary, AppColors.brandLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.brandPrimary.withValues(alpha: 0.4),
            blurRadius: 24,
            spreadRadius: 8,
          ),
        ],
      ),
      child: const Icon(
        Icons.mic,
        size: 40,
        color: Colors.white,
      ),
    );
  }

  /// 构建状态标题
  Widget _buildStatusTitle(SpeechState state) {
    String title;
    Color color;
    switch (state) {
      case SpeechState.listening:
        title = '正在听您说...';
        color = AppColors.brandPrimary;
        break;
      case SpeechState.processing:
        title = '正在分析';
        color = AppColors.brandPrimary;
        break;
      case SpeechState.error:
        title = '识别失败';
        color = AppColors.error;
        break;
      default:
        title = '';
        color = AppColors.textPrimary;
    }

    return Text(
      title,
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }

  /// 构建状态描述
  Widget _buildStatusDescription(SpeechState state) {
    String description;
    switch (state) {
      case SpeechState.listening:
        description = '请说出消费内容，例如："午餐花了25元"';
        break;
      case SpeechState.processing:
        description = '正在理解您的语音并智能分类';
        break;
      case SpeechState.error:
        description = '抱歉没听清，请重试或手动记账';
        break;
      default:
        description = '';
    }

    return Text(
      description,
      style: const TextStyle(
        fontSize: 14,
        color: AppColors.textSecondary,
        height: 1.5,
      ),
      textAlign: TextAlign.center,
    );
  }

  /// 构建识别内容显示
  Widget _buildRecognizedText(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.brandPrimary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '识别到的内容',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            text,
            style: const TextStyle(
              fontSize: 18,
              color: AppColors.textPrimary,
              height: 1.5,
              fontWeight: FontWeight.w500,
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.brandPrimary.withValues(alpha: 0.08),
            AppColors.brandLight.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.psychology,
                  size: 18,
                  color: AppColors.brandPrimary,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                '已识别内容',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.brandPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            text,
            style: const TextStyle(
              fontSize: 18,
              color: AppColors.textPrimary,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.brandPrimary),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'AI 正在智能分析分类...',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.brandPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建错误视图
  Widget _buildErrorView() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.mic_off,
            size: 40,
            color: AppColors.error,
          ),
          const SizedBox(height: 12),
          const Text(
            '未能识别语音内容',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '建议：说话更清晰、靠近麦克风、减少环境噪音',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 构建底部提示
  Widget _buildBottomHint(SpeechState state) {
    String hint;
    IconData icon;
    Color color;

    switch (state) {
      case SpeechState.listening:
        hint = '松开手指结束录音';
        icon = Icons.touch_app;
        color = AppColors.textSecondary;
        break;
      case SpeechState.processing:
        hint = '请稍候，马上就好';
        icon = Icons.hourglass_empty;
        color = AppColors.brandPrimary;
        break;
      case SpeechState.error:
        hint = '长按话筒重试';
        icon = Icons.replay;
        color = AppColors.error;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 6),
        Text(
          hint,
          style: TextStyle(
            fontSize: 14,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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

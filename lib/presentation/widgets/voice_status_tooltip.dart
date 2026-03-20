import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../providers/voice_bookkeeping_provider.dart';

/// 语音识别状态悬浮提示组件
/// 在语音按钮上方显示实时状态
class VoiceStatusTooltip extends StatelessWidget {
  /// 当前语音状态
  final SpeechState state;

  /// 已识别的文本
  final String? recognizedText;

  /// 录音时长（秒）
  final int recordingSeconds;

  /// 取消回调
  final VoidCallback? onCancel;

  const VoiceStatusTooltip({
    super.key,
    required this.state,
    this.recognizedText,
    this.recordingSeconds = 0,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    // 只有在录音或处理状态时才显示
    if (state == SpeechState.idle) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 100, // 按钮上方
      left: 16,
      right: 16,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 12,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStatusText(context),
                if (recognizedText != null && recognizedText!.isNotEmpty)
                  _buildRecognizedText(context),
                if (state == SpeechState.listening) _buildCancelButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建状态文本
  Widget _buildStatusText(BuildContext context) {
    String statusText;
    IconData icon;
    Color iconColor;

    switch (state) {
      case SpeechState.listening:
        statusText = '🎤 正在录音 ${_formatDuration(recordingSeconds)}';
        icon = Icons.mic;
        iconColor = AppColors.error;
        break;
      case SpeechState.processing:
        if (recognizedText != null && recognizedText!.isNotEmpty) {
          statusText = '🤖 正在解析记账信息...';
        } else {
          statusText = '🔍 正在识别语音...';
        }
        icon = Icons.hourglass_top;
        iconColor = AppColors.brandSecondary;
        break;
      case SpeechState.idle:
      default:
        return const SizedBox.shrink();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: iconColor),
        AppSpacing.width(context, 8),
        Flexible(
          child: Text(
            statusText,
            style: AppTextStyles.getBodyMedium(context).copyWith(
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  /// 构建识别文本
  Widget _buildRecognizedText(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          recognizedText!,
          style: AppTextStyles.getBodyMedium(context).copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  /// 构建取消按钮
  Widget _buildCancelButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TextButton.icon(
        onPressed: onCancel,
        icon: const Icon(Icons.cancel_outlined, size: 18),
        label: const Text('取消'),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.error,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
    );
  }

  /// 格式化时长
  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }
}

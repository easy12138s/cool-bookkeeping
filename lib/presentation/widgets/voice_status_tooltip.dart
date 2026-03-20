import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
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
    // 空闲和取消状态不显示弹窗
    if (state == SpeechState.idle || state == SpeechState.cancelled) {
      return const SizedBox.shrink();
    }

    // 使用 MediaQuery 获取屏幕宽度
    final screenWidth = MediaQuery.of(context).size.width;
    final tooltipWidth = screenWidth * 0.7;
    // 计算居中偏移量
    final leftOffset = (screenWidth - tooltipWidth) / 2;

    return Positioned(
      bottom: 100,
      left: leftOffset,
      width: tooltipWidth,
      child: Container(
        width: tooltipWidth,
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
    );
  }

  Widget _buildStatusText(BuildContext context) {
    String statusText;
    IconData icon;
    Color iconColor;

    switch (state) {
      case SpeechState.initializing:
        statusText = '⚙️ 正在初始化语音识别...';
        icon = Icons.settings;
        iconColor = AppColors.brandSecondary;
        break;
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
      case SpeechState.error:
        statusText = '❌ 语音识别出错';
        icon = Icons.error_outline;
        iconColor = AppColors.error;
        break;
      case SpeechState.success:
        statusText = '✅ 识别成功';
        icon = Icons.check_circle_outline;
        iconColor = AppColors.success;
        break;
      case SpeechState.idle:
      case SpeechState.cancelled:
        return const SizedBox.shrink();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 8),
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
          maxLines: 5,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

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

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }
}

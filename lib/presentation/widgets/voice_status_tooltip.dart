import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../providers/voice_bookkeeping_provider.dart';

/// 语音识别状态悬浮提示组件
/// 使用 Overlay 在屏幕级别显示，展示步骤进度、错误详情和操作建议
class VoiceStatusTooltip extends StatefulWidget {
  final SpeechState state;
  final VoiceProcessingStep step;
  final String? recognizedText;
  final int recordingSeconds;
  final String? errorDetail;
  final String? suggestion;
  final VoidCallback? onCancel;

  const VoiceStatusTooltip({
    super.key,
    required this.state,
    required this.step,
    this.recognizedText,
    this.recordingSeconds = 0,
    this.errorDetail,
    this.suggestion,
    this.onCancel,
  });

  @override
  State<VoiceStatusTooltip> createState() => _VoiceStatusTooltipState();
}

class _VoiceStatusTooltipState extends State<VoiceStatusTooltip> {
  OverlayEntry? _overlayEntry;
  bool _isShowing = false;
  bool _dismissedByUser = false;
  Timer? _autoRemoveTimer;

  @override
  void didUpdateWidget(covariant VoiceStatusTooltip oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _updateOverlay();
    });
  }

  @override
  void dispose() {
    _autoRemoveTimer?.cancel();
    _removeOverlay();
    super.dispose();
  }

  void _updateOverlay() {
    final shouldShow = widget.state != SpeechState.idle &&
        widget.state != SpeechState.cancelled;

    if (shouldShow && !_isShowing) {
      _showOverlay();
    } else if (!shouldShow && _isShowing) {
      // 状态变为不可见时，延迟 3 秒移除
      _scheduleRemove();
    } else if (shouldShow && _isShowing) {
      _overlayEntry?.markNeedsBuild();
    }
  }

  void _scheduleRemove() {
    _autoRemoveTimer?.cancel();
    _autoRemoveTimer = Timer(const Duration(seconds: 3), () {
      _removeOverlay();
    });
  }

  void _showOverlay() {
    _dismissedByUser = false;
    _autoRemoveTimer?.cancel();
    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (context) => _buildOverlayContent(context),
    );
    overlay.insert(_overlayEntry!);
    _isShowing = true;
  }

  void _removeOverlay() {
    _autoRemoveTimer?.cancel();
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isShowing = false;
    _dismissedByUser = true;
  }

  /// 获取步骤总数
  int get _totalSteps => 5;

  /// 获取当前步骤编号
  int get _currentStepNumber {
    switch (widget.step) {
      case VoiceProcessingStep.permissionCheck:
        return 1;
      case VoiceProcessingStep.initializing:
        return 2;
      case VoiceProcessingStep.recording:
        return 3;
      case VoiceProcessingStep.recognizing:
        return 4;
      case VoiceProcessingStep.parsing:
        return 5;
      case VoiceProcessingStep.complete:
        return 5;
      case VoiceProcessingStep.none:
        return 0;
    }
  }

  /// 获取当前步骤描述
  String get _stepLabel {
    switch (widget.step) {
      case VoiceProcessingStep.permissionCheck:
        return '检查权限';
      case VoiceProcessingStep.initializing:
        return '初始化中';
      case VoiceProcessingStep.recording:
        return '录音中';
      case VoiceProcessingStep.recognizing:
        return '识别中';
      case VoiceProcessingStep.parsing:
        return 'AI 解析';
      case VoiceProcessingStep.complete:
        return '解析完成';
      case VoiceProcessingStep.none:
        return '';
    }
  }

  Widget _buildOverlayContent(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final tooltipWidth = screenWidth * 0.85;

    return Positioned(
      bottom: 100,
      left: (screenWidth - tooltipWidth) / 2,
      width: tooltipWidth,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: tooltipWidth,
          padding: const EdgeInsets.all(16),
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
              _buildHeader(context),
              if (widget.errorDetail != null) _buildErrorDetail(context),
              if (widget.suggestion != null) _buildSuggestion(context),
              if (widget.recognizedText != null &&
                  widget.recognizedText!.isNotEmpty)
                _buildRecognizedText(context),
              if (widget.state == SpeechState.listening)
                _buildCancelButton(context),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建步骤进度和状态头部
  Widget _buildHeader(BuildContext context) {
    String statusText;
    IconData icon;
    Color iconColor;

    switch (widget.state) {
      case SpeechState.initializing:
        statusText = _stepLabel;
        icon = Icons.settings;
        iconColor = AppColors.brandSecondary;
        break;
      case SpeechState.listening:
        statusText = '$_stepLabel ${_formatDuration(widget.recordingSeconds)}';
        icon = Icons.mic;
        iconColor = AppColors.error;
        break;
      case SpeechState.processing:
        statusText = _stepLabel;
        icon = Icons.hourglass_top;
        iconColor = AppColors.brandSecondary;
        break;
      case SpeechState.error:
        statusText = '出错了';
        icon = Icons.error_outline;
        iconColor = AppColors.error;
        break;
      case SpeechState.success:
        statusText = '完成';
        icon = Icons.check_circle_outline;
        iconColor = AppColors.success;
        break;
      case SpeechState.idle:
      case SpeechState.cancelled:
        return const SizedBox.shrink();
    }

    return Column(
      children: [
        // 步骤进度条
        if (_currentStepNumber > 0 && widget.state != SpeechState.error)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildStepIndicator(context),
          ),
        // 状态行
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                statusText,
                style: AppTextStyles.getBodyMedium(context).copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建步骤进度指示器
  Widget _buildStepIndicator(BuildContext context) {
    return Row(
      children: [
        for (int i = 1; i <= _totalSteps; i++) ...[
          if (i > 1)
            Expanded(
              child: Container(
                height: 2,
                color: i <= _currentStepNumber
                    ? AppColors.brandPrimary
                    : AppColors.divider,
              ),
            ),
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i <= _currentStepNumber
                  ? AppColors.brandPrimary
                  : AppColors.divider,
            ),
            child: Center(
              child: Text(
                '$i',
                style: TextStyle(
                  fontSize: 10,
                  color: i <= _currentStepNumber
                      ? Colors.white
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// 构建错误详情
  Widget _buildErrorDetail(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.error.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline,
              size: 18,
              color: AppColors.error,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.errorDetail!,
                style: AppTextStyles.getBodyMedium(context).copyWith(
                  color: AppColors.error,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建操作建议
  Widget _buildSuggestion(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 16,
            color: AppColors.brandSecondary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              widget.suggestion!,
              style: AppTextStyles.getBodyMedium(context).copyWith(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '识别内容',
              style: AppTextStyles.getLabelMedium(context).copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.recognizedText!,
              style: AppTextStyles.getBodyMedium(context).copyWith(
                color: AppColors.textPrimary,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCancelButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TextButton.icon(
        onPressed: widget.onCancel,
        icon: const Icon(Icons.cancel_outlined, size: 18),
        label: const Text('取消'),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.error,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../providers/voice_bookkeeping_provider.dart';

/// 语音按钮组件
/// 支持长按录音，显示录音动画和时长
class VoiceButton extends ConsumerStatefulWidget {
  const VoiceButton({super.key});

  @override
  ConsumerState<VoiceButton> createState() => _VoiceButtonState();
}

class _VoiceButtonState extends ConsumerState<VoiceButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  Timer? _durationTimer;
  int _recordingDuration = 0;
  bool _isStarting = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _durationTimer?.cancel();
    super.dispose();
  }

  void _startRecording() async {
    // 防止重复启动
    if (_isStarting) return;
    _isStarting = true;

    // 清除之前的错误
    ref.read(voiceErrorMessageProvider.notifier).state = null;

    final controller = ref.read(voiceBookkeepingControllerProvider);
    await controller.startRecording();

    if (mounted) {
      _pulseController.repeat();
      _recordingDuration = 0;
      _durationTimer = Timer.periodic(
        const Duration(seconds: 1),
        (timer) {
          if (mounted) {
            setState(() {
              _recordingDuration++;
            });
          }
        },
      );
    }

    _isStarting = false;
  }

  void _stopRecording() {
    _pulseController.stop();
    _pulseController.reset();
    _durationTimer?.cancel();

    final controller = ref.read(voiceBookkeepingControllerProvider);
    controller.stopRecording();

    // 延迟解析，等待语音识别完成
    Future.delayed(const Duration(milliseconds: 500), () {
      controller.parseVoiceInput();
    });
  }

  void _cancelRecording() {
    _pulseController.stop();
    _pulseController.reset();
    _durationTimer?.cancel();

    final controller = ref.read(voiceBookkeepingControllerProvider);
    controller.cancelRecording();
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: '去设置',
          textColor: Colors.white,
          onPressed: () {
            // TODO: 导航到设置页面
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final speechState = ref.watch(speechStateProvider);
    final isRecording = speechState == SpeechState.listening;
    final isProcessing = speechState == SpeechState.processing;

    // 监听错误信息并显示提示
    ref.listen<String?>(voiceErrorMessageProvider, (previous, next) {
      if (next != null && next.isNotEmpty) {
        _showErrorSnackBar(next);
      }
    });

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isRecording) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.brandPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _formatDuration(_recordingDuration),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.brandPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        GestureDetector(
          onLongPressStart: (_) => _startRecording(),
          onLongPressEnd: (_) => _stopRecording(),
          onLongPressCancel: () => _cancelRecording(),
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final scale = isRecording
                  ? 1.0 + (_pulseController.value * 0.15)
                  : 1.0;

              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isProcessing
                        ? AppColors.brandSecondary
                        : isRecording
                            ? AppColors.error
                            : AppColors.brandPrimary,
                    boxShadow: [
                      if (isRecording)
                        BoxShadow(
                          color: AppColors.error.withValues(
                            alpha: 0.3 + (_pulseController.value * 0.3),
                          ),
                          blurRadius: 20 + (_pulseController.value * 10),
                          spreadRadius: 2 + (_pulseController.value * 4),
                        )
                      else
                        BoxShadow(
                          color: AppColors.brandPrimary.withValues(alpha: 0.3),
                          blurRadius: 12,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                    ],
                  ),
                  child: Center(
                    child: isProcessing
                        ? const SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Icon(
                            isRecording ? Icons.mic : Icons.mic_none,
                            size: 32,
                            color: Colors.white,
                          ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isRecording
              ? '松手完成'
              : isProcessing
                  ? '处理中...'
                  : '长按说话',
          style: TextStyle(
            fontSize: 12,
            color: isRecording
                ? AppColors.error
                : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
